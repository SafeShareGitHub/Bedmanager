import 'dart:convert';
import 'dart:html' as html;

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Linens e suas abreviações
  final Map<String, String> linens = {
    'fronha': 'Fr',
    'lencol_elastico': 'El',
    'lencol_sem_elastico': 'S/El',
    'capa_edredom': 'Ed',
  };

  DocumentReference _bedDoc(String roomId, String bedId) =>
      FirebaseFirestore.instance
          .collection('rooms')
          .doc(roomId)
          .collection('beds')
          .doc(bedId);

  bool _isToday(Timestamp ts) {
    final d = ts.toDate();
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  /// Busca todos os documentos "beds" em todos os quartos
  Future<List<Map<String, dynamic>>> _fetchAllBeds() async {
    final query =
        await FirebaseFirestore.instance.collectionGroup('beds').get();
    return query.docs.map((doc) {
      final roomId = doc.reference.parent.parent!.id;
      final bedId = doc.id;
      final data = doc.data();
      return {
        'roomId': roomId,
        'bedId': bedId,
        'linens': data['linens'] as Map<String, dynamic>? ?? {},
        'ref': doc.reference,
      };
    }).toList();
  }

  /// Define todos como "hoje"
  Future<void> _markAllToday() async {
    final beds = await _fetchAllBeds();
    final batch = FirebaseFirestore.instance.batch();
    for (var b in beds) {
      final ref = b['ref'] as DocumentReference;
      batch.set(
          ref,
          {
            'linens': {
              for (var key in linens.keys)
                key: {'lastChanged': FieldValue.serverTimestamp()}
            }
          },
          SetOptions(merge: true));
    }
    await batch.commit();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Tudo marcado como hoje')),
    );
    setState(() {});
  }

  /// Exporta relatório como JSON
  Future<void> _exportReport() async {
    final beds = await _fetchAllBeds();
    final report = beds.map((b) {
      final m = b['linens'] as Map<String, dynamic>;
      return {
        'quarto': b['roomId'],
        'cama': b['bedId'],
        for (var key in linens.keys)
          key: m[key]?['lastChanged'] != null
              ? DateFormat('yyyy-MM-dd')
                  .format((m[key]['lastChanged'] as Timestamp).toDate())
              : '-'
      };
    }).toList();
    final jsonString = JsonEncoder.withIndent('  ').convert(report);
    final blob = html.Blob([jsonString], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    html.AnchorElement(href: url)
      ..setAttribute('download', 'relatorio_camas.json')
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Relatório de Camas'),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: () => setState(() {}),
          ),
          IconButton(
            icon: Icon(Icons.download),
            tooltip: 'Exportar',
            onPressed: _exportReport,
          ),
          TextButton(
            onPressed: _markAllToday,
            child: Text('Tudo Hoje'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAllBeds(),
        builder: (ctx, snap) {
          if (snap.hasError) {
            return Center(child: Text('Erro: ${snap.error}'));
          }
          if (!snap.hasData) {
            return Center(child: CircularProgressIndicator());
          }
          // Agrupa por quarto
          final beds = snap.data!;
          final Map<String, List<Map<String, dynamic>>> byRoom = {};
          for (var b in beds) {
            byRoom.putIfAbsent(b['roomId'], () => []).add(b);
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              children: byRoom.entries.map((entry) {
                final roomId = entry.key;
                final roomBeds = entry.value;
                return Card(
                  margin: EdgeInsets.only(bottom: 24),
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Quarto $roomId',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              DataColumn(label: Text('Cama')),
                              for (var abbr in linens.values)
                                DataColumn(label: Text(abbr)),
                            ],
                            rows: roomBeds.map((b) {
                              final linensMap =
                                  b['linens'] as Map<String, dynamic>;
                              return DataRow(cells: [
                                DataCell(Text(b['bedId'])),
                                for (var key in linens.keys)
                                  DataCell(Row(
                                    children: [
                                      Text(
                                        linensMap[key]?['lastChanged'] == null
                                            ? '-'
                                            : DateFormat('yyyy-MM-dd').format(
                                                (linensMap[key]['lastChanged']
                                                        as Timestamp)
                                                    .toDate(),
                                              ),
                                      ),
                                      if (linensMap[key]?['lastChanged'] !=
                                              null &&
                                          _isToday(linensMap[key]['lastChanged']
                                              as Timestamp))
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 6),
                                          child: Icon(Icons.check_circle,
                                              color: Colors.green, size: 16),
                                        ),
                                    ],
                                  )),
                              ]);
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        },
      ),
    );
  }
}

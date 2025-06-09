import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Ocean extends StatelessWidget {
  // Apenas uma cama
  final List<String> bedIds = ['bed1'];

  // Tipos de roupa de cama com rótulos abreviados
  final Map<String, String> linens = {
    'fronha': 'Fr',
    'lencol_elastico': 'El',
    'lencol_sem_elastico': 'S/E',
    'capa_edredom': 'Ed',
  };

  // Referência ao documento da cama em rooms/ocean/beds/bed1
  DocumentReference _bedDoc(String bedId) => FirebaseFirestore.instance
      .collection('rooms')
      .doc('ocean')
      .collection('beds')
      .doc(bedId);

  // Sub-coleção de logs
  CollectionReference _logsCol(String bedId) =>
      _bedDoc(bedId).collection('logs');

  bool _isToday(Timestamp ts) {
    final d = ts.toDate();
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ocean – Visão Geral'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: bedIds.map((bedId) {
          return StreamBuilder<DocumentSnapshot>(
            stream: _bedDoc(bedId).snapshots(),
            builder: (ctx, snap) {
              if (snap.hasError) {
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    title: Text('Erro: ${snap.error}'),
                  ),
                );
              }

              final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};
              final map = data['linens'] as Map<String, dynamic>? ?? {};

              return Card(
                margin: const EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Cabeçalho: título + botão "Tudo"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Cama Única',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              try {
                                // cria logs para cada tipo de linen
                                for (var key in linens.keys) {
                                  await _logsCol(bedId).add({
                                    'linen': key,
                                    'changedAt': FieldValue.serverTimestamp(),
                                  });
                                }
                                // atualiza todos de uma vez
                                final updateMap = {
                                  'linens': {
                                    for (var key in linens.keys)
                                      key: {
                                        'lastChanged':
                                            FieldValue.serverTimestamp()
                                      }
                                  }
                                };
                                await _bedDoc(bedId).set(
                                  updateMap,
                                  SetOptions(merge: true),
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Tudo hoje')));
                              } catch (err) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Erro: $err')));
                              }
                            },
                            child: Text('Tudo'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text('Item')),
                            DataColumn(label: Text('Última')),
                            DataColumn(label: Text('Ação')),
                          ],
                          rows: linens.entries.map((e) {
                            final key = e.key;
                            final label = e.value;
                            final ts = (map[key]
                                    as Map<String, dynamic>?)?['lastChanged']
                                as Timestamp?;
                            final dateText = ts == null
                                ? '-'
                                : DateFormat('yyyy-MM-dd').format(ts.toDate());
                            final wasToday = ts != null && _isToday(ts);

                            return DataRow(cells: [
                              DataCell(Text(label)),
                              DataCell(Row(
                                children: [
                                  Text(dateText),
                                  if (wasToday) ...[
                                    SizedBox(width: 6),
                                    Icon(Icons.check_circle,
                                        color: Colors.green, size: 16),
                                  ],
                                ],
                              )),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        await _logsCol(bedId).add({
                                          'linen': key,
                                          'changedAt':
                                              FieldValue.serverTimestamp(),
                                        });
                                        await _bedDoc(bedId).set({
                                          'linens': {
                                            key: {
                                              'lastChanged':
                                                  FieldValue.serverTimestamp()
                                            }
                                          }
                                        }, SetOptions(merge: true));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text('Alterar')));
                                      } catch (err) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text('Erro: $err')));
                                      }
                                    },
                                    child: Text('Alt'),
                                  ),
                                  SizedBox(width: 8),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.grey),
                                    onPressed: () async {
                                      try {
                                        final logs = await _logsCol(bedId)
                                            .where('linen', isEqualTo: key)
                                            .get();
                                        var docs = logs.docs;
                                        if (docs.isEmpty) return;
                                        docs.sort((a, b) {
                                          final aTs = (a.data() as Map<String,
                                                  dynamic>?)?['changedAt']
                                              as Timestamp?;
                                          final bTs = (b.data() as Map<String,
                                                  dynamic>?)?['changedAt']
                                              as Timestamp?;
                                          return bTs!.compareTo(aTs!);
                                        });
                                        await docs.first.reference.delete();
                                        Timestamp? prevTs;
                                        if (docs.length > 1) {
                                          final m = docs[1].data()
                                              as Map<String, dynamic>?;
                                          prevTs =
                                              m?['changedAt'] as Timestamp?;
                                        }
                                        await _bedDoc(bedId).set({
                                          'linens': {
                                            key: {'lastChanged': prevTs}
                                          }
                                        }, SetOptions(merge: true));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text('Undo')));
                                      } catch (err) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                                content: Text('Erro: $err')));
                                      }
                                    },
                                    child: Text('Undo'),
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
            },
          );
        }).toList(),
      ),
    );
  }
}

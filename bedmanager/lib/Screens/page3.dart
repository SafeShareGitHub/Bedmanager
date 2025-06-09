import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Harmony extends StatelessWidget {
  // IDs der Betten
  final List<String> bedIds = ['bed1', 'bed2', 'bed3'];

  // Linen‐Typen und ihre Labels
  final Map<String, String> linens = {
    'fronha': 'Fronha',
    'lencol_elastico': 'Lençol com elástico',
    'lencol_sem_elastico': 'Lençol sem elástico',
    'capa_edredom': 'Capa de edredom',
  };

  // Referenz zum Bett‐Dokument
  DocumentReference _bedDoc(String bedId) => FirebaseFirestore.instance
      .collection('rooms')
      .doc('harmony')
      .collection('beds')
      .doc(bedId);

  // Referenz zur Log‐Subcollection
  CollectionReference _logsCol(String bedId) =>
      _bedDoc(bedId).collection('logs');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Harmony – Bettenübersicht')),
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
                    title: Text('Fehler: ${snap.error}'),
                  ),
                );
              }
              // Rohdaten oder leere Map
              final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};
              final map = data['linens'] as Map<String, dynamic>? ?? {};

              return Card(
                margin: const EdgeInsets.only(bottom: 24),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bett ${bedId.replaceAll('bed', '')}',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Item')),
                            DataColumn(label: Text('Letzter Wechsel')),
                            DataColumn(label: Text('Aktion')),
                          ],
                          rows: linens.entries.map((e) {
                            final key = e.key;
                            final label = e.value;
                            // Datum auslesen (nullable)
                            final ts = (map[key]
                                    as Map<String, dynamic>?)?['lastChanged']
                                as Timestamp?;
                            final dateText = ts == null
                                ? '-'
                                : DateFormat('yyyy-MM-dd HH:mm')
                                    .format(ts.toDate());

                            return DataRow(cells: [
                              DataCell(Text(label)),
                              DataCell(Text(dateText)),
                              DataCell(Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // Changed‐Button
                                  ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        // 1) Log anlegen
                                        await _logsCol(bedId).add({
                                          'linen': key,
                                          'changedAt':
                                              FieldValue.serverTimestamp(),
                                        });
                                        // 2) lastChanged im Hauptdokument
                                        await _bedDoc(bedId).set({
                                          'linens': {
                                            key: {
                                              'lastChanged':
                                                  FieldValue.serverTimestamp(),
                                            }
                                          }
                                        }, SetOptions(merge: true));
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text(
                                              'Wechsel $label gespeichert'),
                                        ));
                                      } catch (err) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(SnackBar(
                                          content: Text('Fehler: $err'),
                                        ));
                                      }
                                    },
                                    child: Text('Changed'),
                                  ),
                                  const SizedBox(width: 8),
                                  // Undo‐Button
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                    ),
                                    onPressed: () async {
                                      try {
                                        // 1) Die letzten zwei Logs laden
                                        final logsSnapshot =
                                            await _logsCol(bedId)
                                                .where('linen', isEqualTo: key)
                                                .orderBy('changedAt',
                                                    descending: true)
                                                .limit(2)
                                                .get();

                                        final docs = logsSnapshot.docs;
                                        if (docs.isEmpty) return;

                                        // 2) Letzten Eintrag löschen
                                        await docs.first.reference.delete();

                                        // 3) Vorherigen Timestamp ermitteln, falls vorhanden
                                        Timestamp? prevTs;
                                        if (docs.length > 1) {
                                          // data() kann null oder ein beliebiger Object-Typ sein, daher casten
                                          final Map<String, dynamic>? dataMap =
                                              docs[1].data()
                                                  as Map<String, dynamic>?;
                                          prevTs = dataMap == null
                                              ? null
                                              : (dataMap['changedAt']
                                                  as Timestamp?);
                                        }

                                        // 4) lastChanged im Hauptdokument zurücksetzen
                                        await _bedDoc(bedId).set({
                                          'linens': {
                                            key: {
                                              'lastChanged': prevTs,
                                            }
                                          }
                                        }, SetOptions(merge: true));

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text(
                                                  'Undo für $label ausgeführt')),
                                        );
                                      } catch (err) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                              content: Text('Fehler: $err')),
                                        );
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

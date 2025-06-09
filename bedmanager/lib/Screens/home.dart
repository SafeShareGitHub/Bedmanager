import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:html' as html;

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- Produktion (Persönliche Daten) ---
  String name = '';
  String email = '';

  // --- Solver Eigenschaften ---
  String profil = '';
  int? numberOfJobs;
  String selectedModel = '';
  double? solverTime;
  double? solverGap;

  // --- Jobs Liste ---
  List<Map<String, dynamic>> jobs = [];

  // Einen neuen Job hinzufügen
  void _addJob() {
    setState(() {
      jobs.add({
        'Job ID': null, // Es wird keine automatische ID vergeben
        'Due Date': DateTime.now().toIso8601String(),
        'Gesamtdauer': 0.0,
        'Anzahl': 0,
        'Amount': 0,
        'Priorität': 0,
      });
    });
  }

  // Baut einen String mit allen Debug-Informationen
// Baut einen String mit allen Debug-Informationen im JSON-Format
  String _buildDebugText() {
    final debugData = {
      'Produktion': {
        'Name': name,
        'E-Mail': email,
      },
      'Solver Eigenschaften': {
        'Profil': profil,
        'Number of Jobs': numberOfJobs,
        'Selected Model': selectedModel,
        'Solver Time': solverTime,
        'Solver Gap': solverGap,
      },
      'Jobs': jobs,
      'Matrizen': {
        'Maschinen': machines,
        'Matrix Data': matrixData,
      },
    };
    return JsonEncoder.withIndent('  ').convert(debugData);
  }

  // Exportiere Jobs als JSON
  void _exportJobs() {
    final jsonString = jsonEncode(jobs);
    final blob = html.Blob([jsonString], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "jobs.json")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  // Importiere Jobs aus JSON
  void _importJobs(html.File file) {
    final reader = html.FileReader();
    reader.onLoad.listen((event) {
      try {
        final result = reader.result;
        if (result is String) {
          final jsonData = jsonDecode(result);
          if (jsonData is List) {
            setState(() {
              jobs = jsonData.map<Map<String, dynamic>>((job) {
                return {
                  'Job ID': job['Job ID'], // Übernimmt den Wert aus der JSON
                  'Due Date':
                      job['Due Date'] ?? DateTime.now().toIso8601String(),
                  'Gesamtdauer': (job['Gesamtdauer'] is num)
                      ? (job['Gesamtdauer'] as num).toDouble()
                      : 0.0,
                  'Anzahl': (job['Anzahl'] is int) ? job['Anzahl'] : 0,
                  'Amount': (job['Amount'] is int) ? job['Amount'] : 0,
                  'Priorität': (job['Priorität'] is int) ? job['Priorität'] : 0,
                };
              }).toList();
            });
          }
        }
      } catch (e) {
        print("Fehler beim Importieren der Jobs: $e");
      }
    });
    reader.onError.listen((event) {
      print("Fehler beim Lesen der Datei: ${reader.error}");
    });
    reader.readAsText(file);
  }

  // Öffnet den Datei-Upload-Dialog für Jobs
  void _pickJobsFile() {
    final uploadInput = html.FileUploadInputElement()..accept = '.json';
    uploadInput.click();
    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        _importJobs(files.first);
      }
    });
  }

  // --- Export / Import Solver Eigenschaften ---
  void _exportSolverProperties() {
    final solverProps = {
      'Profil': profil,
      'Number of Jobs': numberOfJobs,
      'Selected Model': selectedModel,
      'Solver Time': solverTime,
      'Solver Gap': solverGap,
    };
    final jsonString = jsonEncode(solverProps);
    final blob = html.Blob([jsonString], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute("download", "solver_properties.json")
      ..click();
    html.Url.revokeObjectUrl(url);
  }

  void _importSolverProperties(html.File file) {
    final reader = html.FileReader();
    reader.onLoad.listen((event) {
      try {
        final result = reader.result;
        if (result is String) {
          final jsonData = jsonDecode(result);
          if (jsonData is Map) {
            setState(() {
              profil = jsonData['Profil'] ?? '';
              numberOfJobs = jsonData['Number of Jobs'];
              selectedModel = jsonData['Selected Model'] ?? '';
              solverTime = (jsonData['Solver Time'] is num)
                  ? (jsonData['Solver Time'] as num).toDouble()
                  : null;
              solverGap = (jsonData['Solver Gap'] is num)
                  ? (jsonData['Solver Gap'] as num).toDouble()
                  : null;
            });
          }
        }
      } catch (e) {
        print("Fehler beim Importieren der Solver-Eigenschaften: $e");
      }
    });
    reader.onError.listen((event) {
      print("Fehler beim Lesen der Datei: ${reader.error}");
    });
    reader.readAsText(file);
  }

  void _pickSolverPropertiesFile() {
    final uploadInput = html.FileUploadInputElement()..accept = '.json';
    uploadInput.click();
    uploadInput.onChange.listen((event) {
      final files = uploadInput.files;
      if (files != null && files.isNotEmpty) {
        _importSolverProperties(files.first);
      }
    });
  }

  // --- Datumsauswahl für Jobs ---
  Future<void> _pickDueDate(BuildContext context, int index) async {
    DateTime initialDate =
        DateTime.tryParse(jobs[index]['Due Date']) ?? DateTime.now();
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selectedDate != null) {
      setState(() {
        jobs[index]['Due Date'] = selectedDate.toIso8601String();
      });
    }
  }

  // --- Auftrag abschicken ---
  void _submitOrder() {
    // Hier können alle Daten gesammelt und verarbeitet werden.
    print("Auftrag abgeschickt!");
  }

  // ====================== Neuer Block: Matrizen ======================
  // Variablen und Controller für Matrizen
  TextEditingController machineController = TextEditingController();
  List<String> machines = [];
  List<List<String>> matrixData = [];
  Map<String, TextEditingController> _matrixControllers = {};

  // Maschine (und zugehörige Matrixzeile/-spalte) hinzufügen
  void _addMachine() {
    final machineName = machineController.text.trim();
    if (machineName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bitte geben Sie einen Maschinenname ein.')),
      );
      return;
    }
    setState(() {
      machines.add(machineName);
      // Bestehende Zeilen um eine Spalte erweitern
      for (int i = 0; i < matrixData.length; i++) {
        matrixData[i].add("");
      }
      // Neue Zeile hinzufügen (mit Anzahl Zellen = neue Anzahl der Maschinen)
      matrixData.add(List.generate(machines.length, (_) => ""));
      // Initialisiere TextEditingController für die neue Zeile
      int newRowIndex = matrixData.length - 1;
      for (int j = 0; j < machines.length; j++) {
        _matrixControllers['$newRowIndex-$j'] =
            TextEditingController(text: matrixData[newRowIndex][j]);
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Maschine "$machineName" hinzugefügt.')),
    );
    machineController.clear();
  }

  // Maschine (und zugehörige Zeile und Spalte) löschen
  void _deleteMachine(int index) {
    setState(() {
      machines.removeAt(index);
      matrixData.removeAt(index);
      // Entferne die Spalte 'index' aus allen verbleibenden Zeilen
      for (int i = 0; i < matrixData.length; i++) {
        if (matrixData[i].length > index) {
          matrixData[i].removeAt(index);
        }
      }
      // Entferne zugehörige Controller
      List<String> keysToRemove = [];
      _matrixControllers.forEach((key, controller) {
        final parts = key.split('-');
        int row = int.tryParse(parts[0]) ?? -1;
        int col = int.tryParse(parts[1]) ?? -1;
        if (row == index || col == index) {
          keysToRemove.add(key);
        }
      });
      for (String key in keysToRemove) {
        _matrixControllers[key]?.dispose();
        _matrixControllers.remove(key);
      }
      // Neuindexierung der Controller, da sich Zeilen-/Spaltennummern ändern
      Map<String, TextEditingController> newControllers = {};
      for (int i = 0; i < matrixData.length; i++) {
        for (int j = 0; j < matrixData[i].length; j++) {
          String newKey = '$i-$j';
          if (_matrixControllers.containsKey('$i-$j')) {
            newControllers[newKey] = _matrixControllers['$i-$j']!;
          } else {
            newControllers[newKey] =
                TextEditingController(text: matrixData[i][j]);
          }
        }
      }
      _matrixControllers = newControllers;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Maschine gelöscht.')),
    );
  }

  // Exportiere Matrix als CSV
  void _exportMatrixCsv() {
    final csvBuffer = StringBuffer();
    // Header-Zeile: erstes Feld leer, dann Maschinen-Namen
    csvBuffer.write(',');
    for (final m in machines) {
      csvBuffer.write('$m,');
    }
    csvBuffer.write('\n');
    // Datenzeilen
    for (int i = 0; i < machines.length; i++) {
      csvBuffer.write('${machines[i]},');
      for (int j = 0; j < machines.length; j++) {
        csvBuffer.write('${matrixData[i][j]},');
      }
      csvBuffer.write('\n');
    }
    final csvString = csvBuffer.toString();
    final bytes = utf8.encode(csvString);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..style.display = 'none'
      ..download = 'matrix_data.csv';
    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV exportiert.')),
    );
  }

  // Importiere Matrix CSV
  void _importMatrixCsv() {
    final uploadInput = html.FileUploadInputElement()..accept = '.csv';
    uploadInput.click();
    uploadInput.onChange.listen((event) {
      final file = uploadInput.files?.first;
      if (file == null) return;
      final reader = html.FileReader();
      reader.onLoadEnd.listen((event) {
        if (reader.readyState == html.FileReader.DONE) {
          final csvString = reader.result as String?;
          if (csvString == null) return;
          _parseAndSetMatrixCsv(csvString);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('CSV importiert.')),
          );
        }
      });
      reader.onError.listen((event) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Importieren der CSV.')),
        );
      });
      reader.readAsText(file);
    });
  }

  // Parsen und Setzen der Matrixdaten aus CSV
  void _parseAndSetMatrixCsv(String csvString) {
    final lines =
        csvString.split('\n').where((line) => line.trim().isNotEmpty).toList();
    if (lines.isEmpty) return;
    final header = lines.first.split(',');
    if (header.isEmpty || header[0].trim().isNotEmpty) return;
    List<String> newMachines = header
        .sublist(1)
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    List<List<String>> newMatrixData = [];
    // Jede weitere Zeile: erste Zelle ist Maschinenname, Rest die Matrixwerte
    for (int i = 1; i < lines.length; i++) {
      final parts = lines[i].split(',');
      if (parts.isEmpty) continue;
      String machineName = parts.first.trim();
      if (machineName.isEmpty) continue;
      final rowData = parts.sublist(1).map((e) => e.trim()).toList();
      while (rowData.length < newMachines.length) {
        rowData.add("");
      }
      newMatrixData.add(rowData);
    }
    setState(() {
      machines = newMachines;
      matrixData = newMatrixData;
      _matrixControllers.clear();
      for (int i = 0; i < matrixData.length; i++) {
        for (int j = 0; j < matrixData[i].length; j++) {
          _matrixControllers['$i-$j'] =
              TextEditingController(text: matrixData[i][j]);
        }
      }
    });
  }

  Widget _buildMatrixTable() {
    if (machines.isEmpty) {
      return Center(
        child: Text(
          'Noch keine Matrizen vorhanden.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    // Ermitteln der maximalen Spaltenanzahl in der Matrix
    int maxColumns = machines.length;
    for (var row in matrixData) {
      if (row.length > maxColumns) {
        maxColumns = row.length;
      }
    }

    return Table(
      border: TableBorder.all(color: Colors.grey),
      defaultColumnWidth: IntrinsicColumnWidth(),
      children: [
        // Header-Zeile (Maschinennamen ohne erste Zelle)
        TableRow(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              alignment: Alignment.center,
              child: Text(''), // Erste leere Zelle
            ),
            for (int j = 0; j < maxColumns; j++)
              Container(
                padding: EdgeInsets.all(8),
                alignment: Alignment.center,
                child: j < machines.length
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            machines[j],
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon:
                                Icon(Icons.delete, size: 16, color: Colors.red),
                            onPressed: () => _deleteMachine(j),
                          ),
                        ],
                      )
                    : Text(
                        ""), // Falls Spaltenanzahl größer als Maschinenanzahl ist
              ),
          ],
        ),

        // Datenzeilen (Maschinennamen + Matrixwerte)
        for (int i = 0; i < matrixData.length; i++)
          TableRow(
            children: [
              // Maschinenname (erste Spalte)
              Container(
                padding: EdgeInsets.all(8),
                alignment: Alignment.centerLeft,
                child: i < machines.length
                    ? Text(
                        machines[i],
                        style: TextStyle(fontWeight: FontWeight.bold),
                      )
                    : Text(""),
              ),
              // Matrixwerte (je nach Zeilenlänge angepasst)
              for (int j = 0; j < maxColumns; j++)
                Container(
                  width: 80,
                  padding: EdgeInsets.all(4),
                  child: TextField(
                    controller: _matrixControllers['$i-$j'] ??
                        TextEditingController(
                            text: (j < matrixData[i].length)
                                ? matrixData[i][j]
                                : ""),
                    onChanged: (value) {
                      setState(() {
                        if (j >= matrixData[i].length) {
                          matrixData[i].add(value); // Fehlende Spalten ergänzen
                        } else {
                          matrixData[i][j] = value;
                        }
                      });
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  @override
  void dispose() {
    machineController.dispose();
    _matrixControllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  // ====================== UI Aufbau ======================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Begrüßung
            Text(
              'Willkommen auf der Seite!',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            // Block 1: Produktion (Persönliche Daten)
            _buildBlock(
              title: 'Produktion',
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: 'Name'),
                    onChanged: (value) => setState(() => name = value),
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: 'E-Mail'),
                    onChanged: (value) => setState(() => email = value),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Block 2: Solver Eigenschaften inkl. Import/Export
            _buildBlock(
              title: 'Solver Eigenschaften',
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(labelText: 'Profil'),
                    onChanged: (value) => setState(() => profil = value),
                    controller: TextEditingController(text: profil),
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: 'Number of Jobs'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        setState(() => numberOfJobs = int.tryParse(value)),
                    controller: TextEditingController(
                        text: numberOfJobs?.toString() ?? ''),
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: 'Selected Model'),
                    onChanged: (value) => setState(() => selectedModel = value),
                    controller: TextEditingController(text: selectedModel),
                  ),
                  TextField(
                    decoration:
                        InputDecoration(labelText: 'Solver Time (Sekunden)'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) =>
                        setState(() => solverTime = double.tryParse(value)),
                    controller: TextEditingController(
                        text: solverTime?.toString() ?? ''),
                  ),
                  TextField(
                    decoration: InputDecoration(labelText: 'Solver Gap (%)'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      double? gap = double.tryParse(value);
                      if (gap != null && gap >= 0 && gap <= 100) {
                        setState(() => solverGap = gap);
                      }
                    },
                    controller: TextEditingController(
                        text: solverGap?.toString() ?? ''),
                  ),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _exportSolverProperties,
                        child: Text('Export Solver Eigenschaften'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _pickSolverPropertiesFile,
                        child: Text('Import Solver Eigenschaften'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Block 3: Jobs Tabelle inkl. Import/Export
            _buildBlock(
              title: 'Jobs',
              child: Column(
                children: [
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _addJob,
                        child: Text('Zeile hinzufügen'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _exportJobs,
                        child: Text('Jobs exportieren'),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _pickJobsFile,
                        child: Text('Jobs importieren'),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('Job ID')),
                        DataColumn(label: Text('Due Date')),
                        DataColumn(label: Text('Gesamtdauer (h)')),
                        DataColumn(label: Text('Anzahl')),
                        DataColumn(label: Text('Amount')),
                        DataColumn(label: Text('Priorität')),
                      ],
                      rows: jobs.asMap().entries.map((entry) {
                        int index = entry.key;
                        Map<String, dynamic> job = entry.value;
                        return DataRow(
                          cells: [
                            DataCell(
                              TextField(
                                keyboardType: TextInputType.number,
                                onChanged: (value) => setState(() {
                                  job['Job ID'] = int.tryParse(value);
                                }),
                                controller: TextEditingController(
                                    text: job['Job ID']?.toString() ?? ''),
                              ),
                            ),
                            DataCell(
                              InkWell(
                                onTap: () => _pickDueDate(context, index),
                                child: Text(
                                  (job['Due Date'] != null &&
                                          job['Due Date'].length >= 10)
                                      ? job['Due Date'].substring(0, 10)
                                      : '',
                                ),
                              ),
                            ),
                            DataCell(
                              TextField(
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                                onChanged: (value) => setState(() {
                                  job['Gesamtdauer'] =
                                      double.tryParse(value) ?? 0.0;
                                }),
                                controller: TextEditingController(
                                    text: job['Gesamtdauer'].toString()),
                              ),
                            ),
                            DataCell(
                              TextField(
                                keyboardType: TextInputType.number,
                                onChanged: (value) => setState(() {
                                  job['Anzahl'] = int.tryParse(value) ?? 0;
                                }),
                                controller: TextEditingController(
                                    text: job['Anzahl'].toString()),
                              ),
                            ),
                            DataCell(
                              TextField(
                                keyboardType: TextInputType.number,
                                onChanged: (value) => setState(() {
                                  job['Amount'] = int.tryParse(value) ?? 0;
                                }),
                                controller: TextEditingController(
                                    text: job['Amount'].toString()),
                              ),
                            ),
                            DataCell(
                              TextField(
                                keyboardType: TextInputType.number,
                                onChanged: (value) => setState(() {
                                  job['Priorität'] = int.tryParse(value) ?? 0;
                                }),
                                controller: TextEditingController(
                                    text: job['Priorität'].toString()),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            // Block 4: Matrizen (Matrix bearbeiten)
            _buildBlock(
              title: 'Matrizen',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Zeile: Maschine hinzufügen
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: machineController,
                          decoration: InputDecoration(
                            labelText: 'Maschine hinzufügen',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: _addMachine,
                        child: Text('Hinzufügen'),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Zeile: Export und Import CSV
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _exportMatrixCsv,
                        child: Text('Export CSV'),
                      ),
                      SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _importMatrixCsv,
                        child: Text('Import CSV'),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  // Matrix-Tabelle
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.vertical,
                      child: _buildMatrixTable(),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),
            // Fett formatierter Button "Auftrag abschicken"
            Container(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitOrder,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  textStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: Text('Auftrag abschicken'),
              ),
            ),

            Container(
              width: double.infinity,
              margin: EdgeInsets.only(top: 16),
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: SelectableText(
                _buildDebugText(),
                style: TextStyle(fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Ein Hilfswidget für die Blöcke
Widget _buildBlock({required String title, required Widget child}) {
  return Container(
    width: double.infinity,
    padding: EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(8),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        SizedBox(height: 8),
        child,
      ],
    ),
  );
}

import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:http/http.dart' as http;
import 'package:csv/csv.dart';

class MatrizenPage extends StatefulWidget {
  @override
  _MatrizenPageState createState() => _MatrizenPageState();
}

class _MatrizenPageState extends State<MatrizenPage> {
  final TextEditingController machineController = TextEditingController();
  List<String> machines = [];
  List<List<String>> matrixData = [];
  List<Reference> uploadedFiles = [];
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  // Map to store TextEditingControllers for each cell
  Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    print('initState: Laden der hochgeladenen Dateien...');
    _loadUploadedFiles();
  }

  @override
  void dispose() {
    machineController.dispose();
    _controllers.forEach((key, controller) => controller.dispose());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text('Rüstmatrizen'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Dashboard ---
            _buildDashboard(user),

            // --- Maschine hinzufügen ---
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: machineController,
                    decoration: InputDecoration(
                      labelText: 'Matrixelement hinzufügen',
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
            SizedBox(height: 16),

            // --- Buttons: Export, Import, Upload ---
            Row(
              children: [
                ElevatedButton(
                  onPressed: _exportToCsvWeb,
                  child: Text('Export CSV'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _importCsvWeb,
                  child: Text('Import CSV'),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _uploadToServer,
                  child: Text('Upload CSV'),
                ),
              ],
            ),
            Divider(),

            // --- Matrix selbst ---
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: _buildMatrixTable(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Dashboard Widget ---
  Widget _buildDashboard(User? user) {
    return Card(
      elevation: 4,
      margin: EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Willkommen, ${user?.email ?? 'Gast'}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              "Hochgeladene Dateien:",
              style: TextStyle(fontSize: 16),
            ),
            if (uploadedFiles.isEmpty)
              Text("Keine Dateien hochgeladen.")
            else
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: uploadedFiles.length,
                itemBuilder: (context, index) {
                  final file = uploadedFiles[index];
                  return ListTile(
                    title: Text(file.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.download),
                          color: Colors.blue,
                          onPressed: () => _downloadFile(file),
                        ),
                        IconButton(
                          icon: Icon(Icons.visibility),
                          color: Colors.green,
                          onPressed: () => _displayFile(file.fullPath),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  // --- Add Machine ---
  void _addMachine() {
    final name = machineController.text.trim();
    if (name.isEmpty) {
      print('AddMachine: Kein Maschinenname eingegeben.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bitte geben Sie einen Maschinenname ein.')),
      );
      return;
    }

    setState(() {
      machines.add(name);
      for (var row in matrixData) {
        row.add("");
      }
      matrixData.add(List.generate(machines.length, (_) => ""));

      // Initialize controllers for the new row
      int newRowIndex = matrixData.length - 1;
      for (int j = 0; j < machines.length; j++) {
        _controllers['$newRowIndex-$j'] =
            TextEditingController(text: matrixData[newRowIndex][j]);
      }
    });

    print('AddMachine: Maschine "$name" hinzugefügt.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Maschine "$name" erfolgreich hinzugefügt.')),
    );
    machineController.clear();
  }

  // --- Export CSV ---
  void _exportToCsvWeb() {
    print('ExportToCsvWeb: CSV-Export gestartet.');
    final csvBuffer = StringBuffer();

    // Header Row
    csvBuffer.write(',');
    for (final machine in machines) {
      csvBuffer.write('$machine,');
    }
    csvBuffer.write('\n');

    // Data Rows
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
      ..download = 'machine_data.csv';

    html.document.body?.children.add(anchor);
    anchor.click();
    html.document.body?.children.remove(anchor);
    html.Url.revokeObjectUrl(url);

    print('ExportToCsvWeb: CSV-Download abgeschlossen.');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV-Download gestartet!')),
    );
  }

  // --- Upload CSV to Firebase Storage ---
  Future<void> _uploadToServer() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      print('UploadToServer: Benutzer ist nicht angemeldet.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bitte melden Sie sich zuerst an.')),
      );
      return;
    }

    final csvString = _generateCsvString();
    final bytes = utf8.encode(csvString);
    final blob = html.Blob([bytes], 'text/csv');

    final storageRef = _storage.ref().child(
        'users/${user.uid}/csv_files/${DateTime.now().millisecondsSinceEpoch}.csv');

    print('UploadToServer: Hochladen der CSV-Datei gestartet.');
    try {
      await storageRef.putBlob(blob);
      final url = await storageRef.getDownloadURL();

      setState(() {
        uploadedFiles.add(storageRef);
      });

      print('UploadToServer: CSV erfolgreich hochgeladen. URL: $url');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('CSV erfolgreich hochgeladen!')),
      );
    } on FirebaseException catch (e) {
      print(
          'UploadToServer: FirebaseException beim Upload - Code: ${e.code}, Message: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Upload: ${e.message}')),
      );
    } catch (e) {
      print('UploadToServer: Fehler beim Upload - $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Upload: $e')),
      );
    }
  }

  // --- Load Uploaded Files from Firebase Storage ---
  Future<void> _loadUploadedFiles() async {
    final User? user = _auth.currentUser;
    if (user == null) {
      print('LoadUploadedFiles: Benutzer ist nicht angemeldet.');
      return;
    }

    print(
        'LoadUploadedFiles: Laden der hochgeladenen Dateien für Benutzer ${user.uid}.');

    try {
      final ListResult result =
          await _storage.ref().child('users/${user.uid}/csv_files').listAll();

      setState(() {
        uploadedFiles = result.items;
      });

      for (var ref in uploadedFiles) {
        final url = await ref.getDownloadURL();
        print('LoadUploadedFiles: Gefundene Datei - $url');
      }

      print('LoadUploadedFiles: Alle Dateien erfolgreich geladen.');
    } on FirebaseException catch (e) {
      print(
          'LoadUploadedFiles: FirebaseException beim Laden der Dateien - Code: ${e.code}, Message: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Laden der Dateien: ${e.message}')),
      );
    } catch (e) {
      print('LoadUploadedFiles: Fehler beim Laden der Dateien - $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Laden der Dateien: $e')),
      );
    }
  }

  // --- Download File from Server ---
  void _downloadFile(Reference fileRef) async {
    try {
      final downloadUrl = await fileRef.getDownloadURL();
      html.AnchorElement anchor = new html.AnchorElement(href: downloadUrl)
        ..target = 'blank'
        ..download = fileRef.name;
      html.document.body?.children.add(anchor);
      anchor.click();
      html.document.body?.children.remove(anchor);
      print('DownloadFile: Datei-Download gestartet.');
    } catch (e) {
      print('DownloadFile: Fehler beim Herunterladen der Datei - $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Herunterladen der Datei: $e')),
      );
    }
  }

  // --- Display File from Server ---
  Future<void> _displayFile(String filePath) async {
    print('DisplayFile: Versuche, die Datei anzuzeigen - $filePath');
    try {
      final storageRef = _storage.ref(filePath);
      final downloadUrl = await storageRef.getDownloadURL();
      print('DisplayFile: Download-URL erhalten - $downloadUrl');

      // Bestimmen Sie den Dateityp anhand der Dateiendung
      String fileExtension = filePath.split('.').last.toLowerCase();

      if (['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension)) {
        // Anzeigen von Bildern
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            content: Image.network(downloadUrl),
          ),
        );
      } else if (fileExtension == 'csv') {
        // Abrufen und Anzeigen von CSV-Daten
        final response = await http.get(Uri.parse(downloadUrl));
        if (response.statusCode == 200) {
          final csvString = utf8.decode(response.bodyBytes);
          if (csvString.trim().isEmpty) {
            print('DisplayFile: Dateiinhalt ist leer.');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Die Datei ist leer.')),
            );
            return;
          }

          // Parsen der CSV-Daten
          List<List<dynamic>> csvTable =
              CsvToListConverter().convert(csvString);

          // Anzeigen der CSV-Daten in einem Dialog
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('CSV-Inhalt'),
              content: Container(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: csvTable.isNotEmpty
                        ? csvTable[0]
                            .map((header) => DataColumn(
                                  label: Text(
                                    header.toString(),
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ))
                            .toList()
                        : [],
                    rows: csvTable.length > 1
                        ? csvTable
                            .skip(1)
                            .map(
                              (row) => DataRow(
                                cells: row
                                    .map(
                                      (cell) => DataCell(Text(cell.toString())),
                                    )
                                    .toList(),
                              ),
                            )
                            .toList()
                        : [],
                  ),
                ),
              ),
            ),
          );
        } else {
          throw Exception('HTTP-Fehler: ${response.statusCode}');
        }
      } else if (['pdf'].contains(fileExtension)) {
        // Öffnen der PDF-Datei in einem neuen Tab
        _displayPDF(downloadUrl);
      } else {
        // Für andere Dateitypen können Sie eine Meldung anzeigen oder eine geeignete Aktion durchführen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Dateityp wird nicht unterstützt.')),
        );
      }
    } on FirebaseException catch (e) {
      print(
          'DisplayFile: FirebaseException beim Laden der Datei - Code: ${e.code}, Message: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('Firebase-Fehler beim Laden der Datei: ${e.message}')),
      );
    } on http.ClientException catch (e) {
      print(
          'DisplayFile: ClientException beim Laden der Datei - Message: ${e.message}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Client-Fehler beim Laden der Datei: ${e.message}')),
      );
    } catch (e, stackTrace) {
      print('DisplayFile: Unbekannte Ausnahme beim Laden der Datei - $e');
      print('StackTrace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unbekannter Fehler beim Laden der Datei: $e')),
      );
    }
  }

  // --- Anzeigen von PDFs in einem neuen Tab ---
  void _displayPDF(String downloadUrl) {
    html.window.open(downloadUrl, '_blank');
  }

  // --- Import CSV from Local File ---
  void _importCsvWeb() {
    print('ImportCsvWeb: CSV-Import gestartet.');
    final uploadInput = html.FileUploadInputElement()..accept = '.csv';
    uploadInput.click();

    uploadInput.onChange.listen((html.Event event) {
      final file = uploadInput.files?.first;
      if (file == null) {
        print('ImportCsvWeb: Keine Datei ausgewählt.');
        return;
      }

      print('ImportCsvWeb: Datei ausgewählt - ${file.name}');
      final reader = html.FileReader();
      reader.onLoadEnd.listen((html.ProgressEvent evt) {
        if (reader.readyState == html.FileReader.DONE) {
          final csvString = reader.result as String?;
          if (csvString == null) {
            print('ImportCsvWeb: CSV-Datei konnte nicht gelesen werden.');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('CSV-Datei konnte nicht gelesen werden.')),
            );
            return;
          }
          try {
            _parseAndSetCsv(csvString);
            print('ImportCsvWeb: CSV erfolgreich importiert.');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('CSV erfolgreich importiert!')),
            );
          } catch (e) {
            print('ImportCsvWeb: Fehler beim Parsen der CSV-Datei - $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Fehler beim Parsen der CSV-Datei: $e')),
            );
          }
        }
      });
      reader.onError.listen((event) {
        print('ImportCsvWeb: Fehler beim Lesen der Datei.');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Lesen der Datei.')),
        );
      });
      reader.readAsText(file);
      print('ImportCsvWeb: Datei wird gelesen...');
    });
  }

  // --- Parse and Set CSV Data ---
  void _parseAndSetCsv(String csvString) {
    print('ParseAndSetCsv: Beginne mit dem Parsen der CSV-Daten.');
    if (csvString.trim().isEmpty) {
      print('ParseAndSetCsv: CSV-String ist leer.');
      return;
    }

    final lines = csvString.split('\n').where((line) => line.trim().isNotEmpty);
    if (lines.isEmpty) {
      print('ParseAndSetCsv: Keine gültigen Zeilen in der CSV-Datei gefunden.');
      return;
    }

    final header = lines.first.split(',');

    // Assuming the first cell is empty
    if (header.isEmpty || header[0].trim().isNotEmpty) {
      print('ParseAndSetCsv: Ungültiger Header in der CSV-Datei.');
      return;
    }

    // Extract machine names from header, skipping the first empty cell
    final machineList = header.sublist(1);

    final newMachines = <String>[];
    for (var m in machineList) {
      final trimmed = m.trim();
      if (trimmed.isNotEmpty) {
        newMachines.add(trimmed);
      }
    }

    if (newMachines.isEmpty) {
      print('ParseAndSetCsv: Keine Maschinen in der CSV-Datei gefunden.');
      return;
    }

    final newMatrixData = <List<String>>[];
    final dataLines = lines.skip(1);
    for (final line in dataLines) {
      final columns = line.split(',');
      if (columns.length < 1) {
        print('ParseAndSetCsv: Überspringe leere Zeile.');
        continue;
      }

      // First column is the machine name
      final machineName = columns[0].trim();
      if (machineName.isEmpty) {
        print('ParseAndSetCsv: Maschinenname fehlt in der Zeile.');
        continue;
      }

      // Die restlichen sind die Matrixwerte
      final rowData = columns.sublist(1);
      // Ensure the row has enough columns by padding with empty strings if necessary
      while (rowData.length < newMachines.length) {
        rowData.add("");
      }

      // Trim each cell
      final trimmedRowData = rowData.map((c) => c.trim()).toList();

      newMatrixData.add(trimmedRowData);
    }

    setState(() {
      machines = newMachines;
      matrixData = newMatrixData;

      // Initialize controllers
      _controllers.clear();
      for (int i = 0; i < matrixData.length; i++) {
        for (int j = 0; j < matrixData[i].length; j++) {
          String key = '$i-$j';
          _controllers[key] = TextEditingController(text: matrixData[i][j]);
        }
      }
    });

    print('ParseAndSetCsv: CSV-Daten erfolgreich geparst und gesetzt.');
  }

  // --- Generate CSV String from Matrix Data ---
  String _generateCsvString() {
    final csvBuffer = StringBuffer();
    csvBuffer.write(',');
    for (final machine in machines) {
      csvBuffer.write('$machine,');
    }
    csvBuffer.write('\n');

    for (int i = 0; i < machines.length; i++) {
      csvBuffer.write('${machines[i]},');
      for (int j = 0; j < machines.length; j++) {
        csvBuffer.write('${matrixData[i][j]},');
      }
      csvBuffer.write('\n');
    }

    return csvBuffer.toString();
  }

  // --- Build Matrix Table ---
  Widget _buildMatrixTable() {
    if (machines.isEmpty) {
      return Center(
        child: Text(
          'Noch keine Maschinen vorhanden.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Table(
      border: TableBorder.all(color: Colors.grey),
      defaultColumnWidth: IntrinsicColumnWidth(),
      children: [
        // Header Row
        TableRow(
          children: [
            Container(
              padding: EdgeInsets.all(8.0),
              alignment: Alignment.center,
              child: Text(''),
            ),
            for (final machine in machines)
              Container(
                padding: EdgeInsets.all(8.0),
                alignment: Alignment.center,
                child: Text(
                  machine,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        // Data Rows
        for (int i = 0; i < machines.length; i++)
          TableRow(
            children: [
              // Row Header
              Container(
                padding: EdgeInsets.all(8.0),
                alignment: Alignment.centerLeft,
                child: Text(
                  machines[i],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              // Matrix Cells
              for (int j = 0; j < machines.length; j++)
                Container(
                  width: 80,
                  padding: EdgeInsets.all(4.0),
                  child: TextField(
                    controller: _controllers['$i-$j'],
                    onChanged: (value) {
                      setState(() {
                        matrixData[i][j] = value;
                      });
                      print(
                          'MatrixTable: Zelle [$i][$j] geändert zu "$value".');
                    },
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';

class Page2 extends StatefulWidget {
  @override
  _Page2State createState() => _Page2State();
}

class _Page2State extends State<Page2> {
  final TextEditingController rowController = TextEditingController();
  final TextEditingController columnController = TextEditingController();

  List<String> rows = [];
  List<String> columns = [];
  List<List<String>> matrixData = [];
  String csvResult = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Jobs'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // --- Zeilen- und Spalten hinzufügen ---
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: rowController,
                    decoration: InputDecoration(
                      labelText: 'Neue Zeile hinzufügen',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addRow,
                  child: Text('Zeile hinzufügen'),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: TextField(
                    controller: columnController,
                    decoration: InputDecoration(
                      labelText: 'Neue Spalte hinzufügen',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _addColumn,
                  child: Text('Spalte hinzufügen'),
                ),
              ],
            ),
            SizedBox(height: 16),

            // --- Buttons: Export, Import ---
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
              ],
            ),
            Divider(),

            // --- CSV Ergebnis ---
            if (csvResult.isNotEmpty)
              Container(
                padding: EdgeInsets.all(8.0),
                color: Colors.grey[200],
                child: Text(
                  csvResult,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

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

  void _addRow() {
    final name = rowController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      rows.add(name);
      // Füge der Matrix eine neue Zeile hinzu
      matrixData.add(List.generate(columns.length, (_) => ""));
    });

    rowController.clear();
  }

  void _addColumn() {
    final name = columnController.text.trim();
    if (name.isEmpty) return;

    setState(() {
      columns.add(name);
      // Füge jeder bestehenden Zeile eine neue Spalte hinzu
      for (var row in matrixData) {
        row.add("");
      }
    });

    columnController.clear();
  }

  void _exportToCsvWeb() {
    final csvBuffer = StringBuffer();

    // Kopfzeile: (leer) + Spaltennamen
    csvBuffer.write(',');
    for (final column in columns) {
      csvBuffer.write('$column,');
    }
    csvBuffer.write('\n');

    // Datenzeilen mit Zeilennamen
    for (int i = 0; i < rows.length; i++) {
      csvBuffer.write('${rows[i]},');
      for (int j = 0; j < columns.length; j++) {
        csvBuffer.write('${matrixData[i][j]},');
      }
      csvBuffer.write('\n');
    }

    final csvString = csvBuffer.toString();
    final bytes = utf8.encode(csvString);
    final blob = html.Blob([bytes], 'text/csv');
    final url = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.document.createElement('a') as html.AnchorElement
      ..href = url
      ..style.display = 'none'
      ..download = 'matrix_data.csv';

    html.document.body!.children.add(anchor);
    anchor.click();
    html.document.body!.children.remove(anchor);
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV-Download gestartet!')),
    );
  }

  void _importCsvWeb() {
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
          _parseAndSetCsv(csvString);
        }
      });
      reader.readAsText(file);
    });
  }

  void _parseAndSetCsv(String csvString) {
    if (csvString.trim().isEmpty) return;

    final lines = csvString.split('\n').where((line) => line.trim().isNotEmpty);
    if (lines.isEmpty) return;

    final header = lines.first.split(',');
    final columnList =
        header.sublist(1).where((c) => c.trim().isNotEmpty).toList();

    final newRows = <String>[];
    final newColumns = <String>[]..addAll(columnList);

    final newMatrixData = <List<String>>[];
    final dataLines = lines.skip(1);

    for (final line in dataLines) {
      final columns = line.split(',');
      if (columns.isEmpty) continue;

      newRows.add(columns.first.trim());
      final rowData =
          columns.sublist(1).where((c) => c.trim().isNotEmpty).toList();

      newMatrixData.add(
        List.generate(newColumns.length, (index) {
          if (index < rowData.length) {
            return rowData[index];
          }
          return "";
        }),
      );
    }

    setState(() {
      rows = newRows;
      columns = newColumns;
      matrixData = newMatrixData;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('CSV importiert!')),
    );
  }

  Widget _buildMatrixTable() {
    if (rows.isEmpty || columns.isEmpty) {
      return Center(
        child: Text(
          'Noch keine Daten vorhanden.',
          style: TextStyle(fontSize: 16),
        ),
      );
    }

    return Table(
      border: TableBorder.all(color: Colors.grey),
      defaultColumnWidth: IntrinsicColumnWidth(),
      children: [
        // Kopfzeile mit Spaltennamen
        TableRow(
          children: [
            Container(
              padding: EdgeInsets.all(8.0),
              alignment: Alignment.center,
              child: Text(''),
            ),
            for (final column in columns)
              Container(
                padding: EdgeInsets.all(8.0),
                alignment: Alignment.center,
                child: Text(
                  column,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        // Zeilen mit Zeilennamen
        for (int i = 0; i < rows.length; i++)
          TableRow(
            children: [
              Container(
                padding: EdgeInsets.all(8.0),
                alignment: Alignment.centerLeft,
                child: Text(
                  rows[i],
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              for (int j = 0; j < columns.length; j++)
                Container(
                  width: 80,
                  padding: EdgeInsets.all(4.0),
                  child: TextField(
                    controller: TextEditingController(
                      text: matrixData[i][j],
                    ),
                    onChanged: (value) {
                      matrixData[i][j] = value;
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

import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

class Page4 extends StatefulWidget {
  @override
  _Page4State createState() => _Page4State();
}

class _Page4State extends State<Page4> {
  List<String> uploadedFiles = [];
  String? previewFile;
  Uint8List? selectedFileBytes;
  bool isUploading = false;

  final FirebaseStorage storage = FirebaseStorage.instance;

  // Datei auswählen (CSV oder Excel)
  void _pickFile() {
    final uploadInput = html.FileUploadInputElement()
      ..accept = '.csv,.xlsx,.xls';
    uploadInput.click();
    print("[DEBUG] Datei-Upload-Dialog geöffnet.");

    uploadInput.onChange.listen((event) {
      final file = uploadInput.files?.first;
      if (file == null) {
        print("[DEBUG] Keine Datei ausgewählt.");
        return;
      }

      print("[DEBUG] Datei ausgewählt: ${file.name} (${file.size} Bytes)");

      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);

      reader.onLoadEnd.listen((event) {
        setState(() {
          previewFile = file.name;
          selectedFileBytes = reader.result as Uint8List;
        });
        print("[DEBUG] Datei wurde erfolgreich gelesen: ${file.name}");
      });

      reader.onError.listen((error) {
        print("[ERROR] Fehler beim Lesen der Datei: $error");
      });
    });
  }

  // Datei auf Firebase Storage hochladen
  Future<void> _uploadFile() async {
    if (previewFile == null || selectedFileBytes == null) {
      print("[DEBUG] Kein Dateiname oder keine Bytes vorhanden.");
      return;
    }

    setState(() {
      isUploading = true;
    });

    try {
      final ref = storage.ref().child(
          "resources/${DateTime.now().millisecondsSinceEpoch}_$previewFile");
      final uploadTask = ref.putData(selectedFileBytes!);

      print("[DEBUG] Starte Upload: $previewFile");

      // Fortschrittsanzeige
      uploadTask.snapshotEvents.listen((taskSnapshot) {
        switch (taskSnapshot.state) {
          case TaskState.running:
            print(
                "[DEBUG] Upload läuft: ${taskSnapshot.bytesTransferred} / ${taskSnapshot.totalBytes}");
            break;
          case TaskState.success:
            print("[DEBUG] Upload abgeschlossen!");
            break;
          case TaskState.error:
            print("[ERROR] Upload fehlgeschlagen!");
            break;
          default:
            break;
        }
      });

      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();

      setState(() {
        uploadedFiles.add(downloadUrl);
        previewFile = null;
        selectedFileBytes = null;
        isUploading = false;
      });

      print("[DEBUG] Datei hochgeladen: $downloadUrl");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Datei erfolgreich hochgeladen!")),
      );
    } catch (e) {
      setState(() {
        isUploading = false;
      });
      print("[ERROR] Fehler beim Hochladen: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Fehler beim Hochladen: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text('Ressourcen')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Wähle eine CSV- oder Excel-Datei aus:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),

            Row(
              children: [
                ElevatedButton(
                  onPressed: _pickFile,
                  child: Text("Datei auswählen"),
                ),
                SizedBox(width: 16),
                ElevatedButton(
                  onPressed: isUploading ? null : _uploadFile,
                  child: isUploading
                      ? CircularProgressIndicator()
                      : Text("Hochladen"),
                ),
              ],
            ),

            SizedBox(height: 16),
            Divider(),

            // Preview- und Ressourcen-Bereich nebeneinander
            Expanded(
              child: Row(
                children: [
                  // Preview-Bereich
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.only(right: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Datei-Vorschau",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          if (previewFile == null)
                            Text("Keine Datei ausgewählt."),
                          if (previewFile != null)
                            Text(previewFile!,
                                style: TextStyle(
                                    color: Colors.blue,
                                    fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),

                  // Ressourcen-Bereich
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: EdgeInsets.all(16),
                      margin: EdgeInsets.only(left: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hochgeladene Ressourcen",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          if (uploadedFiles.isEmpty)
                            Text("Noch keine Dateien hochgeladen."),
                          for (String file in uploadedFiles)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 4.0),
                              child: Text("- $file"),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

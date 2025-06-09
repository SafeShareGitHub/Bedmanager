import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Controller für Eingabefelder
  final TextEditingController box1Controller = TextEditingController();
  final TextEditingController box2Controller = TextEditingController();
  final TextEditingController box3Controller = TextEditingController();

  // Listen für Einträge
  List<String> box1Items = [];
  List<String> box2Items = [];
  List<String> box3Items = [];

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Begrüßung und Benutzername
            Text(
              'Willkommen, ${user?.email ?? 'Benutzer'}',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            // Dashboard-Bereiche
            Expanded(
              child: Row(
                children: [
                  // Box 1
                  Expanded(
                    child: Card(
                      color: Colors.blue.shade100,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Box 1',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Expanded(
                              child: ListView.builder(
                                itemCount: box1Items.length,
                                itemBuilder: (context, index) {
                                  return Text(box1Items[index]);
                                },
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: box1Controller,
                                    decoration: InputDecoration(
                                      hintText: 'Neuer Eintrag',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      if (box1Controller.text.isNotEmpty) {
                                        box1Items.add(box1Controller.text);
                                        box1Controller.clear();
                                      }
                                    });
                                  },
                                  child: Text('Hinzufügen'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),

                  // Box 2
                  Expanded(
                    child: Card(
                      color: Colors.green.shade100,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Box 2',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Expanded(
                              child: ListView.builder(
                                itemCount: box2Items.length,
                                itemBuilder: (context, index) {
                                  return Text(box2Items[index]);
                                },
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: box2Controller,
                                    decoration: InputDecoration(
                                      hintText: 'Neuer Eintrag',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      if (box2Controller.text.isNotEmpty) {
                                        box2Items.add(box2Controller.text);
                                        box2Controller.clear();
                                      }
                                    });
                                  },
                                  child: Text('Hinzufügen'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),

                  // Box 3
                  Expanded(
                    child: Card(
                      color: Colors.purple.shade100,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Box 3',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 8),
                            Expanded(
                              child: ListView.builder(
                                itemCount: box3Items.length,
                                itemBuilder: (context, index) {
                                  return Text(box3Items[index]);
                                },
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: box3Controller,
                                    decoration: InputDecoration(
                                      hintText: 'Neuer Eintrag',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      if (box3Controller.text.isNotEmpty) {
                                        box3Items.add(box3Controller.text);
                                        box3Controller.clear();
                                      }
                                    });
                                  },
                                  child: Text('Hinzufügen'),
                                ),
                              ],
                            ),
                          ],
                        ),
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

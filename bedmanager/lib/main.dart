import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bedmanager/Screens/register/login.dart';
import 'package:bedmanager/util/pagewrapper.dart';

// Deine Firebase-Konfiguration
const firebaseConfig = FirebaseOptions(
  apiKey: "AIzaSyDGW_e8CLKAzPml5l9rZh9V29a7wMphqQ4",
  authDomain: "bedmanager.firebaseapp.com",
  projectId: "bedmanager",
  storageBucket: "bedmanager.firebasestorage.app",
  messagingSenderId: "395769269591",
  appId: "1:395769269591:web:da52ddf094e7fc12e5c212",
);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(App());
}

class App extends StatelessWidget {
  // Initialisierung von Firebase als Future
  final Future<FirebaseApp> _initFirebase =
      Firebase.initializeApp(options: firebaseConfig);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: _initFirebase,
      builder: (ctx, snapshot) {
        // Fehler beim Initialisieren?
        if (snapshot.hasError) {
          return MaterialApp(
            home: Scaffold(
              body:
                  Center(child: Text('Firebase init error: ${snapshot.error}')),
            ),
          );
        }
        // Noch nicht fertig? Zeige Loader.
        if (snapshot.connectionState != ConnectionState.done) {
          return MaterialApp(
            home: Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        // Firebase ist bereit → Haupt-App
        return MyApp();
      },
    );
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Web Navigation with Firebase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      initialRoute: '/home',
      routes: {
        '/login': (_) => LoginScreen(),
        '/home': (_) => PageWrapper(currentPage: 0),
        '/atlantic': (_) => PageWrapper(currentPage: 1),
        '/harmony': (_) => PageWrapper(currentPage: 2),
        '/neptune': (_) => PageWrapper(currentPage: 3),
        '/ocean': (_) => PageWrapper(currentPage: 4),
        '/pacific': (_) => PageWrapper(currentPage: 5),
        '/peace': (_) => PageWrapper(currentPage: 6),
        '/sunlight': (_) => PageWrapper(currentPage: 7),
        '/sunrise': (_) => PageWrapper(currentPage: 8),
        '/sunray': (_) => PageWrapper(currentPage: 9),
        '/sunset': (_) => PageWrapper(currentPage: 10),
        '/sunshine': (_) => PageWrapper(currentPage: 11),
        '/sunday': (_) => PageWrapper(currentPage: 12),
      },
    );
  }
}

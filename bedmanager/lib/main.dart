import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:bedmanager/Screens/home.dart';
import 'package:bedmanager/Screens/page2.dart';
import 'package:bedmanager/Screens/Matrizen_page.dart';
import 'package:bedmanager/Screens/page4.dart';
import 'package:bedmanager/Screens/page5.dart';
import 'package:bedmanager/Screens/page6.dart';
import 'package:bedmanager/Screens/register/login.dart';
import 'package:bedmanager/util/pagewrapper.dart';

// Replace the following with your actual Firebase configuration
const firebaseConfig = FirebaseOptions(
  apiKey: "AIzaSyAZLCMacr1rTjnCtivsOjv5U9E_GpNQfGo",
  authDomain: "quaternion-96a1f.firebaseapp.com",
  projectId: "quaternion-96a1f",
  storageBucket: "quaternion-96a1f.firebasestorage.app",
  messagingSenderId: "738212412548",
  appId: "1:738212412548:web:98602267087d0307cb96d1",
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: firebaseConfig);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Web Navigation with Firebase',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      // Initiale Route: Login-Screen
      initialRoute: '/home',
      routes: {
        '/login': (context) => LoginScreen(),
        '/home': (context) => PageWrapper(currentPage: 0),
        '/atlantic': (context) => PageWrapper(currentPage: 1),
        '/harmony': (context) => PageWrapper(currentPage: 2),
        '/neptune': (context) => PageWrapper(currentPage: 3),
        '/ocean': (context) => PageWrapper(currentPage: 4),
        '/pacific': (context) => PageWrapper(currentPage: 5),
        '/peace': (context) => PageWrapper(currentPage: 6),
        '/sunlight': (context) => PageWrapper(currentPage: 7),
        '/sunrise': (context) => PageWrapper(currentPage: 8),
        '/sunray': (context) => PageWrapper(currentPage: 9),
        '/sunset': (context) => PageWrapper(currentPage: 10),
        '/sunshine': (context) => PageWrapper(currentPage: 11),
        '/sunday': (context) => PageWrapper(currentPage: 12),
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'subject_page.dart';
import 'package:logger/logger.dart';
import 'package:lottie/lottie.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(const MyAppLoader()); // Menampilkan layar loading terlebih dahulu

  var logger = Logger(); // Inisialisasi logger

  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'AIzaSyDLPEYoVa9zDTnSYo2fJwjJ7rKzHZTSCKk',
        appId: '1:31816478123:android:4687b2935f7abe4a32f6ee',
        messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
        projectId: 'facerecog-4de3d',
        databaseURL: 'https://facerecog-4de3d-default-rtdb.asia-southeast1.firebasedatabase.app',
        storageBucket: 'facerecog-4de3d.appspot.com',
      ),
    );
    runApp(const MyApp());
  } catch (e) {
    logger.e("Failed to initialize Firebase: ${e.toString()}");
    runApp(MyAppNotConnected(errorMessage: e.toString()));
  }
}

class MyAppLoader extends StatelessWidget {
  const MyAppLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Lottie.asset(
            'assets/loading.json', // Path to your Lottie JSON file
            width: 200,
            height: 200,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Absensi Guru',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SubjectPage(),
    );
  }
}

class MyAppNotConnected extends StatelessWidget {
  final String errorMessage;

  const MyAppNotConnected({super.key, required this.errorMessage});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Connection Error'),
        ),
        body: Center(
          child: Text('Failed to initialize Firebase: $errorMessage'),
        ),
      ),
    );
  }
}
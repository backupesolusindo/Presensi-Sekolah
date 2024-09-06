import 'package:flutter/material.dart';
import 'register_face_page.dart';
import 'face_attendance_page.dart';
import 'package:firebase_core/firebase_core.dart';
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
        messagingSenderId: '31816478123',
        projectId: 'facerecog-4de3d',
        databaseURL:
            'https://facerecog-4de3d-default-rtdb.asia-southeast1.firebasedatabase.app',
        storageBucket: 'facerecog-4de3d.appspot.com',
      ),
    );
    runApp(MyApp());
  } catch (e) {
    logger
        .e("Failed to initialize Firebase: ${e.toString()}"); // Gunakan logger
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
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: HomePage(),
      routes: {
        '/register-face': (context) => RegisterFacePage(),
        '/face-attendance': (context) => FaceAttendancePage(),
      },
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color.fromARGB(255, 129, 198, 255),
              const Color.fromARGB(255, 10, 59, 103),
            ],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Text di atas Card
              Text(
                'Welcome to Face Recognition App',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 10), // Spasi antara teks

              // Text tambahan di bawah welcome text
              Text(
                'Your one-stop solution for secure face-based authentication',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20), // Spasi antara teks dan Card

              // Card yang membungkus tombol
              Container(
                width: 350,
                height: 150, // Menentukan lebar card
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  margin: EdgeInsets.symmetric(
                      horizontal: 20), // Menyesuaikan margin
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Register Face Button dengan gradasi
                        Container(
                          height: 45,
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color.fromARGB(255, 129, 198, 255),
                                  const Color.fromARGB(255, 10, 59, 103),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(255, 0, 0, 0)
                                      .withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(context, '/register-face');
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.face,
                                      size: 30, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text('Register Face',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 20),
                        // Face Attendance Button dengan gradasi
                        Container(
                          height: 45,
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  const Color.fromARGB(255, 129, 198, 255),
                                  const Color.fromARGB(255, 10, 59, 103),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color.fromARGB(255, 0, 0, 0)
                                      .withOpacity(0.5),
                                  spreadRadius: 2,
                                  blurRadius: 5,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.pushNamed(
                                    context, '/face-attendance');
                              },
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 10),
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.how_to_reg,
                                      size: 30, color: Colors.white),
                                  SizedBox(width: 10),
                                  Text('Face Attendance',
                                      style: TextStyle(
                                          fontSize: 16, color: Colors.white)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

// import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'login.dart';
import 'package:google_fonts/google_fonts.dart';

// late List<CameraDescription> cameras;
// Future<void> main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   cameras = await availableCameras();
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Presensi SMPN1',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.poppinsTextTheme(
          Theme.of(context).textTheme,
        ),
      ),
      home: const LoginScreen(),
      routes: {
        '/home': (context) => const LoginScreen(),
      },
    );
  }
}

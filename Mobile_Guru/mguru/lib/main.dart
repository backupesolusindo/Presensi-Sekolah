import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'login_page.dart';
import 'subject_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Absensi App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        textTheme: GoogleFonts.robotoTextTheme(),
      ),
      initialRoute: '/login',
      routes: {
       '/login': (context) => LoginPage(),
        '/home': (context) => SubjectPage(),
      },
      onUnknownRoute: (settings) {
        return MaterialPageRoute(builder: (context) => LoginPage());
      },
    );
  }
}

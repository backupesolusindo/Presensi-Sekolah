import 'package:flutter/material.dart';
import 'home.dart'; // Import the home.dart file

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePage(), // Set HomePage from home.dart as the home screen
    );
  }
}

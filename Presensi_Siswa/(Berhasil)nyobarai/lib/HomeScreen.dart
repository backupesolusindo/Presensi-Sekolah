import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nyobarai/UserListScreen.dart'; // Pastikan path ini sesuai

import 'RecognitionScreen.dart';
import 'RegistrationScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  
  @override
  State<HomeScreen> createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 100),
              child: Image.asset(
                "images/logo.png",
                width: screenWidth - 40,
                height: screenWidth - 40,
              ),
            ),
            const SizedBox(height: 20), // Jarak antara logo dan tombol
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegistrationScreen()));
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: Size(screenWidth - 30, 50)),
              child: const Text("Register"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RecognitionScreen()));
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: Size(screenWidth - 30, 50)),
              child: const Text("Recognize"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => UserListScreen()));
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: Size(screenWidth - 30, 50)),
              child: const Text("User List"),
            ),
            const SizedBox(height: 50), // Jarak bawah untuk padding bottom
          ],
        ),
      ),
    );
  }
}

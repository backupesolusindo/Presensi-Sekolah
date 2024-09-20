import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:nyobarai/UserListScreen.dart';
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
      backgroundColor: Colors.blue[50], // Warna latar belakang
      body: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 50),
                child: Image.asset(
                  "images/logo.png",
                  width: screenWidth - 40,
                  height: screenWidth - 40,
                ),
              ),
              const SizedBox(height: 20), // Jarak antara logo dan tombol
              Text(
                "Sistem Absensi Wajah",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue[800], // Warna teks
                ),
              ),
              const SizedBox(height: 20),
              _buildButton("Daftar", () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RegistrationScreen()));
              }),
              const SizedBox(height: 20),
              _buildButton("Absen", () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const RecognitionScreen()));
              }),
              const SizedBox(height: 20),
              _buildButton("Murid Terdaftar", () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => UserListScreen()));
              }),
              const SizedBox(height: 50), // Jarak bawah untuk padding bottom
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String title, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[600], // Warna tombol
        minimumSize: const Size(200, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10), // Sudut tombol
        ),
        elevation: 5, // Bayangan tombol
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}

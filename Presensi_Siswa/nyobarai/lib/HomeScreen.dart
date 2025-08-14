import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:presensiSiswa/RFIDscreen.dart' as rfid_lower;
import 'RecognitionScreen.dart';
import 'UserListScreen.dart';
import 'RFIDScreen.dart'; // pastikan sudah ada file RFIDScreen.dart

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Konten Utama
          Center(
            child: _isLoading
                ? Lottie.asset('assets/loading.json', width: 150, height: 150)
                : SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo
                        Container(
                          margin: const EdgeInsets.only(top: 50),
                          child: Image.asset(
                            "assets/logoSMP.png",
                            width: screenWidth - 100,
                            height: screenWidth - 100,
                          ),
                        ),
                        const SizedBox(height: 20),
                        // Judul
                        Text(
                          "Presensi Wajah\nSMPN 1 Jember",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                        const SizedBox(height: 90),

                        // Tombol Presensi
                        _buildButton(
                          "Presensi",
                          "assets/camera_icon.png",
                          () {
                            _navigateWithLoading(
                                context, const RecognitionScreen());
                          },
                        ),
                        const SizedBox(height: 20),

                        // Tombol Murid Terdaftar
                        _buildButton(
                          "Murid Terdaftar",
                          "assets/list_icon.png",
                          () {
                            _navigateWithLoading(
                                context, const UserListScreen());
                          },
                        ),
                        const SizedBox(height: 20),

                        // Tombol Absensi RFID
                        _buildButton(
                          "Absensi RFID",
                          "assets/rfid_icon.png",
                          () {
                            _navigateWithLoading(
                                context, const RFIDScreen());
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // Widget tombol dengan ikon
  Widget _buildButton(String title, String iconPath, VoidCallback onPressed) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue[600],
        minimumSize: const Size(220, 55),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 5,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            iconPath,
            width: 30,
            height: 30,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateWithLoading(BuildContext context, Widget page) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() => _isLoading = false);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }
}

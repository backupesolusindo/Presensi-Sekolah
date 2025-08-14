import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:presensiSiswa/RFIDscreen.dart' as rfid_lower;
import 'RecognitionScreen.dart';
import 'UserListScreen.dart';
import 'RFIDScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = false;
  bool _isPressed = false; // Buat animasi tombol

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
          // Konten
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
                        const SizedBox(height: 70),

                        // Tombol Presensi
                        _buildSquareButton(
                          "Presensi",
                          Icons.camera_alt_rounded,
                          () => _navigateWithLoading(
                              context, const RecognitionScreen()),
                        ),
                        const SizedBox(height: 15),

                        // Tombol Murid Terdaftar
                        _buildSquareButton(
                          "Murid Terdaftar",
                          Icons.list_alt_rounded,
                          () => _navigateWithLoading(
                              context, const UserListScreen()),
                        ),
                        const SizedBox(height: 15),

                        // Tombol Absensi RFID
                        _buildSquareButton(
                          "Absensi RFID",
                          Icons.wifi_rounded,
                          () => _navigateWithLoading(
                              context, const RFIDScreen()),
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

  /// Tombol kotak biru gradasi elegan + animasi scale
  Widget _buildSquareButton(
      String title, IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedScale(
        scale: _isPressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: 220,
          height: 60,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [
                Color(0xFF256DDB), // biru tua
                Color(0xFF4A90E2), // biru muda
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
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

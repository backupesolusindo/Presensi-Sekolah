import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'RecognitionScreen.dart';
import 'RegistrationScreen.dart';
import 'UserListScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomePageState();
}

class _HomePageState extends State<HomeScreen> {
  bool _isLoading = false; // Untuk menandai proses loading

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Stack(
        children: [
          // Gambar latar belakang
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg.png'),
                fit: BoxFit.cover, // Sesuaikan gambar dengan layar
              ),
            ),
          ),
          Center(
            child: _isLoading
                ? Lottie.asset('assets/loading.json', width: 150, height: 150)
                : SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 50),
                          child: Image.asset(
                            "assets/logoSMP.png",
                            width: screenWidth - 100,
                            height: screenWidth - 100,
                          ),
                        ),
                        const SizedBox(height: 20), // Jarak antara logo dan tombol
                        Text(
                          "Presensi Wajah\nSMPN 1 Jember",
                          textAlign: TextAlign.center, // Membuat teks rata tengah
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800], // Warna teks
                          ),
                        ),
                        const SizedBox(height: 90),
                        _buildButton("Presensi", () {
                          _navigateWithLoading(context, const RecognitionScreen());
                        }),
                        const SizedBox(height: 20),
                        _buildButton("Murid Terdaftar", () {
                          _navigateWithLoading(context, UserListScreen());
                        }),
                        const SizedBox(
                            height: 20), // Jarak bawah untuk padding bottom
                      ],
                    ),
                  ),
          ),
        ],
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

  Future<void> _navigateWithLoading(BuildContext context, Widget page) async {
    setState(() {
      _isLoading = true; // Mulai loading
    });
    await Future.delayed(const Duration(seconds: 1)); // Simulasi loading
    setState(() {
      _isLoading = false; // Selesai loading
    });
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }
}

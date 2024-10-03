import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart'; // Make sure to add google_fonts to your pubspec.yaml

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController nomorTeleponController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController namaController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false; // New variable for password visibility

  Future<void> signup() async {
  final String nomorTelepon = nomorTeleponController.text.trim();
  final String password = passwordController.text.trim();
  final String nama = namaController.text.trim();

  String? validationMessage = _validateInputs(nomorTelepon, password, nama);
  if (validationMessage != null) {
    _showSnackbar(validationMessage, isError: true);
    return;
  }

  final url = Uri.parse('https://presensi-smp1.esolusindo.com/ApiWali/Wali/login');
  setState(() {
    _isLoading = true;
  });

  int maxRetries = 3;
  int retryCount = 0;
  bool success = false;

  while (retryCount < maxRetries && !success) {
    try {
      final response = await http.post(
        url,
        body: {
          'nomor_telepon': nomorTelepon,
          'password': password,
          'nama': nama,
        },
      ).timeout(Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          Navigator.pop(context);
          _showSnackbar('Registrasi berhasil! Silakan login.', isError: false);
          success = true;
        } else {
          _showSnackbar('Gagal mendaftar: ${data['message']}', isError: true);
          success = true; // Exit loop
        }
      } else {
        _showSnackbar('Gagal menghubungi server. Coba lagi nanti.', isError: true);
        success = true; // Exit loop
      }
    } catch (e) {
      retryCount++;
      if (retryCount < maxRetries) {
        await Future.delayed(Duration(seconds: 2));
      } else {
        if (e is TimeoutException) {
          _showSnackbar('Waktu habis saat menghubungi server. Coba lagi nanti.', isError: true);
        } else {
          _showSnackbar('Terjadi kesalahan: ${e.toString()}', isError: true);
        }
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}


  String? _validateInputs(String nomorTelepon, String password, String nama) {
    // Validate Nama
    if (nama.isEmpty || !RegExp(r'^[a-zA-Z\s]+$').hasMatch(nama)) {
      return 'Nama tidak valid (hanya huruf dan spasi)';
    }

    // Validate Nomor Telepon
    if (nomorTelepon.isEmpty || !RegExp(r'^\d{10,15}$').hasMatch(nomorTelepon)) {
      return 'Nomor telepon tidak valid (10-15 digit)';
    }

    // Validate Password
    if (password.isEmpty || password.length < 6) {
      return 'Password harus memiliki minimal 6 karakter';
    }
    if (!RegExp(r'^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{6,}$').hasMatch(password)) {
      return 'Password harus mengandung huruf besar, huruf kecil, angka, dan simbol';
    }

    return null; // No validation errors
  }

  void _showSnackbar(String message, {bool isError = true}) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle,
            color: Colors.white,
          ),
          SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.all(10),
      duration: Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[200]!, Colors.grey[400]!],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 60.0),
                    _buildLogo(),
                    SizedBox(height: 40.0),
                    _buildTitle(),
                    SizedBox(height: 20.0),
                    _buildTextField(
                      controller: namaController,
                      labelText: 'Nama',
                      icon: Icons.person,
                    ),
                    SizedBox(height: 20.0),
                    _buildTextField(
                      controller: nomorTeleponController,
                      labelText: 'Nomor Telepon',
                      icon: Icons.phone,
                    ),
                    SizedBox(height: 20.0),
                    _buildTextField(
                      controller: passwordController,
                      labelText: 'Password',
                      icon: Icons.lock,
                      isPassword: true,
                    ),
                    SizedBox(height: 30.0),
                    Column(
                      children: <Widget>[
                        _isLoading ? _buildLoadingIndicator() : _buildSignupButton(),
                        SizedBox(height: 20),
                        _buildBackToLoginButton(),
                      ],
                    ),
                    SizedBox(height: 20.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Image.asset(
      'assets/logo.png', // Ensure this path matches your assets
      height: 120,
    );
  }

  Widget _buildTitle() {
    return Text(
      'DAFTAR AKUN',
      style: GoogleFonts.poppins(
        textStyle: TextStyle(
          fontSize: 26.0,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible, // Toggle password visibility
      style: GoogleFonts.raleway(
        textStyle: TextStyle(color: Colors.black87),
      ),
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.black54),
        labelStyle: GoogleFonts.raleway(
          textStyle: TextStyle(color: Colors.black87),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.black38),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.black54,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible; // Toggle visibility
                  });
                },
              )
            : null,
      ),
    );
  }

  Widget _buildSignupButton() {
    return ElevatedButton(
      onPressed: signup,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0), backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      child: Text(
        'Daftar',
        style: GoogleFonts.poppins(
          textStyle: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildBackToLoginButton() {
    return TextButton(
      onPressed: () {
        Navigator.pop(context); // Go back to the login page
      },
      child: Text(
        'Sudah punya akun? Kembali ke Login',
        style: GoogleFonts.raleway(
          textStyle: TextStyle(color: Colors.blueGrey[700], fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(
        color: Colors.blueGrey,
      ),
    );
  }
}

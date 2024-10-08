import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:google_fonts/google_fonts.dart';

class SignupPage extends StatefulWidget {
  @override
  _SignupPageState createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController nomorTeleponController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController namaController = TextEditingController();
  final TextEditingController nisAnakController = TextEditingController(); // NIS Anak

  bool _isLoading = false;
  bool _isPasswordVisible = false;

Future<bool> isPhoneNumberUsed(String nomorTelepon) async {
  final url = Uri.parse('https://presensi-smp1.esolusindo.com/ApiWali/Wali/check_phone?nomor_telepon=$nomorTelepon');
  
  try {
    final response = await http.get(url);
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['status'] == 'error') {
        return true; // Nomor telepon sudah digunakan
      }
    }
  } catch (e) {
    // Handle error if needed
    print('Error checking phone number: $e');
  }
  
  return false; // Nomor telepon belum digunakan
}

Future<void> signup() async {
  final String nomorTelepon = nomorTeleponController.text.trim();
  final String password = passwordController.text.trim();
  final String namaWali = namaController.text.trim();
  final String nisAnak = nisAnakController.text.trim();

  if (namaWali.isEmpty || nisAnak.isEmpty) {
    _showSnackbar('Nama dan NIS Anak tidak boleh kosong', isError: true);
    return;
  }

  // Cek apakah nomor telepon sudah digunakan
  final isUsed = await isPhoneNumberUsed(nomorTelepon);
  if (isUsed) {
    _showSnackbar('Nomor telepon sudah digunakan', isError: true);
    return;
  }

  final url = Uri.parse('https://presensi-smp1.esolusindo.com/ApiWali/Wali/create');
  setState(() {
    _isLoading = true;
  });

  try {
    final response = await http.post(
      url,
      body: {
        'nama_wali': namaWali,
        'nomor_telepon': nomorTelepon,
        'nis_anak': nisAnak,
        'password': password,
      },
    ).timeout(Duration(seconds: 30));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        Navigator.pop(context);
        _showSnackbar('Registrasi berhasil! Silakan login.', isError: false);
      } else {
        _showSnackbar('Gagal mendaftar: ${data['message']}', isError: true);
      }
    } else {
      _showSnackbar('Gagal menghubungi server. Coba lagi nanti.', isError: true);
    }
  } catch (e) {
    _showSnackbar('Terjadi kesalahan: ${e.toString()}', isError: true);
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
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
                      labelText: 'Nama Wali',
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
                      controller: nisAnakController,
                      labelText: 'NIS Anak',
                      icon: Icons.school,
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
      'assets/logo.png',
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
      obscureText: isPassword && !_isPasswordVisible,
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
                    _isPasswordVisible = !_isPasswordVisible;
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
        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        backgroundColor: Colors.blueAccent,
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
        Navigator.pop(context);
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

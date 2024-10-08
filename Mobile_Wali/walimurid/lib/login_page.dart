import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:walimurid/Utilities/BaseUrl.dart';
import 'navbar_page.dart'; // Ganti dengan file dashboard kamu
import 'signup_page.dart'; // Ganti dengan file signup kamu

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController no_hpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.bounceOut);
    _controller.forward();
  }

  Future<void> login() async {
    final String no_hp = no_hpController.text;
    final String password = passwordController.text;

    if (no_hp.isEmpty || password.isEmpty) {
      _showErrorSnackbar('Nomor telepon dan password tidak boleh kosong');
      return;
    }

    final url = Uri.parse(UrlApi +'/WaliAPI/login');
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        url,
        body: {
          'no_hp': no_hp,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          List<dynamic> siswaData = data['siswa']; // Data siswa dari API

          // Navigasi ke NavbarPage sambil mengirimkan data siswa
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => NavbarPage(
                nama_wali: data['nama_wali'],
                no_hp: data['no_hp'],
                siswaData: siswaData, // Kirimkan data siswa ke NavbarPage
              ),
            ),
          );
        } else {
          _showErrorSnackbar('Nomor telepon atau password salah');
        }
      } else {
        _showErrorSnackbar('Gagal menghubungi server. Coba lagi nanti.');
      }
    } catch (e) {
      _showErrorSnackbar('Terjadi kesalahan. Cek koneksi internet Anda.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackbar(String message) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.white),
          SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.all(10),
      duration: Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  void dispose() {
    _controller.dispose();
    no_hpController.dispose();
    passwordController.dispose();
    super.dispose();
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
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    SizedBox(height: 60.0),
                    _buildLogo(),
                    SizedBox(height: 40.0),
                    _buildTitle(),
                    SizedBox(height: 20.0),
                    _buildTextField(
                      controller: no_hpController,
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
                    _isLoading ? _buildLoadingIndicator() : _buildLoginButton(),
                    SizedBox(height: 20),
                    _buildSignupButton(),
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
    return ScaleTransition(
      scale: _animation,
      child: Image.asset(
        'assets/logo.png',
        height: 120,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'ABSENSI SMPN 1 JEMBER',
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
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: login,
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        backgroundColor: Colors.blueAccent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      child: Text(
        'Login',
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

  Widget _buildSignupButton() {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SignupPage()), // Ganti dengan halaman signup
        );
      },
      child: Text(
        'Belum punya akun? Daftar di sini',
        style: GoogleFonts.raleway(
          textStyle: TextStyle(color: Colors.blueAccent),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: CircularProgressIndicator(),
    );
  }
}

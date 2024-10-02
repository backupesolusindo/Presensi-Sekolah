import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dashboard_page.dart'; // Import DashboardPage

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController nomorTeleponController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;

  // Animasi untuk logo
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
    final String nomorTelepon = nomorTeleponController.text;
    final String password = passwordController.text;

    if (nomorTelepon.isEmpty || password.isEmpty) {
      _showErrorSnackbar('Nomor telepon dan password tidak boleh kosong');
      return;
    }

    final url = Uri.parse('https://presensi-smp1.esolusindo.com/ApiWali/Wali/login');
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        url,
        body: {
          'nomor_telepon': nomorTelepon,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          // Arahkan ke DashboardPage dengan data yang didapat
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardPage(nama_wali: data['nama'], nis_anak: data['anak']),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient yang elegan dan soft
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.grey[200]!, Colors.grey[400]!], // Warna gradient yang soft
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
                    _isLoading ? _buildLoadingIndicator() : _buildLoginButton(),
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
        'assets/logo.png', // Sesuaikan path gambar Anda
        height: 120,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'ABSENSI SMPN 1 JEMBER',
      style: TextStyle(
        fontSize: 26.0,
        fontWeight: FontWeight.bold,
        color: Colors.black87, // Warna teks yang kontras dengan background soft
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
      obscureText: isPassword,
      style: TextStyle(color: Colors.black87),
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.black54),
        labelStyle: TextStyle(color: Colors.black87),
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
        padding: EdgeInsets.symmetric(vertical: 18.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        backgroundColor: Colors.blueGrey[600],
      ),
      child: Text(
        'Login',
        style: TextStyle(
          fontSize: 18.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
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

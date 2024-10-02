import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dashboard_page.dart'; // Import SubjectPage

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController nomor_teleponController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String _message = '';
  bool _isLoading = false;

  Future<void> login() async {
    final String nomor_telepon = nomor_teleponController.text;
    final String password = passwordController.text;

    if (nomor_telepon.isEmpty || password.isEmpty) {
      setState(() {
        _message = 'nomor_telepon dan password tidak boleh kosong';
      });
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
          'nomor_telepon': nomor_telepon,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          setState(() {
            _message = 'Login berhasil, nama: ${data['nama']}';

            // Arahkan ke SubjectPage dengan nomor_telepon yang didapat
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => DashboardPage(nama_wali: data['nama'], nis_anak: data['anak']),
              ),
            );
          });
        } else {
          setState(() {
            _message = 'nomor_telepon atau password salah';
          });
        }
      } else {
        setState(() {
          _message = 'Gagal menghubungi server. Coba lagi nanti.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Terjadi kesalahan. Cek koneksi internet Anda.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(height: 80.0),
                Image.asset(
                  'assets/logo.png', // Sesuaikan path gambar Anda
                  height: 150,
                ),
                SizedBox(height: 40.0),
                Text(
                  'ABSENSI SMPN 1 JEMBER',
                  style: TextStyle(
                    fontSize: 22.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20.0),
                TextField(
                  controller: nomor_teleponController,
                  keyboardType: TextInputType.text,
                  decoration: InputDecoration(
                    labelText: 'Nomor Telepon',
                    prefixIcon: Icon(Icons.email, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                SizedBox(height: 20.0),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock, color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                ),
                SizedBox(height: 10.0),
                SizedBox(height: 20.0),
                _isLoading
                    ? Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: login,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          backgroundColor: Colors.blue,
                        ),
                        child: Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 18.0,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                SizedBox(height: 20.0),
                Center(
                  child: Text(
                    _message,
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

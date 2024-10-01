import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController nipController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String _message = '';

Future<void> login() async {
  final String nip = nipController.text;
  final String password = passwordController.text;

  final url = Uri.parse('https://presensi-smp1.esolusindo.com/ApiGuru/Guru/login');
  try {
    final response = await http.post(
      url,
      body: {
        'nip': nip,
        'password': password,
      },
    );
    
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');
    
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      if (data['status'] == 'success') {
        setState(() {
          _message = 'Login berhasil, nama: ${data['nama']}';
        });
      } else {
        setState(() {
          _message = 'NIP tidak ditemukan';
        });
      }
    } else {
      setState(() {
        _message = 'Gagal menghubungi server';
      });
    }
  } catch (e) {
    print('Error: $e');
    setState(() {
      _message = 'Terjadi kesalahan. Cek koneksi internet Anda.';
    });
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            TextField(
              controller: nipController,
              decoration: InputDecoration(labelText: 'NIP'),
            ),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              child: Text('Login'),
            ),
            SizedBox(height: 20),
            Text(_message),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController nipController = TextEditingController();
  TextEditingController passwordController = TextEditingController();

  Future<void> login() async {
    if (nipController.text == 'admin' && passwordController.text == 'admin') {
      try {
        final response = await http.post(
          Uri.parse('https://presensi-smp1.esolusindo.com/ApiGuru/Guru/SyncGuru'),
          body: jsonEncode({
            'nip': nipController.text,
            'password': passwordController.text,
          }),
          headers: {'Content-Type': 'application/json'},
        );

        // Log the response
        print('Response status: ${response.statusCode}');
        print('Response body: ${response.body}');

        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          String userName = data['name'];
          List<String> subjects = List<String>.from(data['subjects']);

          Navigator.pushReplacementNamed(
            context,
            '/home',
            arguments: {'name': userName, 'subjects': subjects},
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'])),
          );
        }
      } catch (e) {
        // Log the exception
        print('Exception occurred: $e');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terjadi kesalahan saat login')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('NIP atau password salah')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: nipController,
              decoration: InputDecoration(labelText: 'NIP'),
              keyboardType: TextInputType.text,
            ),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: InputDecoration(labelText: 'Password'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: login,
              child: Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'subject_page.dart'; // Import the subject page

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController nipController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false; // To show loading indicator

  Future<void> login() async {
    // Validasi input
    if (nipController.text.isEmpty || passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Harap isi NIP dan password')),
      );
      return;
    }

    setState(() {
      _isLoading = true; // Show loading when login starts
    });

    try {
      final response = await http.post(
        Uri.parse('https://presensi-smp1.esolusindo.com/ApiGuru/Guru/login'),
        body: jsonEncode({
          'nip': nipController.text,
          'password': passwordController.text,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      // Logging response for debugging
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          // Navigate to SubjectPage if login is successful
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SubjectPage(nip: nipController.text), // Pass the NIP
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'Login gagal')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login gagal: ${response.reasonPhrase}')),
        );
      }
    } catch (e) {
      print('Exception occurred: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan saat login')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Hide loading when login is complete
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Login")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
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
            _isLoading
                ? CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: login,
                    child: Text('Login'),
                  ),
          ],
        ),
      ),
    );
  }
}

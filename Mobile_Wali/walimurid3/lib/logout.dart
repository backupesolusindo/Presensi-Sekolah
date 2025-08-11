import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';

Future<void> logout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  
  // Menghapus semua data dari SharedPreferences
  await prefs.clear();

  // Navigasi ke halaman login
  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
}

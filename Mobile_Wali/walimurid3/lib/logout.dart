import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';

Future<void> logout(BuildContext context) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('nama_wali');
  await prefs.remove('no_hp');

  // Navigasi ke halaman login
  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => LoginPage()));
}

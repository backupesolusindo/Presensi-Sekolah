import 'package:flutter/material.dart';
import 'database_helper.dart'; // Pastikan path ini benar
import 'package:http/http.dart' as http;
import 'dart:convert';

class RiwayatPage extends StatefulWidget {
  @override
  _RiwayatPageState createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  List<dynamic> _absensiList = [];
  bool _isLoading = true;
  String? _nis; // Variabel untuk menyimpan NIS dari SQLite

  final DatabaseHelper _dbHelper = DatabaseHelper(); // Inisialisasi DatabaseHelper

  @override
  void initState() {
    super.initState();
    _getNisFromDatabase(); // Ambil NIS dari SQLite saat halaman dibuka
  }

  Future<void> _getNisFromDatabase() async {
    // Lakukan query untuk mengambil NIS dari SQLite
    List<Map<String, dynamic>> students = await _dbHelper.getStudents();
    if (students.isNotEmpty) {
      setState(() {
        _nis = students[0]['nis']; // Ambil NIS dari record pertama
      });
      _fetchData(); // Lakukan fetch data absensi setelah NIS diperoleh
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data NIS tidak ditemukan')),
      );
    }
  }

  Future<void> _fetchData() async {
    if (_nis == null) return; // Pastikan NIS tidak null sebelum melakukan request
    String url = 'https://presensi-smp1.esolusindo.com/ApiGerbang/Gerbang/ambilAbsen';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {'nis': _nis}, // Gunakan NIS dari SQLite sebagai parameter
      );

      if (response.statusCode == 200) {
        setState(() {
          _absensiList = json.decode(response.body)['data']; // Parsing respons JSON
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print(e);
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data absensi')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Absensi'),
        backgroundColor: Colors.blue,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _absensiList.isEmpty
              ? Center(child: Text('Tidak ada data absensi'))
              : ListView.builder(
                  itemCount: _absensiList.length,
                  itemBuilder: (context, index) {
                    final absensi = _absensiList[index];
                    return ListTile(
                      title: Text('Tanggal: ${absensi['tanggal'] ?? 'N/A'}'),
                      subtitle: Text('Status: ${absensi['status'] ?? 'N/A'}'),
                    );
                  },
                ),
    );
  }
}

import 'package:flutter/material.dart';
import 'database_helper.dart'; // Ganti sesuai path DatabaseHelper

class DashboardContent extends StatefulWidget {
  @override
  _DashboardContentState createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _nisController = TextEditingController();
  final TextEditingController _kelasController = TextEditingController();

  final DatabaseHelper _dbHelper = DatabaseHelper();

  void _saveData() async {
    String nama = _namaController.text;
    String nis = _nisController.text;
    String kelas = _kelasController.text;

    if (nama.isNotEmpty && nis.isNotEmpty && kelas.isNotEmpty) {
      await _dbHelper.insertStudent({
        'nama': nama,
        'nis': nis,
        'kelas': kelas,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data siswa berhasil disimpan')),
      );
      _namaController.clear();
      _nisController.clear();
      _kelasController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Harap lengkapi semua field')),
      );
    }
  }

  void _clearFields() {
    _namaController.clear();
    _nisController.clear();
    _kelasController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat Datang di Dashboard!',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            TextField(
              controller: _namaController,
              decoration: InputDecoration(labelText: 'Nama Siswa'),
            ),
            TextField(
              controller: _nisController,
              decoration: InputDecoration(labelText: 'NIS'),
            ),
            TextField(
              controller: _kelasController,
              decoration: InputDecoration(labelText: 'Kelas'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveData,
              child: Text('Simpan Data'),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _clearFields, // Menambahkan event untuk mengosongkan field
        child: Icon(Icons.add),
        backgroundColor: Colors.blue,
        tooltip: 'Tambah Siswa Baru',
      ),
    );
  }
}

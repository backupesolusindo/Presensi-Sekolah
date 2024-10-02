import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  final String nama_wali;
  final String nis_anak; // Sekarang menggunakan String

  DashboardPage({required this.nama_wali, required this.nis_anak});

  @override
  Widget build(BuildContext context) {
    // Memeriksa apakah terdapat lebih dari satu NIS berdasarkan adanya koma
    bool isMultipleAnak = nis_anak.contains(',');

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
              'Selamat Datang, $nama_wali!',
              style: TextStyle(
                fontSize: 24.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.0),
            Text(
              isMultipleAnak 
                ? 'NIS Anak-anak: $nis_anak'
                : 'NIS Anak: $nis_anak',
              style: TextStyle(
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                // Tambahkan aksi ketika tombol ditekan
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: Text('Fitur Lainnya'),
            ),
          ],
        ),
      ),
    );
  }
}

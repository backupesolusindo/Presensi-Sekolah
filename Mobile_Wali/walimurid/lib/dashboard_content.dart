import 'package:flutter/material.dart';

class DashboardContent extends StatelessWidget {
  final String namaWali; // Parameter yang diperlukan
  final List<dynamic> siswaData; // Data siswa yang diterima

  DashboardContent({required this.namaWali, required this.siswaData}); // Konstruktor

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Selamat datang, $namaWali!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          Text('No HP: ', style: TextStyle(fontSize: 16)), // No HP tidak disertakan di sini
          SizedBox(height: 20),
          Text('Data Siswa:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          for (var siswa in siswaData) ...[
            Text('Nama: ${siswa['nama_siswa']}'),
            Text('NIS: ${siswa['nis']}'),
            Text('Kelas: ${siswa['kelas']}'),
            SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

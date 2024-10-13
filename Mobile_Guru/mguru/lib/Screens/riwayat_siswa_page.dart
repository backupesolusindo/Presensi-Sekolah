import 'package:flutter/material.dart';

class RiwayatSiswaPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/WaliRename.png'), // Pastikan path sesuai
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Tambahkan Container hitam dengan opacity untuk efek pudar
        Container(
          color: Colors.black.withOpacity(0.1), // 10% transparan
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              // Judul Halaman
              Text(
                'Riwayat Presensi Siswa',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              SizedBox(height: 20),

              // Bagian Daftar Riwayat Presensi
              Expanded(
                child: ListView.builder(
                  itemCount: 10, // Jumlah riwayat yang ingin ditampilkan
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Siswa ${index + 1}',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Kelas: 10A',
                                  style: TextStyle(fontSize: 14, color: Colors.black),
                                ),
                                Text(
                                  'Tanggal: ${DateTime.now().subtract(Duration(days: index)).toLocal().toString().split(' ')[0]}', // Contoh tanggal
                                  style: TextStyle(fontSize: 14, color: Colors.black),
                                ),
                              ],
                            ),
                            Text(
                              index % 2 == 0 ? 'Tepat Waktu' : 'Terlambat', // Contoh status
                              style: TextStyle(
                                fontSize: 14,
                                color: index % 2 == 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

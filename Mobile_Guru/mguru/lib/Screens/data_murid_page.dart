import 'package:flutter/material.dart';

class DataMuridPage extends StatelessWidget {
  final List<Map<String, String>> siswaList = [
    {"nama": "Siswa 1", "nis": "001"},
    {"nama": "Siswa 2", "nis": "002"},
    {"nama": "Siswa 3", "nis": "003"},
    {"nama": "Siswa 4", "nis": "004"},
    {"nama": "Siswa 5", "nis": "005"},
    {"nama": "Siswa 6", "nis": "006"},
    {"nama": "Siswa 7", "nis": "007"},
    {"nama": "Siswa 8", "nis": "008"},
    // Tambahkan lebih banyak data siswa sesuai kebutuhan
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/WaliRename.png'), // Pastikan path sesuai
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Tambahkan efek transparan
          Container(
            color: Colors.black.withOpacity(0.2), // 20% transparan
          ),
          ListView.builder(
            itemCount: siswaList.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                elevation: 4, // Memberikan bayangan pada kartu
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10), // Membuat sudut kartu membulat
                ),
                child: ListTile(
                  title: Text(
                    siswaList[index]["nama"]!,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue, // Warna teks item
                    ),
                  ),
                  subtitle: Text(
                    'NIS: ${siswaList[index]["nis"]!}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.green, // Warna teks NIS
                    ),
                  ),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blue[100],
                    child: Icon(Icons.person, color: Colors.blue),
                  ),
                  trailing: Icon(Icons.arrow_forward_ios, color: Colors.blue), // Ubah warna ikon
                  onTap: () {
                    // Aksi ketika siswa diklik, misalnya navigasi ke detail siswa
                    // Navigator.push(context, MaterialPageRoute(builder: (context) => DetailSiswaPage()));
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

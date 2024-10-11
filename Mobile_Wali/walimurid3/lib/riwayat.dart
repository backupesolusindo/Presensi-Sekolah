import 'package:flutter/material.dart';
import 'home.dart';      // Import home page
import 'profile.dart';  // Import profile page
import 'bottombar.dart'; // Import bottom bar

class RiwayatPage extends StatefulWidget {
  @override
  _RiwayatPageState createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  int _currentIndex = 1; // Set index 1 untuk halaman Riwayat

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()), // Pindah ke halaman Home
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage()), // Pindah ke halaman Profile
      );
    }
    // Untuk index 1, tetap di halaman Riwayat
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue, // Warna atas disesuaikan
        title: Text('Riwayat'),
        leading: IconButton(
          icon: Icon(Icons.menu),
          onPressed: () {
            // Aksi untuk membuka drawer atau menu
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.info_outline),
            onPressed: () {
              // Aksi untuk membuka info
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Banner untuk mata pelajaran dan kelas
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12.0),
                  image: DecorationImage(
                    image: AssetImage('assets/banner.png'), // Sesuaikan path gambar
                    fit: BoxFit.cover,
                  ),
                ),
                height: 150,
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Bahasa Indonesia',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tahun Ajaran 2023-2024 - 9A',
                        style: TextStyle(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16.0),

              // Tombol Riwayat
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Aksi tombol Riwayat
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                  ),
                  child: Text('Riwayat'),
                ),
              ),
              SizedBox(height: 16.0),

              // Tanggal dan opsi pencarian
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Senin, 29 Maret 2024',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Aksi pencarian
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    icon: Icon(Icons.search),
                    label: Text('Cari'),
                  ),
                ],
              ),
              SizedBox(height: 16.0),

              // Kategori filter
              Wrap(
                spacing: 8.0,
                children: [
                  _buildFilterButton('Semua', true),
                  _buildFilterButton('Hadir', false),
                  _buildFilterButton('Tidak Hadir', false),
                  _buildFilterButton('Terlambat', false),
                  _buildFilterButton('Izin', false),
                  _buildFilterButton('Sakit', false),
                ],
              ),
              SizedBox(height: 16.0),

              // Daftar murid dan riwayat absen
              _buildAttendanceCard(
                  'Senin, 29 Maret 2024', 'Ihsan Haadi Nugroho', 1, 'Hadir', '-'),
              _buildAttendanceCard('Senin, 29 Maret 2024', 'Aliefian Cahya Nugroho', 2,
                  'Sakit', 'Pusing dan Batuk'),
              _buildAttendanceCard(
                  'Senin, 29 Maret 2024', 'Ihsan Haadi Nugroho', 3, 'Izin', 'Acara Keluarga'),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
        onTap: _onItemTapped, // Fungsi navigasi
      ),
    );
  }

  // Widget untuk tombol filter
  Widget _buildFilterButton(String label, bool isSelected) {
    return ElevatedButton(
      onPressed: () {
        // Aksi filter
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? Colors.blue : Colors.grey[300],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black,
        ),
      ),
    );
  }

  // Widget untuk card absensi
  Widget _buildAttendanceCard(
      String date, String name, int noAbsen, String status, String reason) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              date,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.0),
            Text('Nama Murid : $name'),
            Text('No Absen : $noAbsen'),
            Text('Keterangan : $status'),
            Text('Alasan : $reason'),
          ],
        ),
      ),
    );
  }
}

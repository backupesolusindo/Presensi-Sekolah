import 'package:flutter/material.dart';
import 'package:walimurid3/recognition/RegistrationScreen.dart';
import 'bottombar.dart'; // Import bottom bar kustom
import 'riwayat.dart';   // Import halaman Riwayat

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RiwayatPage()), // Navigasi ke RiwayatPage
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bagian Info Profil di dalam kartu
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15.0),
                ),
                elevation: 5,
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        backgroundImage: AssetImage(
                            'assets/logopoltek.png'), // Ganti dengan logo Anda
                      ),
                      SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Good Day!',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'Rahma Dian Milinia Desi, S.Tr.P.',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'A19991209202407201',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Bagian Tanggal dan Lokasi
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildInfoCard(
                      '15:15:38\nTue, 08 October 2024',
                      Icons.access_time,
                      Colors.white // Ubah warna latar belakang menjadi putih
                      ),
                  _buildInfoCard(
                      'Kampus POLIJE\nLokasi Anda',
                      Icons.location_on,
                      Colors.white // Ubah warna latar belakang menjadi putih
                      ),
                ],
              ),
              SizedBox(height: 16),

              // Bagian Menu Presensi
              Text(
                'Menu Presensi:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              // Card dengan scroll horizontal untuk Menu Presensi
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildMenuIcon(Icons.menu, 'Semua Menu'),
                        SizedBox(width: 20),
                        _buildMenuIcon(Icons.login, 'Presensi Masuk'),
                        SizedBox(width: 20),
                        _buildMenuIcon(Icons.coffee, 'Istirahat Keluar'),
                        SizedBox(width: 20),
                        _buildMenuIcon(Icons.logout, 'Presensi Pulang'),
                        SizedBox(width: 20),
                        _buildMenuIcon(Icons.history, 'Istirahat Masuk'),
                        SizedBox(width: 20),
                        _buildMenuIcon(Icons.face, 'Daftarkan Wajah Anak'),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Presensi Anda Section
              Text(
                'Presensi Anda:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _buildPresenceStatusCard(
                  'Anda Hari ini Belum Melakukan Presensi'), // Presensi Anda

              SizedBox(height: 16),

              // Bagian Kegiatan Anda
              Text(
                'Jadwal Mapel Hari Ini:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              _buildPresenceStatusCard(
                  'Tidak ada jadwal mapel untuk hari ini.'), // Kegiatan Anda
            ],
          ),
        ),
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  // Widget untuk info card dengan icon
  Widget _buildInfoCard(String text, IconData icon, Color cardColor) {
    return Card(
      elevation: 5, // Tambahkan elevasi untuk memberikan efek bayangan
      color: cardColor, // Mengatur warna latar belakang
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 30, color: Colors.blueAccent),
            SizedBox(height: 8),
            Text(
              text,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk ikon menu dengan teks di dalam Card
  Widget _buildMenuIcon(IconData icon, String label, {Function()? onTap}) {
    return GestureDetector(
      onTap: onTap, // Tambahkan fungsi onTap di sini
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blueAccent,
            child: Icon(icon, color: Colors.white),
          ),
          SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }

  // Widget untuk status presensi (Presensi Anda dan Kegiatan Anda)
  Widget _buildPresenceStatusCard(String text) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20), // Membuat sudut melengkung
      ),
      elevation: 5, // Menambahkan bayangan
      color: Colors.lightBlue, // Warna latar belakang sesuai dengan gambar
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Text(
              text,
              style: TextStyle(
                color: Colors.white, // Warna teks putih
                fontSize: 16, // Ukuran teks yang cukup besar
                fontWeight: FontWeight.bold, // Teks dibuat tebal
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'bottombar.dart'; // Import bottom bar kustom

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
                        backgroundImage: AssetImage('assets/logopoltek.png'), // Ganti dengan logo Anda
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
              // Horizontal Scroll for Menu Presensi
              SingleChildScrollView(
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
                  ],
                ),
              ),
              SizedBox(height: 16),

              // Presensi Anda Section
              Text(
                'Presensi Anda:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Menambahkan shadow pada kartu jam presensi datang
                  _buildPresenceInfo('Jam Presensi Datang', '10:22:49\n08/10/2024', Colors.blue, 200),
                  SizedBox(width: 16), // Tambahkan jarak di antara kedua kartu
                  // Menambahkan shadow pada kartu jam presensi pulang
                  _buildPresenceInfo('Jam Presensi Pulang', 'Belum Presensi \nPulang', Colors.teal, 200),
                ],
              ),
              SizedBox(height: 16),

              // Bagian Kegiatan Anda
              Text(
                'Kegiatan Anda:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Card(
                color: Colors.orange,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    'Anda Hari Ini Tidak Ada Kegiatan',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
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

  Widget _buildMenuIcon(IconData icon, String label) {
    return Container(
      width: 80, // Set width for scrollable menu items
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

  // Modifikasi untuk menambahkan parameter lebar
  Widget _buildPresenceInfo(String title, String time, Color color, double width) {
    return Card(
      elevation: 5, // Tambahkan elevasi untuk shadow
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Container(
        width: width, // Menentukan lebar kartu
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
            SizedBox(height: 8),
            Text(
              time,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

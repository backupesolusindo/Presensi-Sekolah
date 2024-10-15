import 'dart:async';  // Untuk Timer
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';  // Untuk format tanggal dan waktu
import 'package:shared_preferences/shared_preferences.dart';
import 'recognition/RegistrationScreen.dart';
import 'bottombar.dart'; // Import bottom bar kustom
import 'riwayat.dart';   // Import halaman Riwayat

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String namaWali = '';
  String noHp = '';
  int _currentIndex = 0;

  String _currentTime = '';
  String _currentDate = '';
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _initializeLocale();  // Inisialisasi locale untuk format waktu dan tanggal
    _loadUserData();       // Load nama wali dan nomor HP
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('id_ID', null);  // Inisialisasi locale untuk Indonesia
    _updateTime();  // Panggil pertama kali untuk menampilkan waktu awal

    // Timer untuk memperbarui waktu setiap detik
    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      _updateTime();
    });
  }

  @override
  void dispose() {
    _timer.cancel();  // Hentikan timer saat widget dihancurkan
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      namaWali = prefs.getString('nama_wali') ?? 'Nama Wali';
      noHp = prefs.getString('no_hp') ?? 'Nomor HP';
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(now);  // Format waktu
      _currentDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);  // Format tanggal
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RiwayatPage()), // Navigasi ke halaman Riwayat
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Gambar background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/walibg.png'),
                fit: BoxFit.cover, // Sesuaikan gambar dengan layar
              ),
            ),
          ),
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Kartu Profil
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    elevation: 5,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: AssetImage('assets/logopoltek.png'),
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
                                namaWali,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              Text(
                                noHp,
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
                      _buildInfoCard('$_currentTime\n$_currentDate', Icons.access_time, Colors.white),
                      _buildInfoCard('Kampus POLIJE\nLokasi Anda', Icons.location_on, Colors.white),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Menu Presensi
                  Text(
                    'Menu Presensi:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
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
                            _buildMenuIcon(Icons.menu, 'Semua Menu', () {}),
                            SizedBox(width: 20),
                            _buildMenuIcon(Icons.login, 'Presensi Masuk', () {}),
                            SizedBox(width: 20),
                            _buildMenuIcon(Icons.coffee, 'Istirahat Keluar', () {}),
                            SizedBox(width: 20),
                            _buildMenuIcon(Icons.logout, 'Presensi Pulang', () {}),
                            SizedBox(width: 20),
                            _buildMenuIcon(Icons.history, 'Istirahat Masuk', () {}),
                            SizedBox(width: 20),
                            _buildMenuIcon(Icons.face, 'Daftarkan Wajah Anak', () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => RegistrationScreen()),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),

                  // Presensi Anda
                  Text(
                    'Presensi Anda:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  _buildPresenceStatusCard('Anda Hari ini Belum Melakukan Presensi'),

                  SizedBox(height: 16),

                  // Jadwal Mapel Hari Ini
                  Text(
                    'Jadwal Mapel Hari Ini:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  _buildPresenceStatusCard('Tidak ada jadwal mapel untuk hari ini.'),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }

  Widget _buildInfoCard(String text, IconData icon, Color cardColor) {
    return Card(
      elevation: 5,
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Icon(icon, size: 30, color: Colors.blueAccent),
            SizedBox(height: 8),
            Text(text, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuIcon(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
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

  Widget _buildPresenceStatusCard(String text) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 5,
      color: Colors.lightBlue,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Text(
              text,
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

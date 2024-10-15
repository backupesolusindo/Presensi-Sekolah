import 'dart:async';
import 'dart:convert'; // Untuk JSON decoding
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Import http
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'recognition/RegistrationScreen.dart';
import 'bottombar.dart';
import 'riwayat.dart';

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

  List<dynamic> siswaList = []; // Menampung data siswa
  String? selectedSiswa; // Menampung siswa yang dipilih

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    _loadUserData();
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('id_ID', null);
    _updateTime();
    _timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      _updateTime();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      namaWali = prefs.getString('nama_wali') ?? 'Nama Wali';
      noHp = prefs.getString('no_hp') ?? 'Nomor HP';

      // Ambil NIS dari SharedPreferences
      String nis = prefs.getString('nis') ?? 'NIS tidak tersedia';
      print('NIS: $nis'); // Anda bisa mencetak NIS untuk memastikan
    });

    await _fetchSiswaData(); // Panggil API setelah data pengguna di-load
  }

  Future<void> _fetchSiswaData() async {
    final url = Uri.parse(
        'https://presensi-smp1.esolusindo.com/Api/ApiSiswa/Siswa/getSiswabyHp/$noHp');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        // Log respons API untuk debugging
        print('Respons API: ${response.body}');
        final data = json.decode(response.body);

        // Periksa apakah data kosong
        if (data['data'].isNotEmpty) {
          setState(() {
            siswaList = data['data']; // Simpan data siswa ke siswaList
            selectedSiswa =
                siswaList.first['nama']; // Pilih siswa pertama sebagai default

            // Simpan NIS ke SharedPreferences
            String nis =
                siswaList.first['nis']; // Pastikan key benar sesuai JSON
            final prefs = SharedPreferences.getInstance();
            prefs.then((prefs) {
              prefs.setString('nis', nis); // Simpan NIS
            });
          });
        } else {
          print('Data siswa kosong atau tidak ditemukan.');
        }
      } else {
        print('Gagal mengambil data siswa: ${response.statusCode}');
      }
    } catch (e) {
      print('Terjadi kesalahan: $e');
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm:ss').format(now);
      _currentDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => RiwayatPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/walibg.png'),
                fit: BoxFit.cover,
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
                  _buildProfileCard(),
                  SizedBox(height: 16),

                  // Dropdown Siswa
                  _buildDropdownSiswa(),
                  SizedBox(height: 16),

                  // Tanggal dan Lokasi
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard('$_currentTime\n$_currentDate',
                            Icons.access_time, Colors.white),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: _buildInfoCard('Kampus POLIJE\nLokasi Anda',
                            Icons.location_on, Colors.white),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Menu Presensi
                  Text(
                    'Menu :',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  _buildMenuPresensi(),

                  SizedBox(height: 16),

                  // Presensi Anda
                  Text(
                    'Presensi Anda:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  _buildPresenceStatusCard(
                      'Anda Hari ini Belum Melakukan Presensi'),

                  SizedBox(height: 16),
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

  Widget _buildProfileCard() {
    return Column(
      children: [
        SizedBox(height: 40), // Menambahkan jarak vertikal sebelum card
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
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selamat Datang :',
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
                        'No HP : $noHp',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownSiswa() {
    return Row(
      children: [
        Icon(Icons.location_city, color: Colors.blueAccent),
        SizedBox(width: 8),
        Expanded(
          child: siswaList.isEmpty
              ? Text('Tidak ada siswa tersedia')
              : DropdownButton<String>(
                  value: selectedSiswa,
                  hint: Text('Pilih Siswa'),
                  isExpanded: true,
                  items: siswaList.map((siswa) {
                    return DropdownMenuItem<String>(
                      value: siswa['nama'], // Pastikan key benar sesuai JSON
                      child: Text(siswa['nama']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedSiswa = value; // Mengubah nilai yang dipilih
                    });
                  },
                ),
        ),
      ],
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

  Widget _buildMenuPresensi() {
    return Stack(
      children: [
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
                  _buildMenuIcon(Icons.document_scanner, 'Daftarkan Wajah Anak',
                      () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => RegistrationScreen()),
                    );
                  }),
                  SizedBox(width: 20),
                  _buildMenuIcon(Icons.lock_open, 'Edit Password', () {}),
                  SizedBox(width: 20),
                  _buildMenuIcon(Icons.face, 'Presensi Masuk', () {}),
                  SizedBox(width: 20),
                  _buildMenuIcon(Icons.face, 'Istirahat Keluar', () {}),
                  SizedBox(width: 20),
                  _buildMenuIcon(Icons.face, 'Presensi Pulang', () {}),
                  SizedBox(width: 20),
                ],
              ),
            ),
          ),
        ),
        // Ikon < di sisi kiri
        Positioned(
          left: 7,
          top: 50, // Sesuaikan posisi vertikal
          child: Icon(Icons.arrow_back_ios, color: Colors.grey),
        ),
        // Ikon > di sisi kanan
        Positioned(
          right: 0,
          top: 50, // Sesuaikan posisi vertikal
          child: Icon(Icons.arrow_forward_ios, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildMenuIcon(IconData icon, String label, Function onTap) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blueAccent,
            child: Icon(icon, color: Colors.white),
          ),
          SizedBox(height: 8),
          Container(
            width: 80, // Atur lebar agar teks tidak terlalu panjang
            child: Text(
              label,
              textAlign: TextAlign.center, // Agar teks berada di tengah
              style: TextStyle(
                fontSize: 14, // Atur ukuran teks
                fontWeight: FontWeight.bold, // Agar teks lebih menonjol
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresenceStatusCard(String status) {
    return Card(
      elevation: 5,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Text(status, style: TextStyle(fontSize: 16)),
        ),
      ),
    );
  }
}

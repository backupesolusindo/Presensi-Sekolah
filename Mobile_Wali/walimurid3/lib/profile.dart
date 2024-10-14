import 'package:flutter/material.dart';
import 'home.dart';
import 'riwayat.dart';
import 'bottombar.dart'; // Import bottom bar
import 'login.dart'; // Import halaman login
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences
import 'dart:convert'; // Untuk decoding JSON
import 'package:http/http.dart' as http; // Untuk request HTTP

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentIndex = 2; // Set index 2 untuk halaman profil
  String namaPegawai = "Loading..."; // Default teks sementara

  @override
  void initState() {
    super.initState();
    _fetchNamaPegawai(); // Panggil API saat halaman dimuat
  }

  Future<void> _fetchNamaPegawai() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNamaWali = prefs.getString('nama_wali');

      if (savedNamaWali != null) {
        // Jika nama_wali sudah ada di SharedPreferences, gunakan itu
        setState(() {
          namaPegawai = savedNamaWali;
        });
      } else {
        // Lakukan request API jika tidak ada data di SharedPreferences
        final response = await http.get(
          Uri.parse('https://api.example.com/nama_wali'), // Ganti dengan URL API Anda
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final fetchedNamaWali = data['nama_wali'];

          // Simpan nama_wali ke SharedPreferences
          await prefs.setString('nama_wali', fetchedNamaWali);

          // Update state dengan nama wali yang diambil dari API
          setState(() {
            namaPegawai = fetchedNamaWali;
          });
        } else {
          setState(() {
            namaPegawai = "Gagal memuat data.";
          });
        }
      }
    } catch (e) {
      setState(() {
        namaPegawai = "Error: ${e.toString()}";
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
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
          ClipPath(
            clipper: CustomDiagonalClipper(),
            child: Container(
              height: 300,
              color: Colors.lightBlue,
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 100),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/logopoltek.png'),
                ),
                SizedBox(height: 16),
                Text(
                  namaPegawai, // Tampilkan nama pegawai yang diambil dari API
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text('TEST'),
                SizedBox(height: 32),
                _buildInfoCard(Icons.email, 'Email', 'user@example.com'),
                _buildInfoCard(Icons.domain, 'Unit', 'Politeknik Jember'),
                _buildInfoCard(Icons.check_circle, '0 Presensi', 'Jumlah Presensi Bulan Ini'),
                _buildInfoCard(Icons.event, '0 Kegiatan', 'Jumlah Kegiatan Bulan Ini'),
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => _showLogoutConfirmation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                  ),
                  child: Text('Logout'),
                ),
              ],
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

  Widget _buildInfoCard(IconData icon, String title, String subtitle) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi Logout'),
          content: Text('Apakah Anda yakin ingin logout?'),
          actions: <Widget>[
            TextButton(
              child: Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Logout'),
              onPressed: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.clear(); // Hapus semua data SharedPreferences
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class CustomDiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(size.width, 0.0);
    path.lineTo(0.0, size.height);
    path.lineTo(0.0, 0.0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

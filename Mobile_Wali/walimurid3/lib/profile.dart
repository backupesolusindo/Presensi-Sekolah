import 'package:flutter/material.dart';
import 'home.dart';
import 'riwayat.dart';
import 'bottombar.dart'; // Import bottom bar
import 'login.dart'; // Import halaman login
import 'package:shared_preferences/shared_preferences.dart'; // Import shared_preferences

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentIndex = 2; // Set index 2 untuk halaman profil

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
        MaterialPageRoute(builder: (context) => RiwayatPage()), // Pindah ke halaman Riwayat
      );
    }
    // Untuk index 1, tetap di halaman Riwayat
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Efek slice dari atas kanan ke bawah kiri
          ClipPath(
            clipper: CustomDiagonalClipper(),
            child: Container(
              height: 300,
              color: Colors.lightBlue,
            ),
          ),

          // Isi Profil dalam SingleChildScrollView agar bisa di-scroll jika melebihi layar
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 100),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: AssetImage('assets/logopoltek.png'), // Gambar profil atau logo
                ),
                SizedBox(height: 16),
                Text(
                  'Nama Pegawai', // Ubah sesuai nama yang diinginkan
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text('-'),
                SizedBox(height: 32),

                // Card informasi di depan slice
                _buildInfoCard(Icons.email, 'Email', 'user@example.com'),
                _buildInfoCard(Icons.domain, 'Unit', 'Politeknik Jember'),
                _buildInfoCard(Icons.check_circle, '0 Presensi', 'Jumlah Presensi Bulan Ini'),
                _buildInfoCard(Icons.event, '0 Kegiatan', 'Jumlah Kegiatan Bulan Ini'),

                // Tombol Logout
                SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () => _showLogoutConfirmation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent, // Warna merah untuk tombol logout
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

  // Widget untuk menampilkan info card
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

  // Menampilkan dialog konfirmasi logout
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
                Navigator.of(context).pop(); // Menutup dialog
              },
            ),
            TextButton(
              child: Text('Logout'),
              onPressed: () async {
                // Hapus data dari SharedPreferences
                SharedPreferences prefs = await SharedPreferences.getInstance();
                await prefs.remove('nama_wali');
                await prefs.remove('no_hp');

                // Arahkan kembali ke halaman login
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

// Custom Clipper untuk efek slice
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

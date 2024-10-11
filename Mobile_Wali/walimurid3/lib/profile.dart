import 'package:flutter/material.dart';
import 'bottombar.dart'; // Import bottom bar

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentIndex = 2; // Set index 2 untuk halaman profil

  void _onItemTapped(int index) {
    if (index == 0) {
      Navigator.pushNamed(context, '/home'); // Navigasi ke Home
    } else if (index == 1) {
      Navigator.pushNamed(context, '/history'); // Navigasi ke History
    }
    // Untuk profil (index 2), tetap di halaman ini
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Efek slice dari atas kanan ke bawah kiri
          ClipPath(
            clipper: CustomDiagonalClipper(), // Menggunakan custom clipper untuk slice
            child: Container(
              height: 300, // Mengurangi tinggi slice agar tidak menutupi konten
              color: Colors.lightBlue, // Warna biru muda untuk background
            ),
          ),

          // Isi Profil dalam SingleChildScrollView agar bisa di-scroll jika melebihi layar
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(height: 100), // Jarak antara slice dan konten
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
                    color: Colors.black, // Warna teks hitam agar kontras dengan background
                  ),
                ),
                SizedBox(height: 8),
                Text('-'), // Tanda pemisah atau bisa diisi dengan informasi lain
                SizedBox(height: 32),

                // Card informasi di depan slice
                _buildInfoCard(Icons.email, 'Email', 'user@example.com'),
                _buildInfoCard(Icons.domain, 'Unit', 'Politeknik Jember'),
                _buildInfoCard(Icons.check_circle, '0 Presensi', 'Jumlah Presensi Bulan Ini'),
                _buildInfoCard(Icons.event, '0 Kegiatan', 'Jumlah Kegiatan Bulan Ini'),
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
        borderRadius: BorderRadius.circular(12), // Membuat sudut card melengkung
      ),
      elevation: 4, // Memberikan bayangan pada Card
      child: ListTile(
        leading: Icon(icon, color: Colors.blueAccent),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}

// Custom Clipper untuk efek slice
class CustomDiagonalClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(size.width, 0.0); // Mulai dari kanan atas
    path.lineTo(0.0, size.height); // Garis ke bawah kiri
    path.lineTo(0.0, 0.0); // Kembali ke titik awal di kiri atas
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

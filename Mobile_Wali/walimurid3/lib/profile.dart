import 'package:flutter/material.dart';
import 'home.dart';
import 'riwayat.dart';
import 'bottombar.dart';
import 'login.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  int _currentIndex = 2;
  String namaWali = "Loading...";
  String noHp = "Loading...";
  String nis = "";
  String kelas = "Loading...";
  String namaSiswa = "Loading...";
  List<dynamic> siswaList = [];
  String? selectedSiswa;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNamaWali = prefs.getString('nama_wali');
      final savedNoHp = prefs.getString('no_hp');

      if (savedNamaWali != null) {
        setState(() {
          namaWali = savedNamaWali;
        });
      }

      if (savedNoHp != null) {
        setState(() {
          noHp = savedNoHp;
        });
      }

      List<String>? siswaJsonList = prefs.getStringList('siswa_list');
      if (siswaJsonList != null) {
        setState(() {
          siswaList = siswaJsonList.map((siswaJson) {
            return json.decode(siswaJson);
          }).toList();

          selectedSiswa =
              prefs.getString('selectedSiswa') ?? siswaList.first['nama'];
          _updateSiswaDetail(
              siswaList.firstWhere((siswa) => siswa['nama'] == selectedSiswa));
        });
      }
    } catch (e) {
      setState(() {
        namaWali = "Error: ${e.toString()}";
      });
    }
  }

  void _updateSiswaDetail(Map<String, dynamic> siswa) {
    setState(() {
      namaSiswa = siswa['nama'];
      nis = siswa['nis'];
      kelas = siswa['nama_kelas'];
    });
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
    } else if (index == 1) {
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
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                      'assets/biru.png'), // Ganti dengan gambar latar belakang
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ),
          Positioned(
            top: 170, // Sesuaikan agar pas dengan potongan diagonal
            left: MediaQuery.of(context).size.width / 2 - 50, // Center logo
            child: CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage(
                  'assets/logopoltek.png'), // Ganti dengan logo yang diinginkan
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 290), // Menyesuaikan posisi setelah logo
                Text(
                  namaWali,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  noHp,
                  style: TextStyle(color: Colors.grey[700]),
                ),
                const SizedBox(height: 32), // Mengatur jarak sebelum card siswa
                _buildInfoCard(),
                const SizedBox(
                    height: 20), // Menambah jarak di bawah card data siswa
                ElevatedButton(
                  onPressed: () => _showLogoutConfirmation(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32, vertical: 12),
                  ),
                  child: const Text(
                    'Logout',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(
                    height: 40), // Menambah jarak di bawah tombol logout
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

  Widget _buildInfoCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 6,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            _buildInfoRow(Icons.person, 'Nama', namaSiswa),
            _buildInfoRow(Icons.credit_card, 'NIS', nis),
            _buildInfoRow(Icons.class_, 'Kelas', kelas),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(subtitle),
    );
  }

  void _showLogoutConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Logout'),
          content: const Text('Apakah Anda yakin ingin logout?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Batal'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: const Text('Logout'),
              onPressed: () async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
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
    path.lineTo(size.width * 0.7, 0); // Membuat titik di dekat atas kanan
    path.lineTo(size.width, size.height * 0.4); // Membentuk diagonal
    path.lineTo(size.width, size.height); // Bagian kanan bawah
    path.lineTo(0, size.height * 0.6); // Membentuk sisi diagonal lain
    path.close(); // Menutup path
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

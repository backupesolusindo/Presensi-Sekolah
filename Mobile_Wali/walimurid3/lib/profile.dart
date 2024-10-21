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
  String nis = "Loading...";
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

      setState(() {
        namaWali = savedNamaWali ?? "Loading...";
        noHp = savedNoHp ?? "Loading...";
      });

      List<String>? siswaJsonList = prefs.getStringList('siswa_list');
      if (siswaJsonList != null && siswaJsonList.isNotEmpty) {
        setState(() {
          siswaList = siswaJsonList.map((siswaJson) {
            return json.decode(siswaJson);
          }).toList();

          selectedSiswa =
              prefs.getString('selectedSiswa') ?? siswaList.first['nama'];
          _updateSiswaDetail(
              siswaList.firstWhere((siswa) => siswa['nama'] == selectedSiswa));
        });
      } else {
        setState(() {
          namaSiswa = "Loading...";
          nis = "Loading...";
          kelas = "Loading...";
        });
      }
    } catch (e) {
      setState(() {
        namaWali = "Error: ${e.toString()}";
        noHp = "Loading...";
        namaSiswa = "Loading...";
        nis = "Loading...";
        kelas = "Loading...";
      });
    }
  }

  void _updateSiswaDetail(Map<String, dynamic> siswa) {
    setState(() {
      namaSiswa = siswa['nama'] ?? "Loading...";
      nis = siswa['nis'] ?? "Loading...";
      kelas = siswa['nama_kelas'] ?? "Loading...";
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
            clipper: CustomSemiCircleClipper(),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.3, // Sesuaikan tinggi sesuai kebutuhan
              decoration: BoxDecoration(
                color: Color(0xFF1A237E), 
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 100),
                _buildProfileCard(),
                const SizedBox(height: 32),
                _buildNamaCard(),
                const SizedBox(height: 16),
                _buildNisCard(),
                const SizedBox(height: 16),
                _buildKelasCard(),
                const SizedBox(height: 20),
                _buildLogoutButton(),
                const SizedBox(height: 20),
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

  Widget _buildProfileCard() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth * 0.8; // 80% dari lebar layar
        return Center(
          child: SizedBox(
            width: cardWidth,
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 6,
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: AssetImage('assets/logopoltek.png'),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      namaWali,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      noHp,
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 16,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNamaCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 6,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Column(
          children: [
            _buildInfoRow(Icons.person, namaSiswa, 'nama siswa'),
          ],
        ),
      ),
    );
  }

  Widget _buildNisCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 6,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Column(
          children: [
            _buildInfoRow(Icons.credit_card, nis, 'nis siswa'),
          ],
        ),
      ),
    );
  }

  Widget _buildKelasCard() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 6,
      shadowColor: Colors.black26,
      child: Padding(
        padding: const EdgeInsets.all(0.0),
        child: Column(
          children: [
            _buildInfoRow(Icons.class_, kelas, 'kelas saat ini'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(
        title == "Loading..." ? title : title,
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

  Widget _buildLogoutButton() {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 6,
      shadowColor: Colors.black26,
      color: Colors.red, // Mengubah warna latar belakang kartu menjadi merah
      child: InkWell(
        onTap: () {
          // Logika logout
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => LoginPage()),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.logout, color: Colors.white), // Mengubah warna ikon menjadi putih
              SizedBox(width: 8),
              Text(
                'Logout',
                style: TextStyle(
                  color: Colors.white, // Mengubah warna teks menjadi putih
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomSemiCircleClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(0, size.height * 0.85); // Menggeser titik awal kurva ke bawah
    path.quadraticBezierTo(
      size.width / 2,
      size.height * 1.1, // Menggeser titik kontrol ke bawah
      size.width,
      size.height * 0.85, // Menggeser titik akhir kurva ke bawah
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

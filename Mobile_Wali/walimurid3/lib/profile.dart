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
  String NamaWali = "Loading..."; // Default teks sementara
  String noHp = "Loading..."; // Tambahkan variabel untuk no_hp

  @override
  void initState() {
    super.initState();
    _fetchData(); // Panggil fungsi untuk mengambil data saat halaman dimuat
  }

  Future<void> _fetchData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedNamaWali = prefs.getString('nama_wali');
      final savedNoHp = prefs.getString('no_hp'); // Ambil no_hp dari SharedPreferences

      if (savedNamaWali != null) {
        setState(() {
          NamaWali = savedNamaWali;
        });
      }

      if (savedNoHp != null) {
        setState(() {
          noHp = savedNoHp; // Set no_hp jika sudah disimpan
        });
      } else {
        final response = await http.get(
          Uri.parse('https://presensi-smp1.esolusindo.com/Api/ApiSiswa/Siswa/getSiswabyHp'), // Ganti dengan URL API Anda
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          final fetchedNamaWali = data['nama_wali'];
          final fetchedNoHp = data['no_hp']; // Ambil no_hp dari response

          await prefs.setString('nama_wali', fetchedNamaWali);
          await prefs.setString('no_hp', fetchedNoHp); // Simpan no_hp ke SharedPreferences

          setState(() {
            NamaWali = fetchedNamaWali;
            noHp = fetchedNoHp; // Set no_hp dari API
          });
        } else {
          setState(() {
            NamaWali = "Gagal memuat data.";
          });
        }
      }
    } catch (e) {
      setState(() {
        NamaWali = "Error: ${e.toString()}";
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
                  NamaWali,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8),
                Text(noHp), // Ganti 'TEST' dengan noHp
                SizedBox(height: 32),
                _buildInfoCard(), // Panggil fungsi yang berisi semua informasi
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

  Widget _buildInfoCard() {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildInfoRow(Icons.email, 'Nama', 'user@example.com'),
            _buildInfoRow(Icons.domain, 'Nis', ''),
            _buildInfoRow(Icons.check_circle, 'Kelas', ''),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String title, String subtitle) {
    return ListTile(
      leading: Icon(icon, color: Colors.blueAccent),
      title: Text(title),
      subtitle: Text(subtitle),
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
    path.lineTo(size.width, 0.0);
    path.lineTo(0.0, size.height);
    path.lineTo(0.0, 0.0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}

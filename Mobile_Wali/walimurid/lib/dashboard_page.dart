import 'package:flutter/material.dart';
import 'dashboard_content.dart';
import 'riwayat_page.dart';
import 'account_page.dart';
import 'login_page.dart';

class DashboardPage extends StatefulWidget {
  final String nama_wali;
  final String no_hp;
  final List<dynamic> siswaData;  // Terima data siswa

  DashboardPage({required this.nama_wali, required this.no_hp, required this.siswaData});

  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _selectedIndex = 0;

  static List<Widget> _pages = <Widget>[
    DashboardContent(), // Halaman Dashboard
    RiwayatPage(),      // Halaman Riwayat
    AccountPage(),      // Halaman Account
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100, 
      body: Stack(
        children: [
          _pages[_selectedIndex], 
          Positioned(
            top: 20,
            right: 20,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.blueAccent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextButton(
                onPressed: () {
                  _logout(context);
                },
                child: Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          // Tampilkan data siswa di dashboard
          Positioned(
            top: 80,
            left: 20,
            right: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Selamat datang, ${widget.nama_wali}!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                Text('No HP: ${widget.no_hp}', style: TextStyle(fontSize: 16)),
                SizedBox(height: 20),
                Text('Data Siswa:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                for (var siswa in widget.siswaData) ...[
                  Text('Nama: ${siswa['nama_siswa']}'),
                  Text('NIS: ${siswa['nis']}'),
                  Text('Kelas: ${siswa['kelas']}'),
                  SizedBox(height: 10),
                ]
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard, size: 30),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history, size: 30),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle, size: 30),
            label: 'Akun',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blueAccent,
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
        ),
        onTap: _onItemTapped,
      ),
    );
  }
}

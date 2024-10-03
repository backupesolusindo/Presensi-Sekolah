import 'package:flutter/material.dart';
import 'dashboard_content.dart';
import 'riwayat_page.dart';
import 'account_page.dart';

class DashboardPage extends StatefulWidget {
  final String nama_wali;
  final String nis_anak;

  DashboardPage({required this.nama_wali, required this.nis_anak});

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex], // Menampilkan halaman berdasarkan index
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Account',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

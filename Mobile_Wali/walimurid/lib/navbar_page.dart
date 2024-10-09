import 'package:flutter/material.dart';
import 'dashboard_content.dart';
import 'riwayat_page.dart';
import 'account_page.dart';

class NavbarPage extends StatefulWidget {
  final String nama_wali; // Menyimpan nama wali
  final String no_hp; // Menyimpan nomor telepon wali
  final List<dynamic> siswaData; // Menyimpan data siswa

  NavbarPage({required this.nama_wali, required this.no_hp, required this.siswaData});

  @override
  _NavbarPageState createState() => _NavbarPageState();
}

class _NavbarPageState extends State<NavbarPage> {
  int _selectedIndex = 0; // Menyimpan indeks halaman yang dipilih

  // Daftar halaman yang akan ditampilkan
  static List<Widget> _pages = <Widget>[
    DashboardContent(namaWali: '', siswaData: [], no_hp: ''), // Placeholder
    RiwayatPage(siswaData: []), // Halaman Riwayat
    AccountPage(namaWali: '', no_hp: ''), // Halaman Akun
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index; // Mengupdate halaman yang dipilih
    });
  }

  @override
  Widget build(BuildContext context) {
    // Mengupdate halaman dashboard dengan nama wali dan data siswa
    _pages[0] = DashboardContent(
      namaWali: widget.nama_wali,
      siswaData: widget.siswaData,
      no_hp: widget.no_hp,
    );

    // Mengupdate halaman akun dengan nama wali dan nomor telepon
    _pages[2] = AccountPage(
      namaWali: widget.nama_wali,
      no_hp: widget.no_hp,
    );

    return Scaffold(
      backgroundColor: Colors.grey.shade100, // Warna latar belakang
      body: _pages[_selectedIndex], // Menampilkan halaman yang dipilih
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
        currentIndex: _selectedIndex, // Indeks halaman yang aktif
        selectedItemColor: Colors.blueAccent, // Warna untuk item yang dipilih
        unselectedItemColor: Colors.grey, // Warna untuk item yang tidak dipilih
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 12,
        ),
        onTap: _onItemTapped, // Callback ketika item dipilih
      ),
    );
  }
}

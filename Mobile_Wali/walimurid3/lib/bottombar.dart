import 'package:flutter/material.dart';
import 'home.dart';  // Import halaman Home
import 'profile.dart';  // Import halaman Profile
import 'riwayat.dart';  // Import halaman Riwayat

class CustomBottomBar extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;

  CustomBottomBar({required this.currentIndex, required this.onTap});

  @override
  _CustomBottomBarState createState() => _CustomBottomBarState();
}

class _CustomBottomBarState extends State<CustomBottomBar> {
  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: widget.currentIndex,
      onTap: (index) {
        widget.onTap(index);  // Panggil fungsi onTap dari parent
        _navigateToPage(index);  // Panggil navigasi sesuai index
      },
      items: [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Riwayat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }

  // Fungsi navigasi untuk berpindah halaman
  void _navigateToPage(int index) {
    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomePage(nama_wali: '', no_hp: '',)),  // Navigasi ke Home
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RiwayatPage()),  // Navigasi ke Riwayat
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => ProfilePage()),  // Navigasi ke Profile
        );
        break;
    }
  }
}

import 'package:flutter/material.dart';
import 'profile.dart'; // Import halaman profil
import 'home.dart'; // Import halaman home

class CustomBottomBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  CustomBottomBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      onTap: (int index) {
        if (index == 0) {
          // Jika index 0 (Home) dipilih
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => HomePage()), // Arahkan ke halaman Home
          );
        } else if (index == 2) {
          // Jika index 2 (Profile) dipilih
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfilePage()), // Arahkan ke halaman profil
          );
        } else {
          onTap(index); // Untuk halaman lain, biarkan onTap menjalankan tugasnya
        }
      },
      items: const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'History',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.account_circle),
          label: 'Profile',
        ),
      ],
    );
  }
}

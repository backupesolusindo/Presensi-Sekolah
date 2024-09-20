import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'data_murid_page.dart'; // Import DataMuridPage
import 'subject_detail_page.dart'; // Import SubjectDetailPage

class HistoryPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    int _selectedIndex = 1; // Set default index to Riwayat

    void _onItemTapped(int index) {
      if (index == 0) {
        // Navigate to Absensi (SubjectDetailPage with sample data)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SubjectDetailPage(subject: {
              'name': 'Matematika',
              'details': 'Detail Subject',
            }),
          ),
        );
      } else if (index == 2) {
        // Navigate to Data Murid
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DataMuridPage()),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat', style: GoogleFonts.roboto(fontSize: 18)),
      ),
      body: Center(
        child: Text('Riwayat Absensi Siswa',
            style: GoogleFonts.roboto(fontSize: 24)),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.class_),
            label: 'Absensi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Data Murid',
          ),
        ],
      ),
    );
  }
}

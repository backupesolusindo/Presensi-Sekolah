import 'package:flutter/material.dart';
import 'subject_detail_page.dart'; // Import the SubjectDetailPage
import 'history_page.dart'; // Import the HistoryPage
import 'package:http/http.dart' as http;
import 'dart:convert';

// Define a model for students
class Student {
  final String name;
  final String dob;

  Student({required this.name, required this.dob});

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      name: json['name'],
      dob: json['dob'],
    );
  }
}

class DataMuridPage extends StatefulWidget {
  @override
  _DataMuridPageState createState() => _DataMuridPageState();
}

class _DataMuridPageState extends State<DataMuridPage> {
  List<Student> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      final response = await http.get(Uri.parse('https://presensi-smp1.esolusindo.com/ApiSiswa/Siswa'));
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        setState(() {
          _students = data.map((studentJson) => Student.fromJson(studentJson)).toList();
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load students');
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data siswa. Coba lagi nanti.')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  int _selectedIndex = 2; // Set default index to Data Murid

  void _onItemTapped(int index) {
    if (index != _selectedIndex) { // Only navigate if the index is different
      setState(() {
        _selectedIndex = index;
      });

      if (index == 0) {
        // Navigate to Absensi (SubjectDetailPage with sample data)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => SubjectDetailPage(subject: {
              'name': 'Matematika', // Replace with actual subject data
              'details': 'Detail Subject', // Replace with actual details
            }),
          ),
        );
      } else if (index == 1) {
        // Navigate to Riwayat
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HistoryPage()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Data Murid'),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : _students.isEmpty
              ? Center(child: Text('Tidak ada data siswa.'))
              : ListView.builder(
                  itemCount: _students.length,
                  itemBuilder: (context, index) {
                    final student = _students[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: AssetImage('assets/student_avatar.png'), // Placeholder
                      ),
                      title: Text(student.name),
                      subtitle: Text('Tanggal Lahir: ${student.dob}'),
                    );
                  },
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

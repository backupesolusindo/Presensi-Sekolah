import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_presensi_kdtg/core.dart'; // Import your Core class for the API URL

class Student {
  final String name;
  final String nis;
  final String namaKelas; // Changed classId to nama_kelas
  final String idKelas; // Added id_kelas field

  Student({
    required this.name,
    required this.nis,
    required this.namaKelas,
    required this.idKelas, // Update constructor to include idKelas
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      name: json['nama'] ?? 'Unknown',
      nis: json['nis'] ?? 'Unknown',
      namaKelas:
          json['nama_kelas'] ?? 'Unknown', // Updated to retrieve nama_kelas
      idKelas: json['id_kelas'] ?? 'Unknown', // Retrieve id_kelas
    );
  }
}

class DataMuridPage extends StatefulWidget {
  final int idKelas; // Class ID to fetch students for this class

  const DataMuridPage({Key? key, required this.idKelas}) : super(key: key);

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
    var url = Uri.parse(
        Core().ApiUrl + "ApiSiswa/Siswa/getSiswabykelas/${widget.idKelas}");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body)['data'];
        setState(() {
          _students =
              jsonResponse.map((json) => Student.fromJson(json)).toList();
          _isLoading = false;
        });
      } else {
        _showErrorDialog('Error: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Failed to load students. Error: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error', style: TextStyle(color: Colors.red)),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }


void _showStudentDetails(Student student) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15), // Rounded corners for the dialog
        ),
        backgroundColor: Colors.white, // Background color of the dialog
        content: Container(
          width: 300, // Fixed width for the dialog
          padding: const EdgeInsets.all(16), // Padding for the container
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Profile icon at the center
              CircleAvatar(
                radius: 30, // Radius for the icon
                backgroundColor: Colors.blue[200],
                child: Icon(Icons.person, size: 30, color: Colors.white), // Icon size
              ),
              const SizedBox(height: 36), // Increased spacing between icon and text
              // Align text to the left
              Align(
                alignment: Alignment.centerLeft, // Align text to the left
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start, // Align text items to the start
                  children: [
                    // Student's name with label
                    Text(
                      'Nama: ${student.name}', // Added label "Nama:"
                      style: TextStyle(
                        fontSize: 16, // Font size for the name
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8), // Spacing between name and other details
                    // NIS as a styled text
                    Text(
                      'NIS: ${student.nis}',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800], // Darker grey for better readability
                      ),
                    ),
                    const SizedBox(height: 8), // Spacing
                    // Class name as styled text
                    Text(
                      'Kelas: ${student.namaKelas}', // Display 'Kelas'
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[800], // Darker grey for better readability
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text(
              'OK',
              style: TextStyle(
                fontSize: 16,
                color: Colors.blue, // Change the text color for the button
              ),
            ),
          ),
        ],
      );
    },
  );
}


  @override
Widget build(BuildContext context) {
  return Scaffold(
    body: Stack(
      children: [
        // Background image with a gradient overlay
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage(
                  'assets/images/WaliRename.png'), // Ensure path is correct
              fit: BoxFit.cover,
            ),
          ),
        ),
        // Overlay for background transparency
        Container(
          color: Colors.black.withOpacity(0.3), // Increased transparency for better readability
        ),
        // Loading indicator or student list
        _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column( // Changed from ListView to Column
                children: [
                  // Card at the top with the title "Data Murid"
                  Card(
                    margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    elevation: 6, // Enhanced shadow for card
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15), // Round card corners
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0), // Padding inside the card
                      child: Text(
                        'Data Murid',
                        style: TextStyle(
                          fontSize: 16, // Font size for the title
                          color: Colors.black, // Text color
                        ),
                        textAlign: TextAlign.center, // Center align the text
                      ),
                    ),
                  ),
                  // ListView to display student details
                  Expanded( // Make ListView take the remaining space
                    child: ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                          elevation: 6, // Enhanced shadow for card
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15), // Round card corners
                          ),
                          child: ListTile(
                            title: Text(
                              _students[index].name,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            subtitle: Text(
                              'NIS: ${_students[index].nis}', // Show NIS as subtitle
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blue[100],
                              child: Icon(Icons.person, color: Colors.blue),
                            ),
                            onTap: () {
                              _showStudentDetails(_students[index]); // Show student details
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ],
    ),
  );
}
}

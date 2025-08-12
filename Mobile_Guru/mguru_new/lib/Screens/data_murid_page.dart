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
  List<Student> _filteredStudents = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    var url = Uri.parse(
        "${Core().ApiUrl}ApiSiswa/Siswa/getSiswabykelas/${widget.idKelas}");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> jsonResponse = json.decode(response.body)['data'];
        setState(() {
          _students =
              jsonResponse.map((json) => Student.fromJson(json)).toList();
          _filteredStudents = _students; // Initialize filtered list
          _isLoading = false;
        });
      } else {
        _showErrorDialog('Error: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Failed to load students. Error: $e');
    }
  }

  void _filterStudents(String query) {
    final filteredList = _students.where((student) {
      return student.name.toLowerCase().contains(query.toLowerCase()) ||
          student.nis.contains(query);
    }).toList();

    setState(() {
      _filteredStudents = filteredList;
    });
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
            borderRadius:
                BorderRadius.circular(15), // Rounded corners for the dialog
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
                  child: const Icon(Icons.person,
                      size: 30, color: Colors.white), // Icon size
                ),
                const SizedBox(
                    height: 36), // Increased spacing between icon and text
                // Align text to the left
                Align(
                  alignment: Alignment.centerLeft, // Align text to the left
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align text items to the start
                    children: [
                      // Row for Student's name
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between columns
                        children: [
                          const Text(
                            'Nama:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 20), // Spacing between label and value
                          Expanded(
                            child: Text(
                              student.name, // Display student's name
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8), // Spacing between name and NIS
                      // Row for NIS
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between columns
                        children: [
                          const Text(
                            'NIS:',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(width: 38), // Spacing between label and value
                          Expanded(
                            child: Text(
                              student.nis,
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.black, // Darker grey for better readability
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8), // Spacing between NIS and class name
                      // Row for Class name
                      if (student.namaKelas.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween, // Space between columns
                          children: [
                            const Text(
                              'Kelas:',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.black,
                              ),
                            ),
                            const SizedBox(width: 26), // Spacing between label and value
                            Expanded(
                              child: Text(
                                student.namaKelas.split(' ').last, // Display only the class part (e.g., "7A")
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.black, // Darker grey for better readability
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _buildStudentTile(Student student) {
  return Container(
    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8), // Lebih kecil
    padding: const EdgeInsets.all(0), // Lebih kecil
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(8),
      boxShadow: [
        BoxShadow(
          color: Colors.grey.shade300,
          spreadRadius: 1, // Lebih kecil
          blurRadius: 6,   // Lebih kecil
          offset: const Offset(0, 3), // Lebih kecil
        ),
      ],
    ),
    child: ListTile(
      title: Text(
        student.name,
        style: const TextStyle(
          fontSize: 14, // Ukuran font lebih kecil
          color: Colors.black,
        ),
      ),
      subtitle: Text(
        'NIS: ${student.nis}',
        style: TextStyle(
          fontSize: 12, // Ukuran font lebih kecil
          color: Colors.grey[600],
        ),
      ),
      leading: CircleAvatar(
        radius: 20,  // Ukuran avatar lebih kecil
        backgroundColor: Colors.blue[100],
        child: const Icon(Icons.person, color: Colors.blue, size: 20), // Ikon lebih kecil
      ),
      onTap: () {
        _showStudentDetails(student);
      },
    ),
  );
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Loading indicator or student list
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(
                      top: 20), // Space for the search field
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        child: TextField(
                          controller: _searchController,
                          onChanged: (query) {
                            _filterStudents(query);
                          },
                          decoration: InputDecoration(
                            hintText: 'Cari Berdasarkan Nama atau NIS',
                            hintStyle: const TextStyle(
                              color: Colors.blueGrey,
                              fontSize: 12,  // Ukuran font lebih kecil
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 1,
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.blueAccent,
                                width: 2,
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: const BorderSide(
                                color: Colors.blue,
                                width: 1,
                              ),
                            ),
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Colors.blue,
                              size: 20,  // Ukuran ikon lebih kecil
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(
                                Icons.clear,
                                color: Colors.blue,
                                size: 20,  // Ukuran ikon lebih kecil
                              ),
                              onPressed: () {
                                _searchController.clear();
                                _filterStudents('');
                              },
                            ),
                          ),

                        ),
                      ),
                      // ListView to display student details
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16), // Padding for list view
                        child: ListView.builder(
                          itemCount: _filteredStudents.length,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            return _buildStudentTile(_filteredStudents[index]);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
        ],
      ),
    );
  }
}

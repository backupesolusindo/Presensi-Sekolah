import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'riwayat_siswa_page.dart';
import 'data_murid_page.dart';
import 'package:mobile_presensi_kdtg/core.dart';

class Student {
  final String name;
  final String nis;
  final int classId;

  Student({required this.name, required this.nis, required this.classId});

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      name: json['nama'] ?? 'Unknown',
      nis: json['nis'] ?? 'Unknown',
      classId: json['id_kelas'] != null
          ? int.tryParse(json['id_kelas'].toString()) ?? 0
          : 0,
    );
  }
}

class ApiResponse {
  final bool status;
  final String message;
  final List<Student> data;

  ApiResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory ApiResponse.fromJson(Map<String, dynamic> json) {
    var list = json['data'] as List;
    List<Student> studentList = list.map((i) => Student.fromJson(i)).toList();
    return ApiResponse(
      status: json['status'] ?? false,
      message: json['message'] ?? 'No message provided',
      data: studentList,
    );
  }
}

class PresensiSiswaPage extends StatefulWidget {
  final String namaMapel;
  final String namaKelas;
  final int idKelas;
  final String waktuMulai;
  final String waktuSelesai;
  final String hari;
  final String tanggal;

  const PresensiSiswaPage({
    Key? key,
    required this.namaMapel,
    required this.namaKelas,
    required this.idKelas,
    required this.waktuMulai,
    required this.waktuSelesai,
    required this.hari,
    required this.tanggal,
  }) : super(key: key);

  @override
  _PresensiSiswaPageState createState() => _PresensiSiswaPageState();
}

class _PresensiSiswaPageState extends State<PresensiSiswaPage> {
  int _selectedIndex = 0;
  List<bool> _hadirList = [];
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
        final apiResponse = ApiResponse.fromJson(json.decode(response.body));
        if (apiResponse.status) {
          setState(() {
            _students = apiResponse.data;
            _isLoading = false;
            _hadirList = List.generate(_students.length, (_) => false);
          });
        } else {
          _showErrorDialog(apiResponse.message);
        }
      } else {
        _showErrorDialog('Error: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Failed to load students. Error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi Siswa',
            style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.blueAccent,
      ),
      body: Stack(
        children: [
          // Background Image
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/WaliRename.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Overlay with opacity
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.3),
            ),
          ),
          // Main content
          _isLoading
              ? Center(
                  child: CircularProgressIndicator(), // Show loading indicator
                )
              : _getSelectedPage(), // Show content after data is loaded
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _getSelectedPage() {
    return _selectedIndex == 0 ? _buildPresensiPage() : _buildOtherPage();
  }

  Widget _buildOtherPage() {
    switch (_selectedIndex) {
      case 1:
        return RiwayatSiswaPage();
      case 2:
        return DataMuridPage(idKelas: widget.idKelas);
      default:
        return Container();
    }
  }

  Widget _buildPresensiPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildInfoCard(),
          const SizedBox(height: 20),
          _buildStudentGrid(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject
            Row(
              children: [
                Icon(Icons.book_rounded, color: Colors.blueAccent, size: 28),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.namaMapel,
                    style: _textStyle(20, FontWeight.bold),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Class
            Row(
              children: [
                Icon(Icons.class_, color: Colors.purpleAccent, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Kelas: ${widget.namaKelas}',
                    style: _textStyle(14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Time
            Row(
              children: [
                Icon(Icons.access_time, color: Colors.orangeAccent, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Waktu: ${widget.waktuMulai} - ${widget.waktuSelesai}',
                    style: _textStyle(14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Day
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    color: Colors.greenAccent, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Hari: ${widget.hari}',
                    style: _textStyle(14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date
            Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.redAccent, size: 20),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Tanggal: ${widget.tanggal.isNotEmpty ? widget.tanggal : 'Belum ditentukan'}',
                    style: _textStyle(14),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentGrid() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    return Expanded(
      child: GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.7,
        ),
        itemCount: _students.length,
        itemBuilder: (context, index) => _buildStudentCard(index),
      ),
    );
  }

  Widget _buildStudentCard(int index) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: InkWell(
        onTap: () {
          setState(() {
            _hadirList[index] = !_hadirList[index];
          });
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
              vertical: 10.0, horizontal: 10.0), // Adjusted padding
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.blue[100],
                child: Icon(
                  Icons.person,
                  size: 20,
                  color: _hadirList[index] ? Colors.blue[700] : Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _students[index].name,
                style: _textStyle(13),
                textAlign: TextAlign.center,
                maxLines: 1, // Limit the text to one line
                overflow: TextOverflow.ellipsis, // Add ellipsis for overflow
              ),
              const SizedBox(
                  height: 12), // Increased space to lower the checkbox
              // Customized Circular Checkbox with Animation
              GestureDetector(
                onTap: () {
                  setState(() {
                    _hadirList[index] = !_hadirList[index];
                  });
                },
                child: AnimatedContainer(
                  duration:
                      const Duration(milliseconds: 300), // Animation duration
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _hadirList[index]
                        ? Colors.green
                        : Colors
                            .transparent, // Background color based on checked state
                    border: Border.all(
                        color: Colors.green, width: 2), // Border color
                  ),
                  width: 20, // Fixed width for circular checkbox
                  height: 20, // Fixed height for circular checkbox
                  alignment: Alignment.center, // Center the icon
                  child: _hadirList[index]
                      ? Icon(
                          Icons.check,
                          color: Colors.white, // Check icon color
                          size: 18, // Adjust the icon size for better fit
                        )
                      : null, // No icon when unchecked
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _textStyle(double size, [FontWeight weight = FontWeight.normal]) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: Colors.black,
    );
  }

  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.assignment_turned_in),
          label: 'Presensi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Riwayat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.people),
          label: 'Data Murid',
        ),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor:
          Colors.blueAccent, // Set selected icon color to blue accent
      unselectedItemColor: Colors.grey[400], // Set unselected icon color
      showSelectedLabels: true, // Optionally show labels for selected items
      showUnselectedLabels: true, // Show labels for unselected items
      backgroundColor: Colors.white, // Background color for the bottom bar
      elevation: 8.0, // Shadow effect for the bottom bar
      type: BottomNavigationBarType.fixed, // Fixed type for consistent layout
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
    );
  }
}

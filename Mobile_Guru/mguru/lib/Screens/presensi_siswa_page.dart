import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'riwayat_siswa_page.dart';
import 'data_murid_page.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  final int idKelas; // Ensure this is an int
  final int idMapel; // Ensure this is an int (previously idJadwalMapel)
  final String waktuMulai;
  final String waktuSelesai;
  final String hari;
  final String tanggal;

  const PresensiSiswaPage({
    Key? key,
    required this.namaMapel,
    required this.namaKelas,
    required this.idKelas,
    required this.idMapel, // Correct parameter name
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
  List<bool> _hadirList = []; // List to track attendance status of each student
  List<Student> _students = []; // List of students
  bool _isLoading = true; // To indicate loading state
  String? NIP; // Declare NIP here
  bool _isTeacherPresent = false; // Declare teacher presence status

  @override
  void initState() {
    super.initState();
    _fetchStudents(); // Fetch the list of students when the page initializes
  }

  getPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    NIP = prefs.getString("NIP")!;
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
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0), // Rounded corners
        ),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Ensure the dialog is small
            children: [
              const Icon(
                Icons.error,
                color: Colors.red,
                size: 60, // Icon size
                semanticLabel: 'Error Icon', // Accessibility
              ),
              const SizedBox(height: 20), // Space between icon and text
              Text(
                'Error',
                style: TextStyle(
                  fontSize: 24, // Title font size
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 10), // Space between title and message
              Text(
                message,
                textAlign: TextAlign.center, // Center the text
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 20), // Space before the button
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close the dialog
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Button color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0), // Rounded button
                  ),
                ),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    },
  );
}



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Presensi Siswa',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
              color: Colors.black.withOpacity(0.3),
            ),
          ),
          // Main content
          _isLoading
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : _getSelectedPage(),
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
          const SizedBox(height: 4),
          _buildSelectAllAndSubmitCard(), // Replace with combined card
          const SizedBox(height: 4),
          _buildStudentGrid(),
        ],
      ),
    );
  }

Future<void> _submitAttendance() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  
  // Get NIP from SharedPreferences
  String? NIP = prefs.getString("NIP");
  print("Attempting to retrieve NIP from SharedPreferences...");

  if (NIP == null) {
    print("NIP not found in SharedPreferences");
    _showErrorDialog('NIP tidak ditemukan!'); // Show error dialog
    return;
  }

  print("Retrieved NIP: $NIP");
  List<Map<String, dynamic>> attendanceData = [];

  // Prepare attendance data
  for (int i = 0; i < _students.length; i++) {
    attendanceData.add({
      'id_siswa': _students[i].nis,  // Ensure 'nis' is a string
      'status': _hadirList[i] ? 1 : 0, // Status 1 for present, 0 for absent
      'id_kelas': widget.idKelas,
      'id_jadwal': widget.idMapel, // Add id_jadwal here
    });
  }

  // Log attendance data
  print("Prepared attendance data: $attendanceData");

  Map<String, dynamic> presensiData = {
    'presensi': {
      'guru': {
        'id_kelas': widget.idKelas, // Ensure this is the correct ID
        'idpegawai': NIP, // Ensure this is a string
        'status_guru': _isTeacherPresent ? 1 : 0, // 1 for present, 0 for absent
        'idjadwal_mapel': widget.idMapel, // Add id_jadwal here
      },
      'siswa': attendanceData, // List of students' attendance
    },
  };

  // Log the presensiData being sent
  print("Presensi Data to be sent: ${jsonEncode(presensiData)}");

  var url = Uri.parse(
      Core().ApiUrl + "ApiPresensi/ApiPresensi/storePresensiGdanS/");
  print("API URL: $url");

  try {
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(presensiData), // Send the data as JSON
    );

    // Log the response status and body
    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      print('Attendance submitted successfully!');
      _showSuccessDialog('Presensi Berhasil!'); // Pass success message
    } else {
      print('Failed to submit attendance: ${response.body}');
      _showErrorDialog('Presensi Gagal: ${response.body}'); // Pass failure message
    }
  } catch (e) {
    print('Error submitting attendance: $e');
    _showErrorDialog('Terjadi kesalahan saat Presensi: $e'); // Pass error message
  }
}


  Widget _buildSelectAllAndSubmitCard() {
    bool allSelected =
        _hadirList.every((element) => element); // Check if all are selected

    return Card(
      elevation: 4, // Reduced elevation for a subtle effect
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)), // Slightly less rounded
      color: Colors.white,
      shadowColor: Colors.black.withOpacity(0.1), // Softer shadow
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: 12.0, vertical: 8.0), // Reduced padding
        child: Row(
          mainAxisAlignment: MainAxisAlignment
              .spaceBetween, // Space between Select All and Submit
          children: [
            // Select All Checkbox
            GestureDetector(
              onTap: () {
                setState(() {
                  // Toggle all students' attendance
                  _hadirList =
                      List.generate(_students.length, (_) => !allSelected);
                });
              },
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: allSelected
                          ? Colors.green
                          : Colors
                              .transparent, // Background color based on checked state
                      border: Border.all(
                          color: Colors.green, width: 2), // Border color
                    ),
                    width: 24, // Smaller width for the checkbox
                    height: 24, // Smaller height for the checkbox
                    alignment: Alignment.center,
                    child: allSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white, // Check icon color
                            size: 16, // Slightly smaller icon
                          )
                        : null, // No icon when unchecked
                  ),
                  const SizedBox(width: 8), // Smaller spacing
                  const Text(
                    'Select All',
                    style: TextStyle(
                      fontSize: 14, // Smaller font size
                      fontWeight: FontWeight
                          .w600, // Medium weight for better visibility
                      color: Colors
                          .black87, // Slightly softer black for better readability
                    ),
                  ),
                ],
              ),
            ),
            // Submit Button
            ElevatedButton(
              onPressed: _submitAttendance,
              child: const Text('Submit'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8), // Reduced padding
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white, // Set text color to white
                textStyle: const TextStyle(
                  fontSize: 14, // Smaller font size for the button
                  fontWeight: FontWeight.bold, // Bold text for emphasis
                ),
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(6), // Slightly less rounded
                ),
                elevation: 2, // Reduced elevation for the button
              ),
            ),
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
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
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


  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0), // Rounded corners
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Ensure the dialog is small
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 60, // Icon size
                ),
                const SizedBox(height: 20), // Space between icon and text
                Text(
                  'Success',
                  style: TextStyle(
                    fontSize: 24, // Title font size
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 10), // Space between title and message
                Text(
                  message,
                  textAlign: TextAlign.center, // Center the text
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20), // Space before the button
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close the dialog
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Button color
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10.0), // Rounded button
                    ),
                  ),
                  child:
                      const Text('OK', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(8.0), // Reduced padding for the card
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mata Pelajaran (Header)
            _buildRow(
              icon: Icons.book_rounded,
              color: Colors.blueAccent,
              text: widget.namaMapel, // Mata pelajaran
              fontSize: 18, // Slightly reduced font size for header
              isBold: true, // Bold text
              backgroundColor: Colors.blue[50], // Light background for contrast
              padding: const EdgeInsets.symmetric(
                  vertical: 8, horizontal: 12), // Adjusted padding for spacing
              textColor:
                  Colors.blueAccent, // Change text color to match the theme
            ),

            const SizedBox(height: 8), // Reduced vertical space after header

            // Kelas
            _buildRow(
              icon: Icons.class_,
              color: Colors.purpleAccent,
              text: 'Kelas: ${widget.namaKelas}', // Nama kelas
            ),

            const SizedBox(height: 8), // Reduced vertical space between rows

            // Waktu
            _buildRow(
              icon: Icons.access_time,
              color: Colors.orangeAccent,
              text:
                  'Waktu: ${widget.waktuMulai} - ${widget.waktuSelesai}', // Waktu mulai dan selesai
            ),

            const SizedBox(height: 8), // Reduced vertical space between rows

            // Hari
            _buildRow(
              icon: Icons.calendar_today_outlined,
              color: Colors.greenAccent,
              text: 'Hari: ${widget.hari}', // Hari pelajaran
            ),

            const SizedBox(height: 8), // Reduced vertical space between rows

            // Tanggal
            _buildRow(
              icon: Icons.calendar_today,
              color: Colors.redAccent,
              text:
                  'Tanggal: ${widget.tanggal.isNotEmpty ? widget.tanggal : 'Belum ditentukan'}', // Tanggal pelajaran
            ),

            const SizedBox(height: 8), // Reduced vertical space between rows

// Checkbox for Teacher's Presence
            GestureDetector(
              onTap: () {
                setState(() {
                  _isTeacherPresent =
                      !_isTeacherPresent; // Toggle presence status
                });
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.person,
                          color: Colors.blue), // Icon next to the text
                      const SizedBox(width: 8), // Space between icon and text
                      const Text('Presensi Guru',
                          style: TextStyle(fontSize: 16)),
                    ],
                  ),
                  Container(
                    width: 30, // Width of the circle
                    height: 30, // Height of the circle
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isTeacherPresent
                          ? Colors.green
                          : Colors.grey[300], // Change color based on status
                    ),
                    child: Center(
                      child: _isTeacherPresent
                          ? const Icon(Icons.check,
                              color: Colors.white) // Checkmark icon
                          : const SizedBox
                              .shrink(), // Empty space if not present
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow({
    required IconData icon,
    required Color color,
    required String text,
    double fontSize = 14, // Slightly reduced font size for normal rows
    bool isBold = false,
    Color? backgroundColor, // Optional background color
    EdgeInsetsGeometry? padding, // Optional padding
    Color textColor = Colors.black, // Default text color
  }) {
    return Container(
      color: backgroundColor, // Set the background color
      padding: padding ??
          const EdgeInsets.symmetric(
              vertical: 2, horizontal: 4), // Reduced padding for rows
      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.center, // Aligns icons and text centrally
        children: [
          Icon(icon,
              color: color, size: 25), // Adjusted icon size for compactness
          const SizedBox(width: 8), // Reduced space between icon and text
          Expanded(
            // Ensure text occupies remaining space
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: textColor, // Set the text color
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.blue,
      onTap: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Presensi',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.history),
          label: 'Riwayat',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Data Murid',
        ),
      ],
    );
  }

  TextStyle _textStyle(double fontSize) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: Colors.black,
    );
  }
}

import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'data_murid_page.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

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
  final String idMapel; // Add id_mapel
  final String idJadwal; // Add id_jadwal

  const PresensiSiswaPage({
    super.key,
    required this.namaMapel,
    required this.namaKelas,
    required this.idKelas,
    required this.waktuMulai,
    required this.waktuSelesai,
    required this.hari,
    required this.tanggal,
    required this.idMapel, // Include id_mapel in constructor
    required this.idJadwal, // Include id_jadwal in constructor
  });

  @override
  _PresensiSiswaPageState createState() => _PresensiSiswaPageState();
}

class _PresensiSiswaPageState extends State<PresensiSiswaPage> {
  int _selectedIndex = 0;
  List<bool> _hadirList = [];
  List<Student> _students = [];
  bool _isLoading = true;
  String? NIP; // Declare NIP here
  int isGuruHadir = 0;
  
  

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> getPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    NIP = prefs.getString("NIP")!;
  }

  Future<void> _fetchStudents() async {
    var url = Uri.parse(
        "${Core().ApiUrl}ApiSiswa/Siswa/getSiswabykelas/${widget.idKelas}");

    print("Fetching students from URL: $url"); // Log the URL being fetched

    try {
        final response = await http.get(url);
        print("Response status code: ${response.statusCode}"); // Log the response status code

        if (response.statusCode == 200) {
            final apiResponse = ApiResponse.fromJson(json.decode(response.body));
            print("API Response: ${apiResponse.toString()}"); // Log the API response

            if (apiResponse.status) {
                setState(() {
                    _students = apiResponse.data;
                    _isLoading = false;
                    _hadirList = List.generate(_students.length, (_) => false);
                });
                print("Students fetched successfully: ${_students.length} students."); // Log success
            } else {
                _showErrorDialog(apiResponse.message);
                print("API Error: ${apiResponse.message}"); // Log API error message
            }
        } else if (response.statusCode == 404) {
            _showErrorDialog('Resource not found. Please check the URL.');
            print("HTTP Error: 404 - Resource not found."); // Log HTTP error
        } else {
            _showErrorDialog('Error: ${response.statusCode}');
            print("HTTP Error: ${response.statusCode}"); // Log HTTP error
        }
    } catch (e) {
        _showErrorDialog('Failed to load students. Error: $e');
        print("Exception occurred: $e"); // Log exception
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
                const Text(
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _selectedIndex == 0 ? 'Presensi Siswa' : 'Data Murid', // Title changes based on selected page
          style: const TextStyle(
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
          // Container(
          //   decoration: BoxDecoration(
          //     image: DecorationImage(
          //       image: AssetImage('assets/images/WaliRename.png'),
          //       fit: BoxFit.cover,
          //     ),
          //   ),
          // ),
          // Overlay with opacity
          // Container(
          //   decoration: BoxDecoration(
          //     color: Colors.black.withOpacity(0.3),
          //   ),
          // ),
          // Main content
          _isLoading
              ? const Center(
                  child: CircularProgressIndicator(),
                )
              : _getSelectedPage(),
        ],
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

   // Page selection logic
  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildPresensiPage();
      case 1:
        return DataMuridPage(idKelas: widget.idKelas); // Passing idKelas to DataMuridPage
      default:
        return Container(); // Fallback in case of error
    }
  }

  Widget _buildPresensiPage() {
    return Column(children: [
      _buildSelectAllAndSubmitCard(),
      Expanded(
          child: SingleChildScrollView(
        child: Column(
          children: [
            _buildInfoCard(),
            const SizedBox(height: 4),
            _buildStudentGrid()
          ],
        ),
      ))
    ]);
  }

  Widget _buildSelectAllAndSubmitCard() {
    bool allSelected =
        _hadirList.every((element) => element); // Check if all are selected

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300, // Soft grey shadow with transparency
            spreadRadius: 2, // Controls how much the shadow spreads
            blurRadius: 8, // Higher value for smooth shadow
            offset:
                const Offset(0, 4), // Offset for vertical shadow, adjust as needed
          ),
        ],
      ),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStudentGrid() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return GridView.builder(
      padding: EdgeInsets.zero,
      shrinkWrap: true, // GridView akan menyusut sesuai isi
      physics:
          const NeverScrollableScrollPhysics(), // Disable scroll GridView karena sudah dalam SingleChildScrollView
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.7,
      ),
      itemCount: _students.length,
      itemBuilder: (context, index) => _buildStudentCard(index),
    );
  }

  Widget _buildStudentCard(int index) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300, // Soft grey shadow with transparency
            spreadRadius: 2, // Controls how much the shadow spreads
            blurRadius: 8, // Higher value for smooth shadow
            offset: const Offset(0, 4), // Offset for vertical shadow
          ),
        ],
      ),
      margin: const EdgeInsets.all(8), // Similar margin as in Card
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
                      ? const Icon(
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

  Future<void> _submitAttendance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Get NIP from SharedPreferences
    String? NIP = prefs.getString("NIP");
    print("Attempting to retrieve NIP from SharedPreferences...");

    print("Retrieved NIP: $NIP");
    List<Map<String, dynamic>> attendanceData = [];

    // Prepare attendance data
    for (int i = 0; i < _students.length; i++) {
      attendanceData.add({
        'id_siswa': _students[i].nis,
        'id_jadwal': widget.idJadwal.toString(),
        'status': _hadirList[i] ? 1 : 0,
        'id_kelas': widget.idKelas.toString(),
      });
    }

    // Get current date in desired format (e.g., yyyy-MM-dd)
    String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Log attendance data
    print("Prepared attendance data: $attendanceData");

    // Update the status of the teacher based on isGuruHadir
    int guruStatus =
        isGuruHadir == 1 ? 1 : 0; // Assuming 1 for present and 0 for absent

    Map<String, dynamic> presensiData = {
      'presensi': {
        'guru': {
          'id_jadwal_mapel': widget.idJadwal.toString(),
          'id_guru': NIP,
          'status': guruStatus, // Use the updated status for the teacher
          'tanggal': formattedDate, // Use current date here
        },
        'siswa': attendanceData,
      },
    };

    // Log the presensiData being sent
    print("Presensi Data to be sent: ${jsonEncode(presensiData)}");

    var url = Uri.parse(
        "${Core().ApiUrl}ApiPresensi/ApiPresensi/storePresensiGdanS/");
    print("API URL: $url");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(presensiData),
      );

      // Log the response status and body
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        print('Attendance submitted successfully!');
        _showSuccessDialog('Presensi Berhasil!'); // Pass success message
      } else {
        print('Failed to submit attendance: ${response.body}');
        _showErrorDialog('Presensi Gagal'); // Pass failure message
      }
    } catch (e) {
      print('Error submitting attendance: $e');
      _showErrorDialog(
          'Terjadi kesalahan saat Presensi: $e'); // Pass error message
    }
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
                const Text(
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300, // Soft grey shadow with transparency
            spreadRadius: 2, // Controls how much the shadow spreads
            blurRadius: 8, // Higher value for smooth shadow
            offset:
                const Offset(0, 4), // Offset for vertical shadow, adjust as needed
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildRow(
              icon: Icons.book_rounded,
              color: Colors.blueAccent,
              text: widget.namaMapel,
              fontSize: 18,
              isBold: true,
              backgroundColor: Colors.blue[50],
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              textColor: Colors.blueAccent,
            ),
            const SizedBox(height: 8),
            _buildRow(
              icon: Icons.class_,
              color: Colors.purpleAccent,
              text: 'Kelas: ${widget.namaKelas}',
            ),
            const SizedBox(height: 8),
            _buildRow(
              icon: Icons.access_time,
              color: Colors.orangeAccent,
              text: 'Waktu: ${widget.waktuMulai} - ${widget.waktuSelesai}',
            ),
            const SizedBox(height: 8),
            _buildRow(
              icon: Icons.calendar_today_outlined,
              color: Colors.greenAccent,
              text: 'Hari: ${widget.hari}',
            ),
            const SizedBox(height: 8),
            _buildRow(
              icon: Icons.calendar_today,
              color: Colors.redAccent,
              text: 'Tanggal: ${_formatDate(widget.tanggal)}',
            ),
            const SizedBox(height: 10), // Space above the checkbox row
            // Custom circular checkbox for teacher's attendance with icon and text
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceBetween, // Aligns items to the edges
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      // Toggle the value of isGuruHadir
                      isGuruHadir =
                          isGuruHadir == 1 ? 0 : 1; // Switch between 0 and 1
                    });
                  },
                  child: const Row(
                    children: [
                      Icon(Icons.person,
                          color: Colors.green), // Icon for teacher
                      SizedBox(width: 8), // Space between icon and text
                      Text(
                        'Presensi Guru:',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400), // Text style
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      // Toggle the value of isGuruHadir
                      isGuruHadir =
                          isGuruHadir == 1 ? 0 : 1; // Switch between 0 and 1
                    });
                  },
                  child: AnimatedContainer(
                    duration:
                        const Duration(milliseconds: 300), // Animation duration
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isGuruHadir == 1
                          ? Colors.green
                          : Colors.transparent, // Background color
                      border: Border.all(
                          color: Colors.green, width: 2), // Border color
                    ),
                    width: 24, // Slightly larger for easier interaction
                    height: 24, // Slightly larger for easier interaction
                    alignment: Alignment.center, // Center the icon
                    child: isGuruHadir == 1
                        ? const Icon(
                            Icons.check,
                            color: Colors.white, // Check icon color
                            size: 16, // Adjust the icon size for better fit
                          )
                        : null, // No icon when unchecked
                  ),
                ),
              ],
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
      onTap: (int index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      type: BottomNavigationBarType.fixed,
      backgroundColor: Colors.white,
      showSelectedLabels: false,
      showUnselectedLabels: false,
      selectedItemColor: Colors.blueAccent[700],
      unselectedItemColor: Colors.grey[400],
      elevation: 30.0,
      items: [
        Icons.assignment, // Icon for Presensi Page
        Icons.person      // Icon for Data Murid Page
      ]
          .asMap()
          .map((key, value) => MapEntry(
                key,
                BottomNavigationBarItem(
                  label: "",
                  icon: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 6.0,
                      horizontal: 16.0,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedIndex == key
                          ? Colors.blueAccent
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: Icon(
                      value,
                      color: _selectedIndex == key
                          ? Colors.white
                          : Colors.grey[400],
                    ),
                  ),
                ),
              ))
          .values
          .toList(),
    );
  }

  TextStyle _textStyle(double fontSize) {
    return TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w500,
      color: Colors.black,
    );
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return 'Belum ditentukan'; // Return default message if date is null or empty
    }
    
    try {
      DateTime parsedDate = DateTime.parse(date); // Parse the date string
      return '${parsedDate.day.toString().padLeft(2, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.year}'; // Format to DD-MM-YYYY
    } catch (e) {
      return 'Tanggal tidak valid'; // Return error message if parsing fails
    }
  }
}

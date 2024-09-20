import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mguru/data_murid_page.dart';
// import 'data_murid_page.dart' as data_murid; // Gunakan prefix
import 'api_service.dart'; // Import the API service
import 'student_model.dart' as student_model; // Gunakan prefix

class SubjectDetailPage extends StatefulWidget {
  final dynamic subject; // Data for the selected subject

  SubjectDetailPage({required this.subject});

  @override
  _SubjectDetailPageState createState() => _SubjectDetailPageState();
}

class _SubjectDetailPageState extends State<SubjectDetailPage> {
  List<student_model.Student> _students = []; // Gunakan prefix
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchStudents();
  }

  Future<void> _fetchStudents() async {
    try {
      List<student_model.Student> students =
          await fetchStudents(widget.subject['id']);
      setState(() {
        _students = students;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error fetching students: $e');
    }
  }

  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    // Handle navigation based on index
    if (index == 0) {
      // Stay on the current page (SubjectDetailPage)
    } else if (index == 1) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => DataMuridPage()), // Navigate to DataMuridPage
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.subject['name'],
            style: GoogleFonts.roboto(fontSize: 18)),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                children: [
                  Text(
                    'Nama Murid',
                    style: GoogleFonts.roboto(
                        fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  Expanded(
                    child: GridView.builder(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        childAspectRatio: 1,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        var student = _students[index];
                        return GestureDetector(
                          onTap: () => _showAttendanceDialog(
                              context, student), // Show dialog on tap
                          child: Column(
                            children: [
                              CircleAvatar(
                                backgroundImage: AssetImage(
                                    'assets/student_avatar.png'), // Placeholder
                                radius: 30,
                              ),
                              SizedBox(height: 5),
                              Text(
                                student.name,
                                style: GoogleFonts.roboto(fontSize: 16),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
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
            icon: Icon(Icons.account_circle),
            label: 'Data Murid',
          ),
        ],
      ),
    );
  }

  // Attendance dialog
  void _showAttendanceDialog(
      BuildContext context, student_model.Student student) {
    // Gunakan prefix
    showDialog(
      context: context,
      builder: (context) {
        return AttendanceDialog(student: student);
      },
    );
  }
}

class AttendanceDialog extends StatefulWidget {
  final student_model.Student student; // Gunakan prefix

  AttendanceDialog({required this.student});

  @override
  _AttendanceDialogState createState() => _AttendanceDialogState();
}

class _AttendanceDialogState extends State<AttendanceDialog> {
  String? attendanceStatus;
  String reason = '';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    backgroundImage:
                        AssetImage('assets/student_avatar.png'), // Placeholder
                    radius: 40,
                  ),
                  SizedBox(height: 10),
                  Text(
                    widget.student.name,
                    style: GoogleFonts.roboto(
                        fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 5),
                  Text(
                    widget.student.dob,
                    style: GoogleFonts.roboto(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Text('Keterangan',
                style: GoogleFonts.roboto(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            Column(
              children: ['Hadir', 'Tidak Hadir', 'Terlambat', 'Izin', 'Sakit']
                  .map((status) {
                return RadioListTile<String>(
                  title: Text(status, style: GoogleFonts.roboto(fontSize: 16)),
                  value: status,
                  groupValue: attendanceStatus,
                  onChanged: (value) {
                    setState(() {
                      attendanceStatus = value;
                    });
                  },
                );
              }).toList(),
            ),
            if (attendanceStatus != 'Hadir' && attendanceStatus != null) ...[
              SizedBox(height: 10),
              TextField(
                onChanged: (value) {
                  reason = value;
                },
                decoration: InputDecoration(
                  labelText: 'Alasan',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text('Batal', style: GoogleFonts.roboto(fontSize: 16)),
                ),
                ElevatedButton(
                  onPressed: () {
                    // Logic to save attendance data goes here
                    print(
                        'Attendance for ${widget.student.name}: $attendanceStatus, Reason: $reason');
                    Navigator.pop(context);
                  },
                  child: Text('Kirim', style: GoogleFonts.roboto(fontSize: 16)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

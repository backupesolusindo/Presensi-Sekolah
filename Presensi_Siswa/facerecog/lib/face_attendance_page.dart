import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class FaceAttendancePage extends StatefulWidget {
  @override
  _FaceAttendancePageState createState() => _FaceAttendancePageState();
}

class _FaceAttendancePageState extends State<FaceAttendancePage> {
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    final databaseRef = FirebaseDatabase.instance.ref('siswa');
    final snapshot = await databaseRef.once();

    if (snapshot.snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      setState(() {
        _students =
            data.values.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Face Attendance',
          style: TextStyle(
            fontWeight: FontWeight.bold, // Membuat teks tebal
            color: Colors.white, // Mengatur warna teks menjadi putih
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 129, 198, 255),
                const Color.fromARGB(255, 10, 59, 103),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              const Color.fromARGB(255, 129, 198, 255),
              const Color.fromARGB(255, 10, 59, 103),
            ],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: ListView.builder(
            itemCount: _students.length,
            itemBuilder: (context, index) {
              final student = _students[index];
              return Container(
                margin: EdgeInsets.symmetric(vertical: 10),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.all(16),
                    title: Text(
                      student['name'],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      'Class: ${student['class']} | NIS: ${student['nis']}',
                      style: TextStyle(fontSize: 16),
                    ),
                    trailing: Icon(Icons.face, color: Colors.blue[600]),
                    onTap: () {
                      // Implement face recognition here
                      // Compare the scanned face with student['faceData']
                      // and update attendance status accordingly
                    },
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

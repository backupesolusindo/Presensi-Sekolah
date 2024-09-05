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
    final databaseRef = FirebaseDatabase.instance.ref('students');
    final snapshot = await databaseRef.once();

    if (snapshot.snapshot.value != null) {
      final data = Map<String, dynamic>.from(snapshot.snapshot.value as Map);
      setState(() {
        _students = data.values.map((e) => Map<String, dynamic>.from(e)).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Face Attendance'),
      ),
      body: ListView.builder(
        itemCount: _students.length,
        itemBuilder: (context, index) {
          final student = _students[index];
          return ListTile(
            title: Text(student['name']),
            subtitle: Text('Class: ${student['class']} | NIS: ${student['nis']}'),
            onTap: () {
              // Implement face recognition here
              // Compare the scanned face with student['faceData']
              // and update attendance status accordingly
            },
          );
        },
      ),
    );
  }
}

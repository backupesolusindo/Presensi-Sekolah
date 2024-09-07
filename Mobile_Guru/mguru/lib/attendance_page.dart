import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class AttendancePage extends StatefulWidget {
  final String subjectKey;

  AttendancePage({required this.subjectKey});

  @override
  _AttendancePageState createState() => _AttendancePageState();
}

class _AttendancePageState extends State<AttendancePage> {
  final DatabaseReference _attendanceRef = FirebaseDatabase.instance.reference().child('attendance');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Absensi Murid'),
      ),
      body: StreamBuilder(
        stream: _attendanceRef.child(widget.subjectKey).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> event) {
          if (event.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (event.hasError) {
            return Center(child: Text('Terjadi kesalahan'));
          }

          // Ambil snapshot dari event dan cek null safety
          final snapshot = event.data?.snapshot;
          if (snapshot == null || snapshot.value == null) {
            return Center(child: Text('Tidak ada data absensi'));
          }

          // Casting data snapshot ke Map<dynamic, dynamic>
          final data = Map<dynamic, dynamic>.from(snapshot.value as Map);

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final studentKey = data.keys.elementAt(index);
              final studentData = data[studentKey];

              // Pastikan studentData tidak null sebelum akses dengan []
              final studentName = studentData?['name'] ?? 'Nama tidak tersedia';
              final attendanceStatus = studentData?['status'] ?? 'Status tidak tersedia';

              return ListTile(
                title: Text(studentName),
                subtitle: Text('Status: $attendanceStatus'),
                onTap: () {
                  // Aksi ketika murid dipilih
                },
              );
            },
          );
        },
      ),
    );
  }
}

import 'package:flutter/material.dart';

class AttendancePage extends StatelessWidget {
  final String userId;

  const AttendancePage({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Attendance Confirmation'),
      ),
      body: Center(
        child: Text('Absensi berhasil untuk user: $userId'),
      ),
    );
  }
}

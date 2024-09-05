import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'vision_detector_views/face_mesh_detector_view.dart'; // Sesuaikan dengan path baru

class FaceAttendancePage extends StatefulWidget {
  @override
  _FaceAttendancePageState createState() => _FaceAttendancePageState();
}

class _FaceAttendancePageState extends State<FaceAttendancePage> {
  List<Map<String, dynamic>> _registeredFaces = [];
  String _statusMessage = 'Arahkan wajah Anda ke kamera untuk absen.';

  @override
  void initState() {
    super.initState();
    _fetchRegisteredFaces();
  }

  Future<void> _fetchRegisteredFaces() async {
    final databaseRef = FirebaseDatabase.instance.ref('students');
    DatabaseEvent event = await databaseRef.once();
    DataSnapshot snapshot = event.snapshot;

    if (snapshot.exists) {
      Map<String, dynamic> studentsData = Map<String, dynamic>.from(snapshot.value as Map);
      List<Map<String, dynamic>> registeredFaces = [];

      studentsData.forEach((key, value) {
        Map<String, dynamic> student = Map<String, dynamic>.from(value);
        registeredFaces.add(student);
      });

      setState(() {
        _registeredFaces = registeredFaces;
      });
    }
  }

  Future<void> _startAttendance() async {
    // Navigasi ke halaman deteksi wajah untuk mendapatkan data wajah yang terdeteksi
    final detectedFace = await Navigator.push<List<double>>(
      context,
      MaterialPageRoute(
        builder: (context) => FaceMeshDetectorView(),
      ),
    );

    if (detectedFace != null) {
      _checkAttendance(detectedFace);
    }
  }

  void _checkAttendance(List<double> detectedFace) {
    // Bandingkan data wajah yang terdeteksi dengan data yang tersimpan di Firebase
    for (var student in _registeredFaces) {
      List<dynamic> registeredFaceData = student['faceData'];

      // Menghitung perbedaan antara data wajah yang terdeteksi dan yang terdaftar
      double difference = _calculateFaceDifference(detectedFace, registeredFaceData);

      if (difference < 0.1) { // Batas toleransi perbedaan (nilai ini bisa disesuaikan)
        _markAttendance(student);
        return;
      }
    }

    setState(() {
      _statusMessage = 'Wajah tidak dikenal. Coba lagi!';
    });
  }

  double _calculateFaceDifference(List<double> detectedFace, List<dynamic> registeredFaceData) {
    double sum = 0;
    for (int i = 0; i < detectedFace.length; i++) {
      sum += (detectedFace[i] - registeredFaceData[i]).abs();
    }
    return sum / detectedFace.length; // Menghasilkan rata-rata perbedaan
  }

  Future<void> _markAttendance(Map<String, dynamic> student) async {
    final databaseRef = FirebaseDatabase.instance.ref('attendance').child(student['id']);
    final date = DateTime.now().toIso8601String();

    await databaseRef.set({
      'name': student['name'],
      'class': student['class'],
      'nis': student['nis'],
      'timestamp': date,
    });

    setState(() {
      _statusMessage = 'Absensi berhasil untuk ${student['name']}!';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Absensi Wajah'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _statusMessage,
              style: TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _startAttendance,
              child: Text('Mulai Absen'),
            ),
          ],
        ),
      ),
    );
  }
}

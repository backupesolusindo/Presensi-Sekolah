import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:firebase_database/firebase_database.dart';
import 'vision_detector_views/face_detector_view.dart';

class FaceAttendancePage extends StatefulWidget {
  @override
  _FaceAttendancePageState createState() => _FaceAttendancePageState();
}

class _FaceAttendancePageState extends State<FaceAttendancePage> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref();
  Map<String, dynamic> _studentsData = {}; // Data siswa dengan wajah
  bool _isAttendanceComplete = false;
  String _attendanceStatus = '';

  @override
  void initState() {
    super.initState();
    _fetchStudentsData();
  }

  Future<void> _fetchStudentsData() async {
    // Mengambil data siswa dari database
    final dataSnapshot = await _databaseRef.child('students').get();
    if (dataSnapshot.exists) {
      setState(() {
        _studentsData = Map<String, dynamic>.from(dataSnapshot.value as Map);
      });
    } else {
      setState(() {
        _attendanceStatus = 'Tidak ada data siswa ditemukan.';
      });
    }
  }

  Future<void> _onFaceDetected(List<double>? detectedFaceData) async {
    if (detectedFaceData == null) {
      setState(() {
        _attendanceStatus = 'Wajah tidak terdeteksi.';
      });
      return;
    }

    // Proses perbandingan wajah dengan data di database
    bool isFaceMatched = false;
    String? studentId;

    _studentsData.forEach((key, studentData) {
      List<dynamic> storedFaceData = studentData['faceData'];
      if (_compareFaces(storedFaceData, detectedFaceData)) {
        isFaceMatched = true;
        studentId = key;
      }
    });

    if (isFaceMatched && studentId != null) {
      await _markAttendance(studentId!);
      setState(() {
        _attendanceStatus = 'Absensi berhasil untuk siswa: ${_studentsData[studentId!]['name']}';
        _isAttendanceComplete = true;
      });
    } else {
      setState(() {
        _attendanceStatus = 'Wajah tidak cocok dengan data siswa.';
      });
    }
  }

  // Fungsi untuk membandingkan data wajah yang terdeteksi dengan data di database
  bool _compareFaces(List<dynamic> storedFaceData, List<double> detectedFaceData) {
    const double threshold = 0.1; // Threshold untuk toleransi perbedaan
    for (int i = 0; i < storedFaceData.length; i++) {
      if ((storedFaceData[i] - detectedFaceData[i]).abs() > threshold) {
        return false;
      }
    }
    return true;
  }

  // Fungsi untuk menandai absensi siswa ke database
  Future<void> _markAttendance(String studentId) async {
    final now = DateTime.now();
    final attendanceData = {
      'date': now.toIso8601String(),
      'status': 'present',
    };

    await _databaseRef.child('attendance/$studentId').set(attendanceData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Face Attendance'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Expanded(
            child: FaceDetectorView(
              onFaceDetected: _onFaceDetected,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              _attendanceStatus,
              style: TextStyle(fontSize: 18, color: _isAttendanceComplete ? Colors.green : Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}

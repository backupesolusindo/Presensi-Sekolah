import 'package:firebase_database/firebase_database.dart';

class FirebaseService {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  Future<void> saveAttendance(String userId) async {
    final attendanceRef = _dbRef.child('attendance').push();
    await attendanceRef.set({
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }
}

import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:camera/camera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_database/firebase_database.dart';
import 'dart:io';

class FaceRecognitionService {
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final DatabaseReference _dbRef = FirebaseDatabase.instance.ref();

  static Future<void> saveUserPhoto(String userId, XFile picture) async {
    final file = File(picture.path);
    final storageRef = _storage.ref().child('user_photos/$userId.jpg');
    final uploadTask = storageRef.putFile(file);

    await uploadTask.whenComplete(() async {
      final photoUrl = await storageRef.getDownloadURL();
      await _dbRef.child('users/$userId').update({
        'photoUrl': photoUrl,
      });
    });
  }

  static Future<void> recognizeFace(XFile picture, String userId) async {
    final inputImage = InputImage.fromFilePath(picture.path);
    final faceDetector = GoogleMlKit.vision.faceDetector();
    final faces = await faceDetector.processImage(inputImage);

    if (faces.isNotEmpty) {
      // Wajah terdeteksi, lakukan proses absensi di sini
      print('Wajah terdeteksi');
      // Simpan foto pengguna jika belum ada
      await saveUserPhoto(userId, picture);
      // Lanjutkan ke AttendancePage atau simpan absensi ke Firebase
    } else {
      print('Tidak ada wajah terdeteksi');
    }

    faceDetector.close();
  }
}

import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:camera/camera.dart';

class FaceRecognitionService {
  static Future<void> recognizeFace(XFile picture) async {
    final inputImage = InputImage.fromFilePath(picture.path);
    final faceDetector = GoogleMlKit.vision.faceDetector();
    final faces = await faceDetector.processImage(inputImage);

    if (faces.isNotEmpty) {
      // Wajah terdeteksi, lakukan proses absensi di sini
      print('Wajah terdeteksi');
      // Lanjutkan ke AttendancePage atau simpan absensi ke Firebase
    } else {
      print('Tidak ada wajah terdeteksi');
    }

    faceDetector.close();
  }
}

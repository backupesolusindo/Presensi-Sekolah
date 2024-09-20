import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:http/http.dart' as http;
import 'ML/Recognition.dart';
import 'ML/Recognizer.dart';

class RecognitionScreen extends StatefulWidget {
  const RecognitionScreen({Key? key}) : super(key: key);

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen> {
  late ImagePicker imagePicker;
  File? _image;

  late FaceDetector faceDetector;
  late Recognizer recognizer;

  List<Recognition> recognitions = [];
  List<Face> faces = [];
  var image;
  String detectedNIS = "";

  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();

    final options = FaceDetectorOptions();
    faceDetector = FaceDetector(options: options);

    recognizer = Recognizer();
  }

  Future<void> _imgFromCamera() async {
    XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        doFaceDetection();
      });
    }
  }

  Future<void> _imgFromGallery() async {
    XFile? pickedFile =
        await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        doFaceDetection();
      });
    }
  }

  Future<void> doFaceDetection() async {
    recognitions.clear();
    _image = await removeRotation(_image!);

    if (_image != null) {
      var imageBytes = await _image!.readAsBytes();
      image = await decodeImageFromList(imageBytes);

      InputImage inputImage = InputImage.fromFile(_image!);
      faces = await faceDetector.processImage(inputImage);

      for (Face face in faces) {
        Rect faceRect = face.boundingBox;
        num left = max(0, faceRect.left);
        num top = max(0, faceRect.top);
        num right = min(image.width, faceRect.right);
        num bottom = min(image.height, faceRect.bottom);
        num width = right - left;
        num height = bottom - top;

        final bytes = _image!.readAsBytesSync();
        img.Image? faceImg = img.decodeImage(bytes);

        if (faceImg != null) {
          img.Image croppedFace = img.copyCrop(
            faceImg,
            x: left.toInt(),
            y: top.toInt(),
            width: width.toInt(),
            height: height.toInt(),
          );

          Recognition recognition = recognizer.recognize(croppedFace, faceRect);
          recognitions.add(recognition);

          detectedNIS = recognition.nis;
        }
      }

      drawRectangleAroundFaces();
    }
  }

  Future<File> removeRotation(File inputImage) async {
    final img.Image? capturedImage =
        img.decodeImage(await File(inputImage.path).readAsBytes());
    if (capturedImage != null) {
      final img.Image orientedImage = img.bakeOrientation(capturedImage);
      return await File(_image!.path)
          .writeAsBytes(img.encodeJpg(orientedImage));
    }
    return inputImage;
  }

  Future<void> drawRectangleAroundFaces() async {
    if (_image != null) {
      var imageBytes = await _image!.readAsBytes();
      image = await decodeImageFromList(imageBytes);

      setState(() {
        recognitions;
        image;
        faces;
      });
    }
  }

  Future<void> verifyAttendance() async {
    if (detectedNIS.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return _buildDialog(
            title: 'Gagal',
            message: 'NIS tidak terdeteksi',
            icon: Icons.error,
            iconColor: Colors.red,
          );
        },
      );
      return;
    }

    final url =
        'https://presensi-smp1.esolusindo.com/ApiGerbang/Gerbang/uploadAbsen';
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'nis': detectedNIS, 'status': 'absen'}),
    );

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return _buildDialog(
            title: 'Sukses',
            message: responseData['message'],
            icon: Icons.check_circle,
            iconColor: Colors.green,
          );
        },
      );
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return _buildDialog(
            title: 'Gagal',
            message: 'Gagal mengirim data',
            icon: Icons.error,
            iconColor: Colors.red,
          );
        },
      );
    }
  }

  Widget _buildDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
  }) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.0),
      ),
      title: Row(
        children: [
          Icon(icon, color: iconColor),
          SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      content: Text(
        message,
        style: TextStyle(
          color: Colors.black54,
        ),
      ),
      actions: <Widget>[
        TextButton(
          child: const Text(
            'OK',
            style: TextStyle(color: Colors.blue),
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
      backgroundColor: Colors.white,
      elevation: 24.0,
    );
  }

  TextEditingController textEditingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.blue[50], // Sesuaikan dengan warna latar belakang
      resizeToAvoidBottomInset: false,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          image != null
              ? Container(
                  margin: const EdgeInsets.only(
                      top: 60, left: 30, right: 30, bottom: 0),
                  child: FittedBox(
                    child: SizedBox(
                      width: image.width.toDouble(),
                      height: image.height.toDouble(),
                      child: CustomPaint(
                        painter: FacePainter(
                          facesList: recognitions,
                          imageFile: image,
                        ),
                      ),
                    ),
                  ),
                )
              : Container(
                  margin: const EdgeInsets.only(top: 100),
                  child: Image.asset(
                    "images/logo.png",
                    width: screenWidth - 100,
                    height: screenWidth - 100,
                  ),
                ),
          Container(height: 20),
          ElevatedButton(
            onPressed: verifyAttendance,
            child: Text("Verifikasi"),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white, backgroundColor: Colors.blue, // Mengatur warna teks tombol
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(20), // Mengatur bentuk tombol
              ),
            ),
          ),
          Container(
            margin: const EdgeInsets.only(bottom: 50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 5,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _imgFromGallery,
                    child: Container(
                      width: screenWidth / 2 - 50,
                      height: screenWidth / 2 - 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Colors.blue, Colors.blueAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.image,
                              color: Colors.white, size: screenWidth / 7),
                          const SizedBox(height: 10),
                          const Text(
                            "Galeri",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 5,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _imgFromCamera,
                    child: Container(
                      width: screenWidth / 2 - 50,
                      height: screenWidth / 2 - 50,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          colors: [Colors.green, Colors.greenAccent],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt,
                              color: Colors.white, size: screenWidth / 7),
                          const SizedBox(height: 10),
                          const Text(
                            "Kamera",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  final List<Recognition> facesList;
  final img.Image imageFile;
  final double maxWidth;

  FacePainter({
    required this.facesList,
    required this.imageFile,
    this.maxWidth = 800,
  });

  @override
  void paint(Canvas canvas, Size size) {
    double scale = size.width / maxWidth;
    Paint paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..color = Colors.red;

    for (var face in facesList) {
      canvas.drawRect(
        Rect.fromLTWH(
          face.rect.left.toDouble() * scale,
          face.rect.top.toDouble() * scale,
          face.rect.width.toDouble() * scale,
          face.rect.height.toDouble() * scale,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

class Recognition {
  final String nis;
  final Rect rect;

  Recognition({
    required this.nis,
    required this.rect,
  });
}

class Recognizer {
  Recognition recognize(img.Image faceImg, Rect faceRect) {
    String recognizedNIS = "123456"; // Replace with your recognition logic
    return Recognition(nis: recognizedNIS, rect: faceRect);
  }
}

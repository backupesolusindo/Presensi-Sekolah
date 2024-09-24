import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:lottie/lottie.dart';
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
  bool isLoading = false; // Add this line

  late FaceDetector faceDetector;
  late Recognizer recognizer;

  List<Recognition> recognitions = [];
  List<Face> faces = [];
  var image;
  List<String> detectedNISList = []; // Ubah menjadi List

  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();

    final options = FaceDetectorOptions();
    faceDetector = FaceDetector(options: options);

    recognizer = Recognizer();
  }

  Future<void> _imgFromCamera() async {
    setState(() {
      isLoading = true; // Start loading
    });

    XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await doFaceDetection(); // Wait for face detection to complete
    }

    setState(() {
      isLoading = false; // Stop loading
    });
  }

  Future<void> _imgFromGallery() async {
    setState(() {
      isLoading = true; // Start loading
    });

    XFile? pickedFile =
        await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await doFaceDetection(); // Wait for face detection to complete
    }

    setState(() {
      isLoading = false; // Stop loading
    });
  }

  Future<void> doFaceDetection() async {
    recognitions.clear();
    detectedNISList.clear(); // Kosongkan list sebelum deteksi
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

          // Simpan NIS yang terdeteksi (jika belum ada dalam list)
          if (!detectedNISList.contains(recognition.nis)) {
            detectedNISList.add(recognition.nis);
          }
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
    if (detectedNISList.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return _buildDialog(
            title: 'Gagal',
            message: 'Wajah tidak terdeteksi',
            icon: Icons.error,
            iconColor: Colors.red,
          );
        },
      );
      return;
    }

    final url =
        'https://presensi-smp1.esolusindo.com/ApiGerbang/Gerbang/uploadAbsen';

    // Mengirim semua NIS yang terdeteksi
    for (String nis in detectedNISList) {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'nis': nis, 'status': 'absen'}),
      );

      if (response.statusCode != 200) {
        // Tangani jika ada kesalahan
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return _buildDialog(
              title: 'Gagal',
              message: 'Gagal Absen $nis',
              icon: Icons.error,
              iconColor: Colors.red,
            );
          },
        );
      }
    }

    // Tampilkan dialog sukses setelah semua NIS berhasil dikirim
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _buildDialog(
          title: 'Sukses',
          message: 'Absen Berhasil',
          icon: Icons.check_circle,
          iconColor: Colors.green,
        );
      },
    );

    // Kosongkan list setelah verifikasi
    detectedNISList.clear();
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
      appBar: AppBar(
        title: Text('Sistem Absensi Wajah'),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pop(context); // Navigate back to the previous screen
          },
        ),
        backgroundColor: Colors.blueAccent,
      ),
      backgroundColor: Colors.blue[50],
      resizeToAvoidBottomInset: false,
      body: SingleChildScrollView(
        // Wrap with SingleChildScrollView
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (isLoading)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      'assets/loading1.json', // Ensure this path is correct
                      width: 100,
                      height: 100,
                    ),
                    SizedBox(height: 20),
                    Text(
                      'Mohon Ditunggu',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            if (!isLoading) // Only show the image if not loading
              image != null
                  ? Container(
                      margin: const EdgeInsets.only(
                          top: 30, left: 30, right: 30, bottom: 0),
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
            if (image != null && !isLoading) // Only show button if not loading
              ElevatedButton(
                onPressed: verifyAttendance,
                child: Text("Verifikasi"),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  backgroundColor: Colors.blueAccent,
                  shadowColor: Colors.blue.withOpacity(0.5),
                  elevation: 5,
                ),
              ),
            Container(
              margin: const EdgeInsets.only(bottom: 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  //   Card(
                  //   shape: RoundedRectangleBorder(
                  //     borderRadius: BorderRadius.circular(20),
                  //   ),
                  //   elevation: 5,
                  //   child: InkWell(
                  //     borderRadius: BorderRadius.circular(20),
                  //     onTap: _imgFromGallery,
                  //     child: Container(
                  //       width: screenWidth / 2 - 50,
                  //       height: screenWidth / 2 - 50,
                  //       decoration: BoxDecoration(
                  //         borderRadius: BorderRadius.circular(20),
                  //         gradient: const LinearGradient(
                  //           colors: [Colors.blue, Colors.blueAccent],
                  //           begin: Alignment.topLeft,
                  //           end: Alignment.bottomRight,
                  //         ),
                  //       ),
                  //       child: Column(
                  //         mainAxisAlignment: MainAxisAlignment.center,
                  //         children: [
                  //           Icon(Icons.image,
                  //               color: Colors.white, size: screenWidth / 7),
                  //           const SizedBox(height: 10),
                  //           const Text(
                  //             "Galeri",
                  //             style: TextStyle(
                  //               color: Colors.white,
                  //               fontSize: 18,
                  //               fontWeight: FontWeight.bold,
                  //             ),
                  //           ),
                  //         ],
                  //       ),
                  //     ),
                  //   ),
                  // ),
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
                            colors: [
                              Colors.blue,
                              Colors.lightBlueAccent
                            ], // Updated to a blue gradient
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
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  List<Recognition> facesList;
  dynamic imageFile;

  FacePainter({required this.facesList, @required this.imageFile});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile, Offset.zero, Paint());
    }

    Paint p = Paint();
    p.color = Colors.red;
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 3;

    for (Recognition rectangle in facesList) {
      canvas.drawRect(rectangle.location, p);
      // TEKS DIKOTAK WAJAH
      TextSpan span = TextSpan(
        style: const TextStyle(color: Colors.white, fontSize: 130),
        text: "${rectangle.name} ${(rectangle.confidence).toStringAsFixed(2)}%",
      );

      TextPainter tp = TextPainter(
        text: span,
        textAlign: TextAlign.left,
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(rectangle.location.left, rectangle.location.top));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

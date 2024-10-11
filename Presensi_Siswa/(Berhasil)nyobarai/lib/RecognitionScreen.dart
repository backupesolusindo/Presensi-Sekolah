import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart'; // Tambahkan package kamera
import 'ML/Recognition.dart';
import 'ML/Recognizer.dart';

class RecognitionScreen extends StatefulWidget {
  const RecognitionScreen({Key? key}) : super(key: key);

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen> {
  CameraController? cameraController; // Controller untuk kamera
  File? _image;
  bool isLoading = false;
  bool isFrontCamera = true; // Menyimpan status kamera (depan/belakang)
  bool showPreview = true; // Untuk menampilkan preview kamera atau gambar hasil

  late FaceDetector faceDetector;
  late Recognizer recognizer;

  List<Recognition> recognitions = [];
  List<Face> faces = [];
  var image;
  List<String> detectedNISList = [];

  @override
  void initState() {
    super.initState();
    initializeCamera(); // Inisialisasi kamera

    final options = FaceDetectorOptions();
    faceDetector = FaceDetector(options: options);

    recognizer = Recognizer();
  }

  Future<void> initializeCamera([bool isFront = true]) async {
    // Ambil daftar kamera yang tersedia
    final cameras = await availableCameras();

    // Pilih kamera berdasarkan `isFront`
    final selectedCamera = isFront
        ? cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
          )
        : cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
          );

    // Inisialisasi controller kamera
    cameraController = CameraController(
      selectedCamera,
      ResolutionPreset.high,
    );

    // Mulai kamera
    await cameraController?.initialize();
    setState(() {});
  }

  Future<void> captureImage() async {
    if (cameraController == null || !cameraController!.value.isInitialized) {
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      // Ambil gambar dari kamera
      final XFile imageFile = await cameraController!.takePicture();
      setState(() {
        _image = File(imageFile.path);
        showPreview = false; // Ganti ke tampilan gambar hasil
      });

      await doFaceDetection(); // Deteksi wajah setelah gambar diambil

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      print("Error capturing image: $e");
    }
  }

  Future<void> doFaceDetection() async {
    recognitions.clear();
    detectedNISList.clear();

    if (_image != null) {
      _image = await removeRotation(_image!);
      var imageBytes = await _image!.readAsBytes();
      image = await decodeImageFromList(imageBytes);

      InputImage inputImage = InputImage.fromFile(_image!);
      faces = await faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        setState(() {
          showPreview =
              false; // Tidak menampilkan preview jika wajah tidak terdeteksi
        });

        // Tampilkan dialog ketika wajah tidak terdeteksi
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    color: Colors.red, size: 80), // Ikon X merah besar
                const SizedBox(height: 10),
                const Text(
                  "Wajah Tidak Terdeteksi",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
            content: const Text(
              "Pastikan wajah terlihat jelas dan coba lagi.",
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx); // Tutup dialog dan kembali
                  setState(() {
                    showPreview = true; // Kembali ke tampilan preview kamera
                  });
                },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: const Text("Coba Lagi"),
              ),
            ],
          ),
        );
        return;
      }

      // Jika wajah terdeteksi, lanjutkan dengan proses pengenalan
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

          if (!detectedNISList.contains(recognition.nis)) {
            detectedNISList.add(recognition.nis);
          }
        }
      }

      // Jika tidak ada wajah yang dikenali, tampilkan dialog error
      if (detectedNISList.isEmpty) {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return _buildDialog(
              title: 'Gagal',
              message: 'Wajah tidak dikenali',
              icon: Icons.error,
              iconColor: Colors.red,
            );
          },
        );
      } else {
        // Jika wajah dikenali, lanjutkan dengan proses lainnya
        drawRectangleAroundFaces();
      }
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
            message: 'Wajah tidak terdeteksi, coba foto lagi',
            icon: Icons.error,
            iconColor: Colors.red,
          );
        },
      );
      return;
    }

    final url =
        'https://presensi-smp1.esolusindo.com/Api/ApiGerbang/Gerbang/uploadAbsen';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.vertical(
            bottom:
                Radius.circular(16), // Menentukan seberapa tumpul sudut bawah
          ),
          child: AppBar(
            title: Text(
              'Absensi Wajah',
              style: TextStyle(
                  color: Colors.white), // Ubah warna teks menjadi putih
            ),
            centerTitle: true, // Membuat teks di tengah
            leading: IconButton(
              icon: Image.asset(
                  'assets/logoSMP.png'), // Mengganti tombol dengan logo
              onPressed: () {
                Navigator.pop(context); // Navigasi kembali ke layar sebelumnya
              },
            ),
            backgroundColor: Colors.blueAccent,
          ),
        ),
      ),
      backgroundColor: Colors.blue[50],
      resizeToAvoidBottomInset: false,
      body: Column(
        children: [
          if (isLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Lottie.asset(
                      "assets/loading1.json",
                      width: 100,
                      height: 100,
                    ),
                    const Text(
                      'Loading...',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            )
          else if (cameraController != null &&
              cameraController!.value.isInitialized &&
              showPreview)
            // Tampilkan preview kamera dengan ukuran penuh
            Expanded(
              child: CameraPreview(cameraController!),
            )
          else if (!showPreview && _image != null)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(20),
                child: FittedBox(
                  fit: BoxFit
                      .contain, // Sesuaikan gambar agar pas dengan ukuran layar
                  child: SizedBox(
                    width: image.width
                        .toDouble(), // Menggunakan ukuran asli gambar
                    height: image.height.toDouble(),
                    child: CustomPaint(
                      painter: FacePainter(
                          facesList: recognitions, imageFile: image),
                    ),
                  ),
                ),
              ),
            ),
          SizedBox(height: 20),
          if (showPreview)
            ElevatedButton(
              onPressed: () async {
                await captureImage(); // Mengambil gambar langsung dari kamera
              },
              child: Text('Ambil Gambar'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                padding: EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                textStyle: TextStyle(fontSize: 16),
              ),
            ),
          if (!showPreview && detectedNISList.isNotEmpty)
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Posisikan di tengah
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showPreview = true; // Kembali ke tampilan preview kamera
                    });
                  },
                  child: Text('Ambil Ulang'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
                SizedBox(width: 20), // Spasi di antara tombol
                ElevatedButton(
                  onPressed: () async {
                    await verifyAttendance(); // Mengirim data untuk verifikasi absen
                  },
                  child: Text('Verifikasi Kehadiran'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 10, vertical: 20),
                    textStyle: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          SizedBox(height: 20),
        ],
      ),
    );
  }

  @override
  void dispose() {
    cameraController?.dispose();
    faceDetector.close();
    super.dispose();
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
      // TEKS DI KOTAK WAJAH
      TextSpan span = TextSpan(
        style: const TextStyle(color: Colors.white, fontSize: 41),
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

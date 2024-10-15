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

    for (Recognition rectangle in recognitions) {
      if (rectangle.name == "Tidak dikenali") {
        // Tangani jika wajah tidak dikenali
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return _buildDialog(
              title: 'Gagal',
              message: 'Wajah belum terdaftar',
              icon: Icons.error,
              iconColor: Colors.red,
            );
          },
        );
        return;
      } else {
        // Nama dari rectangle yang dikenali
        String recognizedName = rectangle.name;
        print("Wajah dikenali: $recognizedName");

        // Lanjutkan dengan proses absen
        final url =
            'https://presensi-smp1.esolusindo.com/Api/ApiGerbang/Gerbang/uploadAbsen';

        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'nis': rectangle.nis, 'status': 'absen'}),
        );

        if (response.statusCode != 200) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return _buildDialog(
                title: 'Gagal',
                message: 'Gagal Absen untuk $recognizedName',
                icon: Icons.error,
                iconColor: Colors.red,
              );
            },
          );
        }
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
            Expanded(
              child: Stack(
                children: [
                  // Tampilkan preview kamera dengan ukuran penuh
                  ClipRect(
                    child: Align(
                      alignment: Alignment.center,
                      child: CameraPreview(cameraController!),
                    ),
                  ),
                  // Menambahkan kotak wajah di atas preview kamera
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.3, // Menentukan opasitas gambar
                      child: FractionallySizedBox(
                        widthFactor: 1.7, // Menentukan lebar
                        heightFactor: 1.7, // Menentukan tinggi
                        child: Image.asset(
                          'assets/kotakwajah.png',
                          fit: BoxFit
                              .contain, // Menyesuaikan gambar dengan area yang diberikan
                        ),
                      ),
                    ),
                  ),

                  Positioned.fill(
                    child: Opacity(
                      opacity: 1.0, // Menentukan opasitas gambar
                      child: FractionallySizedBox(
                        widthFactor:
                            1.7, // Menentukan lebar sebagai 80% dari lebar parent
                        heightFactor:
                            1.7, // Menentukan tinggi sebagai 80% dari tinggi parent
                        child: Image.asset(
                          'assets/kotaknya.png',
                          fit: BoxFit
                              .contain, // Menyesuaikan gambar dengan area yang diberikan
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          else if (!showPreview && _image != null)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(0),
                child: FittedBox(
                  fit: BoxFit.cover, // Mengubah ini untuk memperbesar gambar
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
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.center, // Posisikan tombol di tengah
              children: [
                ElevatedButton(
                  onPressed: () async {
                    await captureImage(); // Mengambil gambar langsung dari kamera
                  },
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical:
                            12), // Tambahkan padding untuk menyesuaikan ukuran tombol
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize
                        .min, // Sesuaikan ukuran tombol dengan konten
                    children: [
                      Icon(Icons.camera_alt), // Ikon kamera
                      const SizedBox(width: 8), // Jarak antara ikon dan teks
                      const Text('Ambil Gambar'),
                    ],
                  ),
                ),

                const SizedBox(width: 10), // Jarak antara dua tombol
                IconButton(
                  icon: Icon(Icons.cameraswitch),
                  onPressed: () async {
                    setState(() {
                      isFrontCamera =
                          !isFrontCamera; // Ubah status kamera (depan/belakang)
                    });
                    await initializeCamera(
                        isFrontCamera); // Inisialisasi ulang kamera
                  },
                ),
              ],
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
                  child: const Text('Ambil Ulang'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                  ),
                ),
                SizedBox(width: 20), // Spasi di antara tombol
                ElevatedButton(
                  onPressed: () async {
                    await verifyAttendance(); // Mengirim data untuk verifikasi absen
                  },
                  child: const Text('Verifikasi Kehadiran'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.green, // Teks berwarna putih
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 0),
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
    p.color = const Color.fromARGB(255, 30, 255, 0);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 5;

    // Draw rectangle and text for each face
    for (Recognition rectangle in facesList) {
      // Draw the face rectangle
      canvas.drawRect(rectangle.location, p);

      // Check if the name is "Tidak dikenali"
      if (rectangle.name == "Tidak dikenali") {
        // Display "Wajah Tidak Dikenali" message
        _drawTextWithBackground(
          canvas,
          "Wajah Tidak Dikenali",
          rectangle.location.left,
          rectangle.location.top - 80, // Position above the rectangle
        );
      } else {
        // Display the name and confidence for recognized faces
        String text =
            "${rectangle.name} ${(rectangle.confidence).toStringAsFixed(2)}%";
        _drawTextWithBackground(
          canvas,
          text,
          rectangle.location.left,
          rectangle.location.top - 80, // Position above the rectangle
        );
      }
    }
  }

  // Custom method to draw text with background
  void _drawTextWithBackground(Canvas canvas, String text, double x, double y) {
    TextSpan span = TextSpan(
      style: TextStyle(
          color: Colors.black, fontSize: 30, fontWeight: FontWeight.bold),
      text: text,
    );

    TextPainter tp = TextPainter(
      text: span,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
      maxLines: 2, // Limit to 2 lines
      ellipsis: '...', // Ellipsis for overflow text
    );
    tp.layout(maxWidth: 500); // Set max width to 200px

    // Calculate background size
    Paint backgroundPaint = Paint()..color = Colors.white;
    double padding = 6;
    Rect backgroundRect = Rect.fromLTWH(x - padding, y - padding,
        tp.width + 2 * padding, tp.height + 2 * padding);
    canvas.drawRect(backgroundRect, backgroundPaint);

    // Draw the text over the background
    tp.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

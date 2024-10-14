import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:camera/camera.dart';
import 'ML/Recognition.dart';
import 'ML/Recognizer.dart';
import 'DB/DatabaseHelper.dart';
import 'package:lottie/lottie.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  CameraController? cameraController;
  File? _image;
  bool isLoading = false;
  bool isFrontCamera = true; // Menyimpan status kamera (depan/belakang)
  bool showPreview = true;
  late FaceDetector faceDetector;
  late Recognizer recognizer;
  List<Recognition> recognitions = [];
  List<Face> faces = [];
  var image;

  TextEditingController nameController = TextEditingController();
  TextEditingController nisController = TextEditingController();
  TextEditingController kelasController = TextEditingController();
  TextEditingController noHpOrtuController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeCamera();
    final options = FaceDetectorOptions();
    faceDetector = FaceDetector(options: options);
    recognizer = Recognizer();
  }

  Future<void> initializeCamera([bool isFront = true]) async {
    final cameras = await availableCameras();
    final selectedCamera = isFront
        ? cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.front,
          )
        : cameras.firstWhere(
            (camera) => camera.lensDirection == CameraLensDirection.back,
          );

    cameraController = CameraController(
      selectedCamera,
      ResolutionPreset.high,
    );

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

      final XFile imageFile = await cameraController!.takePicture();
      setState(() {
        _image = File(imageFile.path);
        showPreview = false; // Ganti ke tampilan gambar hasil
      });

      await doFaceDetection();

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
    setState(() {
      isLoading = true; // Mulai proses loading
    });

    if (_image == null) return;

    _image = await removeRotation(_image!);
    image = await _image?.readAsBytes();
    image = await decodeImageFromList(image);
    InputImage inputImage = InputImage.fromFile(_image!);
    faces = await faceDetector.processImage(inputImage);

    setState(() {
      isLoading = false; // Hentikan proses loading
    });

    if (faces.isNotEmpty) {
      for (Face face in faces) {
        Rect faceRect = face.boundingBox;
        num left = faceRect.left < 0 ? 0 : faceRect.left;
        num top = faceRect.top < 0 ? 0 : faceRect.top;
        num right =
            faceRect.right > image.width ? image.width - 1 : faceRect.right;
        num bottom =
            faceRect.bottom > image.height ? image.height - 1 : faceRect.bottom;
        num width = right - left;
        num height = bottom - top;

        final bytes = _image!.readAsBytesSync();
        img.Image? faceImg = img.decodeImage(bytes);
        img.Image croppedFace = img.copyCrop(faceImg!,
            x: left.toInt(),
            y: top.toInt(),
            width: width.toInt(),
            height: height.toInt());

        Recognition recognition = recognizer.recognize(croppedFace, faceRect);
        showFaceRegistrationDialogue(
            Uint8List.fromList(img.encodeBmp(croppedFace)), recognition);
      }
    } else {
      showNoFaceDetectedDialog();
    }
    drawRectangleAroundFaces();
  }

  void showNoFaceDetectedDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 80),
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
  }

  showFaceRegistrationDialogue(Uint8List croppedFace, Recognition recognition) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Pendaftaran Wajah", textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 20),
              Image.memory(croppedFace, width: 200, height: 200),
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  hintText: "Nama",
                ),
              ),
              TextField(
                controller: nisController,
                decoration: const InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  hintText: "NIS",
                ),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: kelasController,
                decoration: const InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  hintText: "Kelas",
                ),
              ),
              TextField(
                controller: noHpOrtuController,
                decoration: const InputDecoration(
                  fillColor: Colors.white,
                  filled: true,
                  hintText: "No HP Orang Tua",
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () async {
                  await registerFace(recognition);
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    minimumSize: const Size(200, 40)),
                child: const Text("Register"),
              ),
            ],
          ),
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  Future<void> registerFace(Recognition recognition) async {
    if (nameController.text.isEmpty ||
        nisController.text.isEmpty ||
        noHpOrtuController.text.isEmpty ||
        kelasController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Isi dengan lengkap")),
      );
    } else if (await DatabaseHelper.instance.isNisExists(nisController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("NIS telah terdaftar")),
      );
    } else {
      recognizer.registerFaceInDB(
          nameController.text,
          nisController.text,
          kelasController.text,
          noHpOrtuController.text,
          recognition.embeddings);

      showSuccessDialog();
    }
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Success", textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 100),
            const SizedBox(height: 20),
            const Text("Berhasil Mendaftar", textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx); // Tutup dialog sukses
              Navigator.pop(context); // Kembali ke halaman sebelumnya
            },
            child: const Text("OK"),
          ),
        ],
      ),
    );

    // Reset text controllers setelah dialog sukses ditutup
    nameController.clear();
    nisController.clear();
    kelasController.clear();
    noHpOrtuController.clear();
  }

  Future<void> drawRectangleAroundFaces() async {
    image = await _image?.readAsBytes();
    image = await decodeImageFromList(image);
    setState(() {
      image;
    });
  }

  removeRotation(File inputImage) async {
    final img.Image? capturedImage =
        img.decodeImage(await File(inputImage.path).readAsBytes());
    final img.Image orientedImage = img.bakeOrientation(capturedImage!);
    return await File(_image!.path).writeAsBytes(img.encodeJpg(orientedImage));
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

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
              'Registrasi Wajah',
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
      body: Center(
        child: isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Lottie.asset('assets/loading1.json',
                        width: 150, height: 150),
                    const SizedBox(height: 20),
                    const Text(
                      'Mohon Ditunggu...',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              )
            : cameraController == null
                ? const CircularProgressIndicator()
                : Column(
                    children: [
                      Expanded(
                        child: Stack(
                          children: [
                            if (showPreview) CameraPreview(cameraController!),
                            if (showPreview)
                              Positioned.fill(
                                child: Image.asset(
                                  'assets/kotakwajah.png',
                                  fit: BoxFit
                                      .cover, // Menyesuaikan ukuran gambar dengan layar
                                ),
                              ),
                            if (!showPreview && _image != null)
                              Image.file(_image!),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Jarak antara preview dan tombol
                      if (showPreview)
                        ElevatedButton(
                          onPressed: captureImage,
                          child: const Text("Ambil Gambar"),
                        ),

                      // Menampilkan tombol Capture Again hanya jika _image != null
                      if (!showPreview && _image != null)
                        ElevatedButton(
                          onPressed: () {
                            setState(() {
                              showPreview = true; // Kembali ke preview kamera
                              _image = null; // Reset gambar
                            });
                          },
                          child: const Text("Ambil Ulang"),
                        ),
                      const SizedBox(
                          height: 20), // Jarak tambahan di bawah tombol
                    ],
                  ),
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

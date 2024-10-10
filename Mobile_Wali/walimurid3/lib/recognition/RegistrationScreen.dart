import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:walimurid3/recognition/UserListScreen.dart';
import 'ML/Recognition.dart';
import 'ML/Recognizer.dart';
import 'DB/DatabaseHelper.dart'; // Pastikan path ini sesuai
import 'package:lottie/lottie.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({Key? key}) : super(key: key);

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  late ImagePicker imagePicker;
  File? _image;
  late FaceDetector faceDetector;
  late Recognizer recognizer;
  List<Face> faces = [];
  var image;
  bool isLoading = false; // Tambahkan isLoading
  TextEditingController nameController = TextEditingController();
  TextEditingController nisController = TextEditingController();
  TextEditingController kelasController = TextEditingController();
  TextEditingController noHpOrtuController = TextEditingController();

  @override
  void initState() {
    super.initState();
    imagePicker = ImagePicker();

    final options = FaceDetectorOptions();
    faceDetector = FaceDetector(options: options);
    recognizer = Recognizer();
  }

  _imgFromCamera() async {
    XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        doFaceDetection();
      });
    }
  }

  _imgFromGallery() async {
    XFile? pickedFile =
        await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        doFaceDetection();
      });
    }
  }

  doFaceDetection() async {
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
      // Jika wajah tidak terdeteksi, tampilkan dialog peringatan dengan X besar
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
    drawRectangleAroundFaces();
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
                  if (nameController.text.isEmpty ||
                      nisController.text.isEmpty ||
                      noHpOrtuController.text.isEmpty ||
                      kelasController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Isi dengan lengkap")),
                    );
                  } else if (await DatabaseHelper.instance
                      .isNisExists(nisController.text)) {
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

                    // Show success dialog and navigate to UserListScreen
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title:
                            const Text("Success", textAlign: TextAlign.center),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.check_circle,
                                color: Colors.green, size: 100),
                            const SizedBox(height: 20),
                            const Text("Berhasil Mendaftar",
                                textAlign: TextAlign.center),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(ctx); // Close the success dialog
                              Navigator.pop(
                                  context); // Go back to the previous screen
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => UserListScreen()),
                              );
                            },
                            child: const Text("OK"),
                          ),
                        ],
                      ),
                    );

                    // Reset text controllers after success dialog
                    nameController.clear();
                    nisController.clear();
                    kelasController.clear();
                    noHpOrtuController.clear();
                  }
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

  drawRectangleAroundFaces() async {
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

  // build method
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
      body: isLoading // Tampilkan loading animasi saat isLoading true
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset('assets/loading1.json', width: 150, height: 150),
                  const SizedBox(height: 20),
                  const Text(
                    'Mohon Ditunggu...',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            )
          : Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                image != null
                    ? Container(
                        margin:
                            const EdgeInsets.only(top: 60, left: 30, right: 30),
                        child: FittedBox(
                          child: SizedBox(
                            width: image.width.toDouble(),
                            height: image.width.toDouble(),
                            child: CustomPaint(
                              painter: FacePainter(
                                  facesList: faces, imageFile: image),
                            ),
                          ),
                        ),
                      )
                    : Container(
                        margin: const EdgeInsets.only(top: 100),
                        child: Image.asset(
                          "assets/gambarmuka.png",
                          width: screenWidth - 100,
                          height: screenWidth - 100,
                        ),
                      ),
                const SizedBox(height: 50),
                Container(
                  margin: const EdgeInsets.only(bottom: 50),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Uncomment this section if you want to include the gallery card
                      // Card(
                      //   shape: RoundedRectangleBorder(
                      //     borderRadius: BorderRadius.circular(20),
                      //   ),
                      //   elevation: 10, // Increased elevation for a more pronounced shadow
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
                      //               color: Colors.white,
                      //               size: screenWidth / 6), // Slightly larger icon
                      //           const SizedBox(height: 10),
                      //           const Text(
                      //             "Galeri",
                      //             style: TextStyle(
                      //               color: Colors.white,
                      //               fontSize: 20, // Increased font size for better readability
                      //               fontWeight: FontWeight.w600, // Change to a lighter weight
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
                        elevation:
                            10, // Increased elevation for a more pronounced shadow
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
                                    color: Colors.white,
                                    size: screenWidth /
                                        6), // Slightly larger icon
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
  List<Face> facesList;
  var imageFile;

  FacePainter({required this.facesList, required this.imageFile});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0
      ..color = Colors.lightGreen;

    canvas.drawImage(imageFile, Offset.zero, Paint());

    for (Face face in facesList) {
      canvas.drawRect(face.boundingBox, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}

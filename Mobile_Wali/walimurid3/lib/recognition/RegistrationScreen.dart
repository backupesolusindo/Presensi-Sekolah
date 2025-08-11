import 'dart:convert';
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
import 'package:http/http.dart' as http;

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

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
  String? selectedKelas;
  List<dynamic> kelasList = [];
  TextEditingController noHpOrtuController = TextEditingController();

  @override
  void initState() {
    super.initState();
    initializeCamera();
    final options = FaceDetectorOptions();
    faceDetector = FaceDetector(options: options);
    recognizer = Recognizer();
    fetchKelas();
  }

  Future<void> syncData() async {
    setState(() {
      isLoading = true;
    });

    final dbHelper = DatabaseHelper.instance;
    final users = await dbHelper.queryAllRows();
    List<Map<String, dynamic>> arData = [];

    for (var user in users) {
      arData.add({
        'nama': user[DatabaseHelper.columnName],
        'nis': user[DatabaseHelper.columnNIS],
        'id_kelas': user[DatabaseHelper.columnKelas],
        'no_hp_ortu':
            user[DatabaseHelper.columnNoHpOrtu], // Tambahkan No HP Orang Tua
        'model': user[DatabaseHelper.columnEmbedding],
      });
    }
    String bodyraw = jsonEncode(<String, dynamic>{'data': arData});
    print(bodyraw);

    try {
      final response = await http.post(
        Uri.parse(
            'https://presensi-smp1.esolusindo.com/Api/ApiSiswa/Siswa/SyncSiswa'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: bodyraw,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['message']['status'] == 200 ||
            responseData['message']['status'] == 201) {
          final List<dynamic> users = responseData['data'];
          await dbHelper.deleteAll();

          for (var user in users) {
            await dbHelper.insert({
              DatabaseHelper.columnName: user['nama'],
              DatabaseHelper.columnNIS: user['nis'],
              DatabaseHelper.columnKelas: user['id_kelas'],
              DatabaseHelper.columnNoHpOrtu:
                  user['no_hp_ortu'], // Menyimpan No HP Orang Tua
              DatabaseHelper.columnEmbedding: user['model'],
            });
          }
        }
      } else {
        _showErrorDialog(
            'Gagal mengupload data, status: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Koneksi gagal. Pastikan Anda terhubung ke internet.');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void showSyncDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Success", textAlign: TextAlign.center),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 100),
            SizedBox(height: 20),
            Text("Berhasil Sinkronisasi", textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
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

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Kesalahan'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
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
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.red, size: 80),
            SizedBox(height: 10),
            Text(
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

  Future<void> fetchKelas() async {
    var url = Uri.parse(
        'https://presensi-smp1.esolusindo.com/Api/ApiKelas/ApiKelas/get_kelas/');
    var response = await http.get(url);
    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      if (jsonData['status'] == true) {
        setState(() {
          kelasList = jsonData['data'];
        });
      }
    }
  }

  showFaceRegistrationDialogue(Uint8List croppedFace, Recognition recognition) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Pendaftaran Wajah", textAlign: TextAlign.center),
        content: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
                horizontal:
                    16.0), // Menambah padding untuk membuat form lebih lebar
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
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.0), // Menambah padding dalam inputan
                  ),
                ),
                const SizedBox(height: 10), // Jarak antar field
                TextField(
                  controller: nisController,
                  decoration: const InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    hintText: "NIS",
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.0), // Padding di dalam input
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.0), // Padding di dalam dropdown
                  ),
                  hint: const Text("Pilih Kelas"),
                  value: selectedKelas,
                  items: kelasList.map((kelas) {
                    return DropdownMenuItem<String>(
                      value: kelas['id_kelas'],
                      child: Text(kelas['nama_kelas']),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      selectedKelas = value;
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: noHpOrtuController,
                  decoration: const InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    hintText: "No HP Orang Tua",
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 12.0), // Padding di dalam input
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedKelas != null) {
                      await registerFace(recognition);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Pilih kelas terlebih dahulu")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(200, 40),
                  ),
                  child: const Text("Register"),
                ),
              ],
            ),
          ),
        ),
        contentPadding: EdgeInsets
            .zero, // Pastikan tidak ada padding di sekitar content secara keseluruhan
      ),
    );
  }

  Future<void> registerFace(Recognition recognition) async {
    if (nameController.text.isEmpty ||
        nisController.text.isEmpty ||
        noHpOrtuController.text.isEmpty ||
        selectedKelas == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Isi dengan lengkap")),
      );
    } else if (await DatabaseHelper.instance.isNisExists(nisController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("NIS telah terdaftar")),
      );
    } else {
      recognizer.registerFaceInDB(nameController.text, nisController.text,
          selectedKelas!, noHpOrtuController.text, recognition.embeddings);

      showSuccessDialog();
    }
  }

  void showSuccessDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Success", textAlign: TextAlign.center),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 100),
            SizedBox(height: 20),
            Text("Berhasil Mendaftar", textAlign: TextAlign.center),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Tutup dialog sukses
              await syncData(); // Panggil fungsi sinkronisasi
              Navigator.pop(context); // Kembali ke halaman sebelumnya
              showSyncDialog();
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
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom:
                Radius.circular(16), // Menentukan seberapa tumpul sudut bawah
          ),
          child: AppBar(
            title: const Text(
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
                                child: Opacity(
                                  opacity: 0.3, // Menentukan opasitas gambar
                                  child: FractionallySizedBox(
                                    widthFactor:
                                        1.7, // Menentukan lebar sebagai 80% dari lebar parent
                                    heightFactor:
                                        1.7, // Menentukan tinggi sebagai 80% dari tinggi parent
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
                            if (!showPreview && _image != null)
                              Image.file(_image!),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Jarak antara preview dan tombol
                      if (showPreview)
                        Row(
                          mainAxisAlignment: MainAxisAlignment
                              .center, // Posisikan tombol di tengah
                          children: [
                            ElevatedButton(
                              onPressed: captureImage,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 20,
                                    vertical: 12), // Menambah padding
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize
                                    .min, // Agar ukuran sesuai dengan konten
                                children: [
                                  Icon(Icons.camera_alt), // Ikon kamera
                                  SizedBox(
                                      width: 8), // Jarak antara ikon dan teks
                                  Text("Ambil Gambar"),
                                ],
                              ),
                            ),

                            const SizedBox(
                                width: 10), // Jarak antara dua tombol
                            IconButton(
                              icon: const Icon(Icons.cameraswitch),
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

                      // Menampilkan tombol Capture Again hanya jika _image != null
                      if (!showPreview && _image != null)
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              showPreview = true; // Kembali ke preview kamera
                              _image = null; // Reset gambar
                            });
                          },
                          icon: const Icon(Icons.camera_alt), // Tambahkan ikon kamera
                          label: const Text("Ambil Ulang"), // Teks pada tombol
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

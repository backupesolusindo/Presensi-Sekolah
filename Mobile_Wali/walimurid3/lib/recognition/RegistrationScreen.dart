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
  bool isFrontCamera = true;
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
        'no_hp_ortu': user[DatabaseHelper.columnNoHpOrtu],
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
              DatabaseHelper.columnNoHpOrtu: user['no_hp_ortu'],
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text("Berhasil", textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF4CAF50), size: 80),
            SizedBox(height: 16),
            Text("Sinkronisasi berhasil dilakukan!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF424242),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 2,
              ),
              child: const Text("OK",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );

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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: Colors.white,
          title: const Text('Kesalahan',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFFD32F2F),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, 
                color: Color(0xFFE57373), size: 60),
              const SizedBox(height: 16),
              Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF424242),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE57373),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('OK'),
              ),
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
        showPreview = false;
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
      isLoading = true;
    });

    if (_image == null) return;

    _image = await removeRotation(_image!);
    image = await _image?.readAsBytes();
    image = await decodeImageFromList(image);
    InputImage inputImage = InputImage.fromFile(_image!);
    faces = await faceDetector.processImage(inputImage);

    setState(() {
      isLoading = false;
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
        backgroundColor: Colors.white,
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.face_retouching_off_rounded, 
              color: Color(0xFFFF7043), size: 70),
            SizedBox(height: 12),
            Text(
              "Wajah Tidak Terdeteksi",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFE65100),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        content: const Text(
          "Pastikan wajah terlihat jelas dalam kotak panduan dan pencahayaan cukup.",
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF424242),
          ),
          textAlign: TextAlign.center,
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                setState(() {
                  showPreview = true;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1976D2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 2,
              ),
              child: const Text("Coba Lagi",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text("Pendaftaran Siswa",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1976D2),
          ),
        ),
        content: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(croppedFace, width: 150, height: 150,
                      fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: "Nama Lengkap",
                      hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
                      prefixIcon: Icon(Icons.person_outline, 
                        color: Color(0xFF1976D2)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: TextField(
                    controller: nisController,
                    decoration: const InputDecoration(
                      hintText: "NIS (Nomor Induk Siswa)",
                      hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
                      prefixIcon: Icon(Icons.badge_outlined, 
                        color: Color(0xFF1976D2)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      hintText: "Pilih Kelas",
                      hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
                      prefixIcon: Icon(Icons.class_outlined, 
                        color: Color(0xFF1976D2)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    ),
                    initialValue: selectedKelas,
                    items: kelasList.map((kelas) {
                      return DropdownMenuItem<String>(
                        value: kelas['id_kelas'],
                        child: Text(kelas['nama_kelas'],
                          style: const TextStyle(color: Color(0xFF424242))),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedKelas = value;
                      });
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: TextField(
                    controller: noHpOrtuController,
                    decoration: const InputDecoration(
                      hintText: "No. HP Orang Tua",
                      hintStyle: TextStyle(color: Color(0xFF9E9E9E)),
                      prefixIcon: Icon(Icons.phone_outlined, 
                        color: Color(0xFF1976D2)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    ),
                    keyboardType: TextInputType.phone,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  height: 50,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF1976D2).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                      if (selectedKelas != null) {
                        await registerFace(recognition);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Pilih kelas terlebih dahulu"),
                            backgroundColor: Color(0xFFFF7043),
                          ),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    child: const Text("Daftarkan Siswa",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      ),
    );
  }

  Future<void> registerFace(Recognition recognition) async {
    if (nameController.text.isEmpty ||
        nisController.text.isEmpty ||
        noHpOrtuController.text.isEmpty ||
        selectedKelas == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Mohon lengkapi semua data"),
          backgroundColor: Color(0xFFFF7043),
        ),
      );
    } else if (await DatabaseHelper.instance.isNisExists(nisController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("NIS sudah terdaftar dalam sistem"),
          backgroundColor: Color(0xFFFF7043),
        ),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: const Text("Berhasil Terdaftar",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_rounded, 
              color: Color(0xFF4CAF50), size: 80),
            SizedBox(height: 16),
            Text("Siswa berhasil didaftarkan dalam sistem!",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF424242),
              ),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await syncData();
                Navigator.pop(context);
                showSyncDialog();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 2,
              ),
              child: const Text("OK",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 10),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x40000000),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              'Registrasi Wajah Siswa',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, 
                  color: Colors.white, size: 20),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ),
        ),
      ),
      resizeToAvoidBottomInset: false,
      body: isLoading
          ? Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFF8F9FA), Color(0xFFE3F2FD)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Lottie.asset('assets/loading1.json',
                              width: 120, height: 120),
                          const SizedBox(height: 20),
                          const Text(
                            'Memproses Data...',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1976D2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Mohon tunggu sebentar',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )
          : cameraController == null
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1976D2)),
                  ),
                )
              : Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFF8F9FA), Color(0xFFE3F2FD)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(25),
                            child: Stack(
                              children: [
                                if (showPreview) 
                                  SizedBox.expand(
                                    child: CameraPreview(cameraController!),
                                  ),
                                if (showPreview)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: const Color(0xFF1976D2),
                                          width: 3,
                                        ),
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                    ),
                                  ),
                                if (showPreview)
                                  Positioned.fill(
                                    child: Opacity(
                                      opacity: 0.3,
                                      child: FractionallySizedBox(
                                        widthFactor: 1.7,
                                        heightFactor: 1.7,
                                        child: Image.asset(
                                          'assets/kotakwajah.png',
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                  ),
                                Positioned.fill(
                                  child: Opacity(
                                    opacity: 1.0,
                                    child: FractionallySizedBox(
                                      widthFactor: 1.7,
                                      heightFactor: 1.7,
                                      child: Image.asset(
                                        'assets/kotaknya.png',
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                ),
                                if (!showPreview && _image != null)
                                  SizedBox.expand(
                                    child: Image.file(_image!, fit: BoxFit.cover),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(20),
                        child: showPreview
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  Container(
                                    height: 60,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                                        begin: Alignment.centerLeft,
                                        end: Alignment.centerRight,
                                      ),
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF1976D2).withOpacity(0.3),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton.icon(
                                      onPressed: captureImage,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 24,
                                          vertical: 12,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      icon: const Icon(
                                        Icons.camera_alt_rounded,
                                        color: Colors.white,
                                        size: 24,
                                      ),
                                      label: const Text(
                                        "Ambil Gambar",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Container(
                                    height: 60,
                                    width: 60,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: const Color(0xFF1976D2),
                                        width: 2,
                                      ),
                                    ),
                                    child: IconButton(
                                      icon: Icon(
                                        isFrontCamera 
                                          ? Icons.cameraswitch_rounded
                                          : Icons.camera_front_rounded,
                                        color: const Color(0xFF1976D2),
                                        size: 28,
                                      ),
                                      onPressed: () async {
                                        setState(() {
                                          isFrontCamera = !isFrontCamera;
                                        });
                                        await initializeCamera(isFrontCamera);
                                      },
                                    ),
                                  ),
                                ],
                              )
                            : Container(
                                width: double.infinity,
                                height: 60,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFFFF7043), Color(0xFFFFAB91)],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFFFF7043).withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      showPreview = true;
                                      _image = null;
                                    });
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                  ),
                                  icon: const Icon(
                                    Icons.refresh_rounded,
                                    color: Colors.white,
                                    size: 24,
                                  ),
                                  label: const Text(
                                    "Ambil Ulang",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                      ),
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
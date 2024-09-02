import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'face_recognition_service.dart';

class CameraPage extends StatefulWidget {
  final String userId;

  const CameraPage({super.key, required this.userId});

  @override
  _CameraPageState createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  late CameraController _cameraController;
  late List<CameraDescription> _cameras;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    _cameraController = CameraController(_cameras[0], ResolutionPreset.high);
    await _cameraController.initialize();
    setState(() {});
  }

  @override
  void dispose() {
    _cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      body: CameraPreview(_cameraController),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.camera),
        onPressed: () async {
          try {
            XFile picture = await _cameraController.takePicture();
            await FaceRecognitionService.recognizeFace(picture, widget.userId);
            // Navigasi ke halaman konfirmasi absensi atau tampilkan notifikasi
          } catch (e) {
            print(e);
          }
        },
      ),
    );
  }
}

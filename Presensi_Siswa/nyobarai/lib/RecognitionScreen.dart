import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:lottie/lottie.dart';
import 'package:http/http.dart' as http;
import 'package:camera/camera.dart';
import 'ML/Recognition.dart';
import 'ML/Recognizer.dart';

class RecognitionScreen extends StatefulWidget {
  const RecognitionScreen({super.key});

  @override
  State<RecognitionScreen> createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen> with TickerProviderStateMixin {
  CameraController? cameraController;
  File? _image;
  bool isLoading = false;
  bool isFrontCamera = true;
  bool showPreview = true;

  late FaceDetector faceDetector;
  late Recognizer recognizer;
  late AnimationController _pulseController;
  late AnimationController _slideController;
  late Animation<double> _pulseAnimation;
  late Animation<Offset> _slideAnimation;

  List<Recognition> recognitions = [];
  List<Face> faces = [];
  var image;
  List<String> detectedNISList = [];

  @override
  void initState() {
    super.initState();
    initializeCamera();
    
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController, 
      curve: Curves.elasticOut,
    ));

    final options = FaceDetectorOptions();
    faceDetector = FaceDetector(options: options);
    recognizer = Recognizer();
    
    _slideController.forward();
  }

  @override
  void dispose() {
    cameraController?.dispose();
    faceDetector.close();
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> initializeCamera([bool isFront = true]) async {
    final cameras = await availableCameras();
    final selectedCamera = isFront
        ? cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.front)
        : cameras.firstWhere((camera) => camera.lensDirection == CameraLensDirection.back);

    cameraController = CameraController(selectedCamera, ResolutionPreset.high);
    await cameraController?.initialize();
    setState(() {});
  }

  Future<void> captureImage() async {
    if (cameraController == null || !cameraController!.value.isInitialized) return;

    try {
      setState(() => isLoading = true);
      final XFile imageFile = await cameraController!.takePicture();
      setState(() {
        _image = File(imageFile.path);
        showPreview = false;
      });
      await doFaceDetection();
      setState(() => isLoading = false);
    } catch (e) {
      setState(() => isLoading = false);
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
        setState(() => showPreview = false);
        _showCustomDialog(
          title: 'Wajah Tidak Terdeteksi',
          message: 'Pastikan wajah terlihat jelas dan coba lagi.',
          icon: Icons.error_outline,
          iconColor: const Color(0xFFDC2626),
          onPressed: () {
            Navigator.pop(context);
            setState(() => showPreview = true);
          },
        );
        return;
      }

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

      if (detectedNISList.isEmpty) {
        _showCustomDialog(
          title: 'Gagal',
          message: 'Wajah tidak dikenali',
          icon: Icons.error,
          iconColor: const Color(0xFFDC2626),
          onPressed: () => Navigator.pop(context),
        );
      } else {
        drawRectangleAroundFaces();
      }
    }
  }

  Future<File> removeRotation(File inputImage) async {
    final img.Image? capturedImage = img.decodeImage(await File(inputImage.path).readAsBytes());
    if (capturedImage != null) {
      final img.Image orientedImage = img.bakeOrientation(capturedImage);
      return await File(_image!.path).writeAsBytes(img.encodeJpg(orientedImage));
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
      _showCustomDialog(
        title: 'Gagal',
        message: 'Wajah tidak terdeteksi, coba foto lagi',
        icon: Icons.error,
        iconColor: const Color(0xFFDC2626),
        onPressed: () => Navigator.pop(context),
      );
      return;
    }

    for (Recognition rectangle in recognitions) {
      if (rectangle.name == "Tidak dikenali") {
        _showCustomDialog(
          title: 'Gagal',
          message: 'Wajah belum terdaftar',
          icon: Icons.error,
          iconColor: const Color(0xFFDC2626),
          onPressed: () => Navigator.pop(context),
        );
        return;
      } else {
        const url = 'https://presensi-smp1.esolusindo.com/Api/ApiGerbang/Gerbang/uploadAbsen';
        final response = await http.post(
          Uri.parse(url),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({'nis': rectangle.nis, 'status': 'Hadir'}),
        );

        if (response.statusCode != 200) {
          _showCustomDialog(
            title: 'Gagal',
            message: 'Gagal presensi untuk ${rectangle.name}',
            icon: Icons.error,
            iconColor: const Color(0xFFDC2626),
            onPressed: () => Navigator.pop(context),
          );
        }
      }
    }

    _showCustomDialog(
      title: 'Sukses',
      message: 'Presensi Berhasil',
      icon: Icons.check_circle,
      iconColor: const Color(0xFF059669),
      onPressed: () => Navigator.pop(context),
    );
    detectedNISList.clear();
  }

  void _showCustomDialog({
    required String title,
    required String message,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFF8FAFC)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 48),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF6B7280),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [iconColor, iconColor.withOpacity(0.8)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextButton(
                  onPressed: onPressed,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'OK',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            ),
          ),
          child: AppBar(
            title: const Text(
              'Presensi Wajah',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
            centerTitle: true,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Image.asset('assets/logoSMP.png'),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
          ),
        ),
      ),
      body: Column(
        children: [
          if (isLoading)
            Expanded(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.0,
                    colors: [
                      Color(0xFF1E3A8A),
                      Color(0xFF0F172A),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.2)),
                        ),
                        child: Lottie.asset(
                          "assets/loading1.json",
                          width: 100,
                          height: 100,
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Memproses...',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (cameraController != null &&
              cameraController!.value.isInitialized &&
              showPreview)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CameraPreview(cameraController!),
                      ),
                      // Face detection overlay
                      Positioned.fill(
                        child: AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Opacity(
                                opacity: 0.4,
                                child: Image.asset(
                                  'assets/kotakwajah.png',
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned.fill(
                        child: Image.asset(
                          'assets/kotaknya.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      // Corner decorations
                      Positioned(
                        top: 20,
                        left: 20,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.white.withOpacity(0.8), width: 3),
                              left: BorderSide(color: Colors.white.withOpacity(0.8), width: 3),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 20,
                        right: 20,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Colors.white.withOpacity(0.8), width: 3),
                              right: BorderSide(color: Colors.white.withOpacity(0.8), width: 3),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        left: 20,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.white.withOpacity(0.8), width: 3),
                              left: BorderSide(color: Colors.white.withOpacity(0.8), width: 3),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 20,
                        right: 20,
                        child: Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: Colors.white.withOpacity(0.8), width: 3),
                              right: BorderSide(color: Colors.white.withOpacity(0.8), width: 3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else if (!showPreview && _image != null)
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: FittedBox(
                    fit: BoxFit.cover,
                    child: SizedBox(
                      width: image.width.toDouble(),
                      height: image.height.toDouble(),
                      child: CustomPaint(
                        painter: FacePainter(facesList: recognitions, imageFile: image),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          
          // Bottom Controls
          SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFF1E293B),
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
              ),
              child: showPreview ? _buildCameraControls() : _buildResultControls(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Switch camera button
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: IconButton(
            icon: const Icon(Icons.cameraswitch, color: Colors.white, size: 28),
            onPressed: () async {
              setState(() => isFrontCamera = !isFrontCamera);
              await initializeCamera(isFrontCamera);
            },
          ),
        ),
        
        // Capture button
        GestureDetector(
          onTap: captureImage,
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(
              Icons.camera_alt,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        
        // Settings placeholder (can be used for flash, etc.)
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.2)),
          ),
          child: IconButton(
            icon: const Icon(Icons.settings, color: Colors.white, size: 28),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildResultControls() {
    if (detectedNISList.isEmpty) return Container();
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: TextButton.icon(
              onPressed: () => setState(() => showPreview = true),
              icon: const Icon(Icons.refresh, color: Colors.white),
              label: const Text(
                'Ambil Ulang',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF059669), Color(0xFF047857)],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF059669).withOpacity(0.5),
                  blurRadius: 15,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: TextButton.icon(
              onPressed: verifyAttendance,
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text(
                'Verifikasi',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class FacePainter extends CustomPainter {
  List<Recognition> facesList;
  dynamic imageFile;

  FacePainter({required this.facesList, required this.imageFile});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile, Offset.zero, Paint());
    }

    Paint p = Paint();
    p.color = const Color(0xFF10B981);
    p.style = PaintingStyle.stroke;
    p.strokeWidth = 4;

    for (Recognition rectangle in facesList) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rectangle.location, const Radius.circular(12)),
        p,
      );

      if (rectangle.name == "Tidak dikenali") {
        _drawTextWithBackground(
          canvas,
          "Wajah Tidak Dikenali",
          rectangle.location.left,
          rectangle.location.top - 80,
          const Color(0xFFDC2626),
        );
      } else {
        String text = "${rectangle.name} ${(rectangle.confidence).toStringAsFixed(1)}%";
        _drawTextWithBackground(
          canvas,
          text,
          rectangle.location.left,
          rectangle.location.top - 80,
          const Color(0xFF10B981),
        );
      }
    }
  }

  void _drawTextWithBackground(Canvas canvas, String text, double x, double y, Color color) {
    TextSpan span = TextSpan(
      style: TextStyle(
        color: Colors.white,
        fontSize: 24,
        fontWeight: FontWeight.bold,
        shadows: [
          Shadow(
            blurRadius: 4,
            color: Colors.black.withOpacity(0.5),
            offset: const Offset(1, 1),
          ),
        ],
      ),
      text: text,
    );

    TextPainter tp = TextPainter(
      text: span,
      textAlign: TextAlign.left,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '...',
    );
    tp.layout(maxWidth: 400);

    Paint backgroundPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    double padding = 12;
    RRect backgroundRect = RRect.fromLTRBR(
      x - padding,
      y - padding,
      x + tp.width + padding,
      y + tp.height + padding,
      const Radius.circular(8),
    );
    canvas.drawRRect(backgroundRect, backgroundPaint);

    tp.paint(canvas, Offset(x, y));
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
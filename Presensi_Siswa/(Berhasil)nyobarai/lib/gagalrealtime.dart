import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'ML/Recognition.dart';
import 'ML/Recognizer.dart';
import 'main.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;

class RecognitionScreen extends StatefulWidget {
  RecognitionScreen({Key? key}) : super(key: key);

  @override
  _RecognitionScreenState createState() => _RecognitionScreenState();
}

class _RecognitionScreenState extends State<RecognitionScreen> {
  dynamic controller;
  bool isBusy = false;
  late Size size;
  late CameraDescription description;
  CameraLensDirection camDirec = CameraLensDirection.front;
  late List<Recognition> recognitions = [];

  late FaceDetector faceDetector;
  late Recognizer recognizer;
  List<CameraDescription> cameras = [];

  @override
  void initState() {
    super.initState();
    initializeCameras().then((_) {
      setState(() {
        description = cameras[1];
        initializeCamera();
      });
    });

    var options = FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate);
    faceDetector = FaceDetector(options: options);
    recognizer = Recognizer();
  }

  Future<void> initializeCameras() async {
    cameras = await availableCameras();
  }

  initializeCamera() async {
    controller = CameraController(description, ResolutionPreset.medium,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
        enableAudio: false);
    await controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      controller.startImageStream((image) {
        if (!isBusy) {
          isBusy = true;
          frame = image;
          doFaceDetectionOnFrame();
        }
      });
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  dynamic _scanResults;
  CameraImage? frame;

  doFaceDetectionOnFrame() async {
    InputImage inputImage = _inputImageFromCameraImage(frame!)!;
    List<Face> faces = await faceDetector.processImage(inputImage);

    print("fl=" + faces.length.toString());
    performFaceRecognition(faces);
  }

  img.Image? image;
  bool register = false;

  performFaceRecognition(List<Face> faces) async {
    recognitions.clear();

    image = Platform.isIOS
        ? _convertBGRA8888ToImage(frame!) as img.Image?
        : _convertNV21(frame!);
    image = img.copyRotate(image!,
        angle: camDirec == CameraLensDirection.front ? 270 : 90);

    for (Face face in faces) {
      Rect faceRect = face.boundingBox;
      img.Image croppedFace = img.copyCrop(image!,
          x: faceRect.left.toInt(),
          y: faceRect.top.toInt(),
          width: faceRect.width.toInt(),
          height: faceRect.height.toInt());

      Recognition recognition = recognizer.recognize(croppedFace, faceRect);
      if (recognition.distance > 1.25) {
        recognition.name = "Unknown";
      }
      recognitions.add(recognition);

      if (register) {
        showFaceRegistrationDialogue(croppedFace, recognition);
        register = false;
      }
    }

    setState(() {
      isBusy = false;
      _scanResults = recognitions;
    });
  }

  TextEditingController textEditingController = TextEditingController();

  showFaceRegistrationDialogue(img.Image croppedFace, Recognition recognition) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Face Registration", textAlign: TextAlign.center),
        alignment: Alignment.center,
        content: SizedBox(
          height: 340,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(
                height: 20,
              ),
              Image.memory(
                Uint8List.fromList(img.encodeBmp(croppedFace)),
                width: 200,
                height: 200,
              ),
              SizedBox(
                width: 200,
                child: TextField(
                    controller: textEditingController,
                    decoration: const InputDecoration(
                        fillColor: Colors.white,
                        filled: true,
                        hintText: "Enter Name")),
              ),
              const SizedBox(
                height: 10,
              ),
              ElevatedButton(
                  onPressed: () {
                    recognizer.registerFaceInDB(
                        textEditingController.text, 
                        recognition.embeddings,
                        "generated_id", // Example ID
                        "generated_nis" // Example NIS
                    );
                    textEditingController.text = "";
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text("Face Registered"),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      minimumSize: const Size(200, 40)),
                  child: const Text("Register"))
            ],
          ),
        ),
        contentPadding: EdgeInsets.zero,
      ),
    );
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final WriteBuffer allBytes = WriteBuffer();
    for (Plane plane in image.planes) {
      allBytes.putUint8List(plane.bytes);
    }
    final bytes = allBytes.done().buffer.asUint8List();
    final size = Size(image.width.toDouble(), image.height.toDouble());

    final imageFormat = InputImageFormatValue.fromRawValue(image.format.raw);
    final planeData = image.planes.map((plane) {
      return InputImagePlaneMetadata(
        height: plane.height,
        width: plane.width,
        rowStride: plane.rowStride,
        pixelStride: plane.pixelStride,
      );
    }).toList();

    return InputImage.fromBytes(
      bytes: bytes,
      inputImageData: InputImageData(
        size: size,
        imageRotation: InputImageRotation.rotation270deg,
        inputImageFormat: imageFormat,
        planeData: planeData,
      ),
    );
  }

  img.Image _convertBGRA8888ToImage(CameraImage image) {
    // Implementasi konversi BGRA8888 ke img.Image
  }

  img.Image _convertNV21(CameraImage image) {
    // Implementasi konversi NV21 ke img.Image
  }

  @override
  Widget build(BuildContext context) {
    size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recognition'),
      ),
      body: Column(
        children: [
          Container(
            width: size.width,
            height: size.width * 4 / 3,
            child: CameraPreview(controller),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: recognitions.length,
              itemBuilder: (context, index) {
                final recognition = recognitions[index];
                return ListTile(
                  title: Text('${recognition.name} - ${recognition.distance.toStringAsFixed(2)}'),
                  subtitle: Text('Location: ${recognition.location}'),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

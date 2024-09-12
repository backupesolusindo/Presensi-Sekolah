import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'ML/Recognition.dart';
import 'ML/Recognizer.dart';

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
  TextEditingController textEditingController = TextEditingController();

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
    XFile? pickedFile = await imagePicker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
        doFaceDetection();
      });
    }
  }

  doFaceDetection() async {
    if (_image == null) return;

    _image = await removeRotation(_image!);
    image = await _image?.readAsBytes();
    image = await decodeImageFromList(image);
    InputImage inputImage = InputImage.fromFile(_image!);
    faces = await faceDetector.processImage(inputImage);

    if (faces.isNotEmpty) {
      for (Face face in faces) {
        Rect faceRect = face.boundingBox;
        num left = faceRect.left < 0 ? 0 : faceRect.left;
        num top = faceRect.top < 0 ? 0 : faceRect.top;
        num right = faceRect.right > image.width ? image.width - 1 : faceRect.right;
        num bottom = faceRect.bottom > image.height ? image.height - 1 : faceRect.bottom;
        num width = right - left;
        num height = bottom - top;

        final bytes = _image!.readAsBytesSync();
        img.Image? faceImg = img.decodeImage(bytes);
        img.Image croppedFace = img.copyCrop(faceImg!, x: left.toInt(), y: top.toInt(), width: width.toInt(), height: height.toInt());

        Recognition recognition = recognizer.recognize(croppedFace, faceRect);
        showFaceRegistrationDialogue(Uint8List.fromList(img.encodeBmp(croppedFace)), recognition);
      }
    }
    drawRectangleAroundFaces();
  }

  showFaceRegistrationDialogue(Uint8List croppedFace, Recognition recognition) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Face Registration", textAlign: TextAlign.center),
        content: SizedBox(
          height: 340,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Image.memory(croppedFace, width: 200, height: 200),
              SizedBox(
                width: 200,
                child: TextField(
                  controller: textEditingController,
                  decoration: const InputDecoration(
                    fillColor: Colors.white,
                    filled: true,
                    hintText: "Enter Name",
                  ),
                ),
              ),
              const SizedBox(height: 10),
              ElevatedButton(
                onPressed: () {
                  recognizer.registerFaceInDB(
                      textEditingController.text, recognition.embeddings);
                  textEditingController.clear();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Face Registered")));
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue, minimumSize: const Size(200, 40)),
                child: const Text("Register"),
              )
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
    final img.Image? capturedImage = img.decodeImage(await File(inputImage.path).readAsBytes());
    final img.Image orientedImage = img.bakeOrientation(capturedImage!);
    return await File(_image!.path).writeAsBytes(img.encodeJpg(orientedImage));
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          image != null
              ? Container(
                  margin: const EdgeInsets.only(top: 60, left: 30, right: 30),
                  child: FittedBox(
                    child: SizedBox(
                      width: image.width.toDouble(),
                      height: image.width.toDouble(),
                      child: CustomPaint(
                        painter: FacePainter(facesList: faces, imageFile: image),
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
          const SizedBox(height: 50),
          Container(
            margin: const EdgeInsets.only(bottom: 50),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildIconButton(
                    screenWidth, Icons.image, "Pick from Gallery", _imgFromGallery),
                _buildIconButton(
                    screenWidth, Icons.camera, "Capture Image", _imgFromCamera),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildIconButton(double screenWidth, IconData icon, String label, Function onTap) {
    return Card(
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(200))),
      child: InkWell(
        onTap: () => onTap(),
        child: SizedBox(
          width: screenWidth / 2 - 70,
          height: screenWidth / 2 - 70,
          child: Icon(icon, color: Colors.blue, size: screenWidth / 7),
        ),
      ),
    );
  }
}

class FacePainter extends CustomPainter {
  List<Face> facesList;
  dynamic imageFile;

  FacePainter({required this.facesList, this.imageFile});

  @override
  void paint(Canvas canvas, Size size) {
    if (imageFile != null) {
      canvas.drawImage(imageFile, Offset.zero, Paint());
    }

    Paint p = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    for (Face face in facesList) {
      canvas.drawRect(face.boundingBox, p);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}

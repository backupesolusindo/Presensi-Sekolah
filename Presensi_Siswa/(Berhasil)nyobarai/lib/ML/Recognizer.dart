import 'dart:math';
import 'dart:typed_data';
import 'dart:ui';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import '../DB/DatabaseHelper.dart';
import 'Recognition.dart';

class Recognizer {
  late Interpreter interpreter;
  late InterpreterOptions _interpreterOptions;
  static const int WIDTH = 112;
  static const int HEIGHT = 112;
  final dbHelper = DatabaseHelper.instance; // Instance database helper
  Map<String, Recognition> registered = Map();

  // Nama model
  String get modelName => 'assets/mobile_face_net.tflite';
  double threshold = 0.8; // Contoh ambang batas, dapat diubah sesuai kebutuhan
  // Konstruktor
  Recognizer({int? numThreads}) {
    _interpreterOptions = InterpreterOptions();

    if (numThreads != null) {
      _interpreterOptions.threads = numThreads;
    }
    loadModel();
    loadRegisteredFaces(); // Mengambil wajah yang terdaftar saat inisialisasi
  }

  // Memuat wajah yang terdaftar dari database
  void loadRegisteredFaces() async {
    final allRows = await dbHelper.queryAllRows();
    for (final row in allRows) {
      String name = row[DatabaseHelper.columnName];
      String nis = row[DatabaseHelper.columnNIS]; // Ambil NIS dari database
      String kelas =
          row[DatabaseHelper.columnKelas]; // Ambil Kelas dari database
      List<double> embd = row[DatabaseHelper.columnEmbedding]
          .split(',')
          .map((e) => double.parse(e))
          .toList()
          .cast<double>();

      // Masukkan NIS dan Kelas ke dalam objek Recognition
      Recognition recognition =
          Recognition(name, Rect.zero, embd, 0, 0, nis, kelas);
      registered.putIfAbsent(name, () => recognition);
    }
  }

  // Mendaftarkan wajah ke database
  void registerFaceInDB(
      String name, String nis, String kelas, List<double> embedding) async {
    // row to insert
    Map<String, dynamic> row = {
      DatabaseHelper.columnName: name,
      DatabaseHelper.columnNIS: nis, // Menambahkan NIS
      DatabaseHelper.columnKelas: kelas, // Menambahkan Kelas
      DatabaseHelper.columnEmbedding: embedding.join(",")
    };
    final id = await dbHelper.insert(row);
    print('inserted row id: $id');
  }

  // Memuat model TensorFlow Lite
  Future<void> loadModel() async {
    try {
      interpreter = await Interpreter.fromAsset(modelName);
    } catch (e) {
      print('Unable to create interpreter, Caught Exception: ${e.toString()}');
    }
  }

  // Mengubah gambar menjadi array
  List<dynamic> imageToArray(img.Image inputImage) {
    img.Image resizedImage =
        img.copyResize(inputImage, width: WIDTH, height: HEIGHT);
    List<double> flattenedList = resizedImage.data!
        .expand((channel) => [channel.r, channel.g, channel.b])
        .map((value) => value.toDouble())
        .toList();
    Float32List float32Array = Float32List.fromList(flattenedList);
    int channels = 3;
    int height = HEIGHT;
    int width = WIDTH;
    Float32List reshapedArray = Float32List(1 * height * width * channels);
    for (int c = 0; c < channels; c++) {
      for (int h = 0; h < height; h++) {
        for (int w = 0; w < width; w++) {
          int index = c * height * width + h * width + w;
          reshapedArray[index] =
              (float32Array[c * height * width + h * width + w] - 127.5) /
                  127.5;
        }
      }
    }
    return reshapedArray.reshape([1, 112, 112, 3]);
  }

  // Mengenali wajah
  Recognition recognize(img.Image image, Rect location) {
    var input = imageToArray(image);
    print(input.shape.toString());

    // Output array
    List output = List.filled(1 * 192, 0).reshape([1, 192]);

    // Melakukan inferensi
    final runs = DateTime.now().millisecondsSinceEpoch;
    interpreter.run(input, output);
    final run = DateTime.now().millisecondsSinceEpoch - runs;
    print('Time to run inference: $run ms$output');

    // Mengonversi output ke list double
    List<double> outputArray = output.first.cast<double>();

    // Mencari embedding terdekat di database
    Pair pair = findNearest(outputArray);
    print("distance= ${pair.distance}");

    // Jika "Tidak dikenali", set distance = 1 (100% tidak dikenali)
    double confidence;
    if (pair.name == "Tidak dikenali") {
      confidence = 0.0; // Set confidence to 0% if not recognized
      return Recognition(pair.name, location, outputArray, pair.distance,
          confidence, '', ''); // Jika tidak dikenali, NIS dan kelas kosong
    } else {
      // Hitung confidence sebagai kebalikan dari jarak, jika dikenali
      confidence = (1.0 - (pair.distance / threshold)) * 100;

      // Ambil data NIS dan kelas dari registered map
      Recognition registeredRecognition = registered[pair.name]!;
      return Recognition(pair.name, location, outputArray, pair.distance,
          confidence, registeredRecognition.nis, registeredRecognition.kelas);
    }
  }

  // Mencari embedding terdekat
  Pair findNearest(List<double> emb) {
    Pair pair = Pair("Tidak dikenali", double.infinity);
    for (MapEntry<String, Recognition> item in registered.entries) {
      final String name = item.key;
      List<double> knownEmb = item.value.embeddings;
      double distance = 0;
      for (int i = 0; i < emb.length; i++) {
        double diff = emb[i] - knownEmb[i];
        distance += diff * diff;
      }
      distance = sqrt(distance);
      if (distance < pair.distance) {
        pair.distance = distance;
        pair.name = name;
      }
    }
    if (pair.distance > threshold) {
      pair.name = "Tidak dikenali";
    }
    return pair;
  }

  // Menutup interpreter
  void close() {
    interpreter.close();
  }
}

// Kelas untuk pasangan nama dan jarak
class Pair {
  String name;
  double distance;
  Pair(this.name, this.distance);
}

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'vision_detector_views/face_detector_view.dart';

class RegisterFacePage extends StatefulWidget {
  @override
  _RegisterFacePageState createState() => _RegisterFacePageState();
}

class _RegisterFacePageState extends State<RegisterFacePage> {
  final _formKey = GlobalKey<FormState>();
  String? _name, _class, _nis;
  List<double>? _faceData; // Data wajah yang dipindai
  bool _isFaceScanned = false; // Status apakah wajah sudah dipindai

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrasi Wajah'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Nama'),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Nama harus diisi';
                      }
                      return null;
                    },
                    onSaved: (value) => _name = value,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'Kelas'),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Kelas harus diisi';
                      }
                      return null;
                    },
                    onSaved: (value) => _class = value,
                  ),
                  TextFormField(
                    decoration: InputDecoration(labelText: 'NIS'),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'NIS harus diisi';
                      }
                      return null;
                    },
                    onSaved: (value) => _nis = value,
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _registerFace, // Tombol untuk scan wajah
              child: Text('Scan Wajah'),
            ),
            SizedBox(height: 20),
            // Menampilkan data wajah jika sudah dipindai
            if (_isFaceScanned)
              Column(
                children: [
                  Text(
                    'Face = ${_faceData.toString()}',
                    style: TextStyle(
                        color: Colors.green, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed:
                        _saveToDatabase, // Tombol untuk menyimpan data ke Firebase
                    child: Text('Simpan Data Wajah'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _registerFace() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Navigasi ke halaman deteksi wajah
      final faceData = await Navigator.push<List<double>>(
        context,
        MaterialPageRoute(
          builder: (context) =>
              FaceDetectorView(), // Panggil FaceDetectorView untuk mendeteksi wajah
        ),
      );

      // Jika wajah berhasil dipindai, simpan datanya
      if (faceData != null) {
        setState(() {
          _faceData = faceData;
          _isFaceScanned = true;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Wajah berhasil dipindai!')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pindai wajah gagal. Coba lagi.')),
        );
      }
    }
  }

  Future<void> _saveToDatabase() async {
    if (_faceData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                'Data wajah belum ada, silakan scan wajah terlebih dahulu.')),
      );
      return;
    }

    // Simpan data ke Firebase Database
    final databaseRef = FirebaseDatabase.instance.ref('students');
    final newStudentRef = databaseRef.push(); // Buat ID baru

    await newStudentRef.set({
      'id': newStudentRef.key,
      'name': _name,
      'class': _class,
      'nis': _nis,
      'faceData': _faceData, // Simpan fitur wajah sebagai data numerik
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registrasi wajah berhasil!')),
    );

    // Reset status setelah data berhasil disimpan
    setState(() {
      _isFaceScanned = false;
      _faceData = null;
    });
  }
}

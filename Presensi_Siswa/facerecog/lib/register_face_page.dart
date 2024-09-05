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
  List<Map<String, dynamic>>? _faceData; // Data wajah dari deteksi
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
              onPressed: _registerFace,
              child: Text('Scan Wajah'),
            ),
            SizedBox(height: 20),
            // Tombol ini akan muncul setelah wajah berhasil dipindai
            if (_isFaceScanned)
              ElevatedButton(
                onPressed: _saveToDatabase,
                child: Text('Simpan Data Wajah'),
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
      final faceData = await Navigator.push<List<Map<String, dynamic>>>(
        context,
        MaterialPageRoute(
          builder: (context) => FaceDetectorView(),
        ),
      );

      if (faceData != null && faceData.isNotEmpty) {
        setState(() {
          _faceData = faceData; // Simpan data hasil deteksi wajah
          _isFaceScanned = true; // Tandai bahwa wajah sudah dipindai
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
      SnackBar(content: Text('Data wajah belum ada, silakan scan wajah terlebih dahulu.')),
    );
    return;
  }

  try {
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

    // Tambahkan log untuk memastikan bahwa data terkirim
    print('Data berhasil dikirim ke Firebase');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registrasi wajah berhasil!')),
    );
  } catch (e) {
    print('Gagal menyimpan data: $e'); // Tambahkan log untuk menangkap error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Gagal menyimpan data. Coba lagi.')),
    );
  }

  // Reset status setelah data berhasil disimpan
  setState(() {
    _isFaceScanned = false;
    _faceData = null;
  });
}

}

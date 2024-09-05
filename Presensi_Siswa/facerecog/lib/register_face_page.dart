import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'vision_detector_views/face_mesh_detector_view.dart'; // Sesuaikan dengan path baru

class RegisterFacePage extends StatefulWidget {
  @override
  _RegisterFacePageState createState() => _RegisterFacePageState();
}

class _RegisterFacePageState extends State<RegisterFacePage> {
  final _formKey = GlobalKey<FormState>();
  String? _name, _class, _nis;
  List<double>? _faceData; // Data wajah dari deteksi mesh

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrasi Wajah'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
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
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _registerFace,
                child: Text('Registrasi Wajah'),
              ),
            ],
          ),
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
          builder: (context) => FaceMeshDetectorView(),
        ),
      );

      if (faceData != null) {
        _faceData = faceData;
        await _saveToDatabase();
      }
    }
  }

  Future<void> _saveToDatabase() async {
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
  }
}

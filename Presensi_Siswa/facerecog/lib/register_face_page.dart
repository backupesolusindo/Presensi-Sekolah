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
        title: Text(
          'Registrasi Wajah',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF0060B3), Color(0xFF0A3B67)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF81C6FF), Color(0xFF0A3B67)],
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Card untuk form input
              Container(
                width: double.infinity,
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  margin: EdgeInsets.symmetric(horizontal: 30),
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        _buildTextFormField('Nama', (value) => _name = value),
                        _buildTextFormField('Kelas', (value) => _class = value),
                        _buildTextFormField('NIS', (value) => _nis = value),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),
              // Kolom Scan Wajah dengan desain yang menarik
              if (_isFaceScanned)
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF81C6FF), Color(0xFF0A3B67)],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.6),
                        spreadRadius: 3,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Face Data: ${_faceData.toString()}',
                        style: TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _saveToDatabase,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 10),
                          backgroundColor: Colors.deepOrangeAccent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          'Simpan Data Wajah',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(height: 20),
              // Tombol Scan Wajah dengan desain modern
              ElevatedButton(
                onPressed: _registerFace,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  backgroundColor: Color(0xFF1ED384),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'Scan Wajah',
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextFormField _buildTextFormField(
      String label, FormFieldSetter<String>? onSaved) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: (value) {
        if (value!.isEmpty) {
          return '$label harus diisi';
        }
        return null;
      },
      onSaved: onSaved,
    );
  }

  Future<void> _registerFace() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      final faceData = await Navigator.push<List<double>>(
        context,
        MaterialPageRoute(
          builder: (context) => FaceDetectorView(),
        ),
      );

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
        SnackBar(content: Text('Data wajah belum ada, silakan scan wajah terlebih dahulu.')),
      );
      return;
    }

    final databaseRef = FirebaseDatabase.instance.ref('students');
    final newStudentRef = databaseRef.push();

    await newStudentRef.set({
      'id': newStudentRef.key,
      'name': _name,
      'class': _class,
      'nis': _nis,
      'faceData': _faceData,
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Registrasi wajah berhasil!')),
    );

    setState(() {
      _isFaceScanned = false;
      _faceData = null;
    });
  }
}

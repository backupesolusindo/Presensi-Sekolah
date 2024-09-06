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
  List<double>? _faceData;
  bool _isFaceScanned = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrasi Wajah'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color.fromARGB(255, 129, 198, 255),
                const Color.fromARGB(255, 10, 59, 103),
              ],
            ),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color.fromARGB(255, 129, 198, 255),
              const Color.fromARGB(255, 10, 59, 103),
            ],
          ),
        ),
        padding: EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                'Isi Data Diri dan Scan Wajah',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 20),
              Form(
                key: _formKey,
                child: Column(
                  children: [
                    _buildTextField('Nama', (value) => _name = value),
                    _buildTextField('Kelas', (value) => _class = value),
                    _buildTextField('NIS', (value) => _nis = value),
                  ],
                ),
              ),
              SizedBox(height: 20),
              _buildGradientButton('Scan Wajah', _registerFace),
              if (_isFaceScanned) ...[
                SizedBox(height: 20),
                Text(
                  'Face Data: ${_faceData.toString()}',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 20),
                _buildGradientButton('Simpan Data Wajah', _saveToDatabase),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(String labelText, Function(String?) onSaved) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.white),
        filled: true,
        fillColor: Colors.white.withOpacity(0.2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
        ),
      ),
      validator: (value) {
        if (value!.isEmpty) return '$labelText harus diisi';
        return null;
      },
      onSaved: onSaved,
    );
  }

  Widget _buildGradientButton(String text, VoidCallback onPressed) {
    return Container(
      height: 45,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color.fromARGB(255, 129, 198, 255),
            const Color.fromARGB(255, 10, 59, 103),
          ],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.5),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
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

    final databaseRef = FirebaseDatabase.instance.ref('murid');
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
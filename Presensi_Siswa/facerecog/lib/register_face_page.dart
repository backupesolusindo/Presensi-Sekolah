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
            fontWeight: FontWeight.bold, // Membuat teks tebal
            color: Colors.white, // Mengatur warna teks menjadi putih
          ),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color.fromARGB(255, 0, 96, 179),
                const Color.fromARGB(255, 10, 59, 103),
              ],
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
            colors: [
              const Color.fromARGB(255, 129, 198, 255),
              const Color.fromARGB(255, 10, 59, 103),
            ],
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
              // Kolom Scan Wajah di luar Card dengan warna gradasi dan bayangan
              if (_isFaceScanned)
                Container(
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
                        color:
                            const Color.fromARGB(255, 0, 0, 0).withOpacity(0.6),
                        spreadRadius: 3,
                        blurRadius: 10,
                        offset:
                            Offset(0, 5), // Efek bayangan lebih besar ke bawah
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
              // Tombol Scan Wajah
              ElevatedButton(
                onPressed: _confirmAndRegisterFace,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  backgroundColor: const Color.fromARGB(255, 30, 211, 132),
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
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value!.isEmpty) {
          return '$label harus diisi';
        }
        return null;
      },
      onSaved: onSaved,
    );
  }

  Future<void> _confirmAndRegisterFace() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      // Tampilkan dialog konfirmasi
      bool? confirm = await showDialog<bool>(
        context: context,
        barrierDismissible:
            false, // Tidak bisa menutup dialog dengan tap di luar
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Konfirmasi'),
            content: Text(
                'Apakah data yang dimasukkan benar dan siap untuk dipindai?'),
            actions: [
              TextButton(
                child: Text('Batal'),
                onPressed: () => Navigator.of(context).pop(false),
              ),
              TextButton(
                child: Text('Ya'),
                onPressed: () => Navigator.of(context).pop(true),
              ),
            ],
          );
        },
      );

      if (confirm == true) {
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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Silakan isi semua data sebelum melanjutkan.')),
      );
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

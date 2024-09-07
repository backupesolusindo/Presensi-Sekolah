import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_fonts/google_fonts.dart';

class SubjectPage extends StatefulWidget {
  @override
  _SubjectPageState createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  final DatabaseReference _subjectRef =
      FirebaseDatabase.instance.reference().child('subjects');
  TextEditingController _searchController = TextEditingController();
  TextEditingController _nameController = TextEditingController();
  TextEditingController _classController = TextEditingController();
  TextEditingController _codeController = TextEditingController();
  List<dynamic> subjects = [];
  List<dynamic> filteredSubjects = [];
  String? _selectedSubjectId;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  void _loadSubjects() {
    _subjectRef.onValue.listen((event) {
      final data = Map<dynamic, dynamic>.from(event.snapshot.value as Map);
      setState(() {
        subjects = data.values.toList();
        filteredSubjects = subjects;
      });
    });
  }

  void _filterSubjects(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredSubjects = subjects;
      });
    } else {
      setState(() {
        filteredSubjects = subjects
            .where((subject) => subject['name']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  void _addSubject() {
    String id = _subjectRef.push().key!;
    _subjectRef.child(id).set({
      'id': id,
      'name': _nameController.text,
      'class': _classController.text,
      'class_code': _codeController.text,
      'image_url': generateImageUrl(id)
    }).then((_) {
      _nameController.clear();
      _classController.clear();
      _codeController.clear();
      Navigator.of(context).pop();
    });
  }

  void _updateSubject() {
    if (_selectedSubjectId != null) {
      _subjectRef.child(_selectedSubjectId!).update({
        'name': _nameController.text,
        'class': _classController.text,
        'class_code': _codeController.text,
      }).then((_) {
        _nameController.clear();
        _classController.clear();
        _codeController.clear();
        Navigator.of(context).pop();
        _selectedSubjectId = null;
      });
    }
  }

  void _deleteSubject(String id) {
    _subjectRef.child(id).remove().then((_) {
      Navigator.of(context).pop();
    });
  }

  void _showAddSubjectDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon di bagian atas dialog
                Icon(
                  Icons.school,
                  color: Colors.teal,
                  size: 60,
                ),
                SizedBox(height: 20),
                Text(
                  'Tambah Mata Pelajaran',
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(height: 20),
                // Input Nama Mata Pelajaran
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Mata Pelajaran',
                    labelStyle: GoogleFonts.raleway(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  style: GoogleFonts.raleway(),
                ),
                SizedBox(height: 10),
                // Input Kelas
                TextField(
                  controller: _classController,
                  decoration: InputDecoration(
                    labelText: 'Kelas',
                    labelStyle: GoogleFonts.raleway(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  style: GoogleFonts.raleway(),
                ),
                SizedBox(height: 10),
                // Input Tahun Ajaran
                TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Tahun Ajaran',
                    labelStyle: GoogleFonts.raleway(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  style: GoogleFonts.raleway(),
                ),
                SizedBox(height: 20),
                // Tombol Aksi
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.raleway(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _addSubject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        'Tambah',
                        style: GoogleFonts.raleway(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditSubjectDialog(String id, String name, String classInfo, String code) {
    _selectedSubjectId = id;
    _nameController.text = name;
    _classController.text = classInfo;
    _codeController.text = code;
    
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit, size: 60, color: Colors.teal), // Ikon Edit
                SizedBox(height: 20),
                Text(
                  'Edit Mata Pelajaran',
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(height: 20),
                // Input Nama Mata Pelajaran
                TextField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Nama Mata Pelajaran',
                    labelStyle: GoogleFonts.raleway(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  style: GoogleFonts.raleway(),
                ),
                SizedBox(height: 10),
                // Input Kelas
                TextField(
                  controller: _classController,
                  decoration: InputDecoration(
                    labelText: 'Kelas',
                    labelStyle: GoogleFonts.raleway(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  style: GoogleFonts.raleway(),
                ),
                SizedBox(height: 10),
                // Input Tahun Ajaran
                TextField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Tahun Ajaran',
                    labelStyle: GoogleFonts.raleway(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  style: GoogleFonts.raleway(),
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.raleway(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _updateSubject,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.teal,
                        padding: EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        'Simpan',
                        style: GoogleFonts.raleway(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSubjectOptionsDialog(String id, String name, String classInfo, String code) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title dialog
                Text(
                  '',
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.teal,
                  ),
                ),
                SizedBox(height: 20),
                // Pilihan Edit dengan Icon
                ListTile(
                  leading: Icon(Icons.edit, color: Colors.teal, size: 30),
                  title: Text(
                    'Edit Mata Pelajaran',
                    style: GoogleFonts.raleway(fontSize: 18),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showEditSubjectDialog(id, name, classInfo, code);
                  },
                ),
                SizedBox(height: 10),
                // Pilihan Hapus dengan Icon
                ListTile(
                  leading: Icon(Icons.delete, color: Colors.red, size: 30),
                  title: Text(
                    'Hapus Mata Pelajaran',
                    style: GoogleFonts.raleway(fontSize: 18),
                  ),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showDeleteSubjectDialog(id);
                  },
                ),
                SizedBox(height: 20),
                // Tombol Batal
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Batal',
                    style: GoogleFonts.raleway(fontSize: 16, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showDeleteSubjectDialog(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 5,
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_forever, size: 60, color: Colors.red), // Ikon Hapus
                SizedBox(height: 20),
                Text(
                  'Hapus Mata Pelajaran',
                  style: GoogleFonts.raleway(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: 20),
                Text(
                  'Apakah Anda yakin ingin menghapus mata pelajaran ini?',
                  style: GoogleFonts.raleway(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text(
                        'Batal',
                        style: GoogleFonts.raleway(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _deleteSubject(id),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(15),
                        ),
                      ),
                      child: Text(
                        'Hapus',
                        style: GoogleFonts.raleway(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }


  String generateImageUrl(String subjectId) {
    return 'https://picsum.photos/seed/$subjectId/150';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('logo.png', height: 40),
            SizedBox(width: 10),
            Text('ABSENSI SMPN 1 JEMBER',
                style: GoogleFonts.roboto(fontSize: 18)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundImage: AssetImage('avatar.png'),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => _filterSubjects(value),
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search, color: Colors.grey),
                hintText: 'Cari Kelas',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              style: GoogleFonts.raleway(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: filteredSubjects.length,
              itemBuilder: (context, index) {
                final subject = filteredSubjects[index];
                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  elevation: 5,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Container(
                    height: 150, // Tinggi tetap untuk setiap item agar ukuran gambar konsisten
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(15),
                      image: DecorationImage(
                        image: NetworkImage(
                          'https://picsum.photos/seed/${subject['id']}/500/300',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(15),
                      title: Text(
                        subject['name'] ?? 'Mata Pelajaran',
                        style: GoogleFonts.raleway(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        'Tahun Ajaran ${subject['class_code'] ?? 'Tidak diketahui'}\n${subject['class'] ?? 'Kelas tidak tersedia'}',
                        style: GoogleFonts.raleway(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      trailing: PopupMenuButton<int>(
                        icon: Icon(Icons.more_vert, color: Colors.white), // Ikon di sebelah kanan
                        onSelected: (value) {
                          if (value == 0) {
                            // Aksi untuk Edit
                            _showEditSubjectDialog(
                              subject['id'],
                              subject['name'],
                              subject['class'],
                              subject['class_code'],
                            );
                          } else if (value == 1) {
                            // Aksi untuk Hapus
                            _showDeleteSubjectDialog(subject['id']);
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 0,
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.teal),
                                SizedBox(width: 10),
                                Text('Edit', style: GoogleFonts.raleway()),
                              ],
                            ),
                          ),
                          PopupMenuItem(
                            value: 1,
                            child: Row(
                              children: [
                                Icon(Icons.delete, color: Colors.red),
                                SizedBox(width: 10),
                                Text('Hapus', style: GoogleFonts.raleway()),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _showAddSubjectDialog,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
          child: Text('+', style: GoogleFonts.roboto(fontSize: 30, color: Colors.teal)),
        ),
      ),    );
  }
}

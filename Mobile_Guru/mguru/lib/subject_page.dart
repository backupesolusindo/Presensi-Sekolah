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
        return AlertDialog(
          title: Text('Tambah Mata Pelajaran',
              style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nama Mata Pelajaran'),
                style: GoogleFonts.raleway(),
              ),
              TextField(
                controller: _classController,
                decoration: InputDecoration(labelText: 'Kelas'),
                style: GoogleFonts.raleway(),
              ),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(labelText: 'Tahun Ajaran'),
                style: GoogleFonts.raleway(),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Batal', style: GoogleFonts.raleway()),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Tambah', style: GoogleFonts.raleway()),
              onPressed: _addSubject,
            ),
          ],
        );
      },
    );
  }

  void _showEditSubjectDialog(
      String id, String name, String classInfo, String code) {
    _selectedSubjectId = id;
    _nameController.text = name;
    _classController.text = classInfo;
    _codeController.text = code;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Mata Pelajaran',
              style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: InputDecoration(labelText: 'Nama Mata Pelajaran'),
                style: GoogleFonts.raleway(),
              ),
              TextField(
                controller: _classController,
                decoration: InputDecoration(labelText: 'Kelas'),
                style: GoogleFonts.raleway(),
              ),
              TextField(
                controller: _codeController,
                decoration: InputDecoration(labelText: 'Kode Kelas'),
                style: GoogleFonts.raleway(),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text('Batal', style: GoogleFonts.raleway()),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Simpan', style: GoogleFonts.raleway()),
              onPressed: _updateSubject,
            ),
          ],
        );
      },
    );
  }

  void _showSubjectOptionsDialog(
      String id, String name, String classInfo, String code) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Pilih Aksi',
              style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
          content: Text('Apa yang ingin Anda lakukan?',
              style: GoogleFonts.raleway()),
          actions: [
            TextButton(
              child: Text('Edit', style: GoogleFonts.raleway()),
              onPressed: () {
                Navigator.of(context).pop();
                _showEditSubjectDialog(id, name, classInfo, code);
              },
            ),
            TextButton(
              child: Text('Hapus', style: GoogleFonts.raleway()),
              onPressed: () {
                Navigator.of(context).pop();
                _showDeleteSubjectDialog(id);
              },
            ),
            TextButton(
              child: Text('Batal', style: GoogleFonts.raleway()),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        );
      },
    );
  }

  void _showDeleteSubjectDialog(String id) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Hapus Mata Pelajaran',
              style: GoogleFonts.raleway(fontWeight: FontWeight.bold)),
          content: Text('Apakah Anda yakin ingin menghapus mata pelajaran ini?',
              style: GoogleFonts.raleway()),
          actions: [
            TextButton(
              child: Text('Batal', style: GoogleFonts.raleway()),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Hapus', style: GoogleFonts.raleway()),
              onPressed: () => _deleteSubject(id),
            ),
          ],
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
                style: GoogleFonts.raleway(fontSize: 18)),
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
                    height:
                        150, // Tinggi tetap untuk setiap item agar ukuran gambar konsisten
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
                        subject['name'],
                        style: GoogleFonts.raleway(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: Colors.white,
                        ),
                      ),
                      subtitle: Text(
                        'Tahun Ajaran 2023-2024\n${subject['class']}',
                        style: GoogleFonts.raleway(
                          fontSize: 16,
                          color: Colors.white,
                        ),
                      ),
                      onTap: () {
                        _showSubjectOptionsDialog(
                          subject['id'],
                          subject['name'],
                          subject['class'],
                          '', // Tidak menampilkan kode kelas
                        );
                      },
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddSubjectDialog,
        child: Icon(Icons.add),
        backgroundColor: Colors.teal,
      ),
    );
  }
}

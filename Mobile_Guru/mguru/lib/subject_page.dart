import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart'; // Import halaman login
import 'subject_detail_page.dart'; // Import the subject detail page

class SubjectPage extends StatefulWidget {
  final String nip; // Pass the NIP from login

  SubjectPage({required this.nip});

  @override
  _SubjectPageState createState() => _SubjectPageState();
}

class _SubjectPageState extends State<SubjectPage> {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> subjects = [];
  List<dynamic> filteredSubjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  // Load subjects from API
  Future<void> _loadSubjects() async {
    try {
      if (widget.nip == 'admin') {
        setState(() {
          subjects = [
            {
              'id': 'admin_subject',
              'name': 'Matematika',
              'class': 'Kelas 7',
              'year': 'Tahun Ajaran 2023-2024',
            },
          ];
          filteredSubjects = subjects;
          _isLoading = false;
        });
      } else {
        final response = await http.get(
            Uri.parse('https://presensi-smp1.esolusindo.com/ApiGuru/Guru/SyncGuru'));
        if (response.statusCode == 200) {
          final List<dynamic> data = json.decode(response.body);
          setState(() {
            subjects = data;
            filteredSubjects = subjects;
            _isLoading = false;
          });
        } else {
          throw Exception('Failed to load subjects');
        }
      }
    } catch (e) {
      print('Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data mata pelajaran. Coba lagi nanti.')),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterSubjects(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredSubjects = subjects;
      } else {
        filteredSubjects = subjects
            .where((subject) => (subject['name'] ?? 'Unknown Subject')
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // Fungsi untuk menangani logout
  void _logout() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()), // Mengarahkan ke halaman login
    );
  }

  // Navigate to Subject Detail Page
  void _onSubjectTap(dynamic subject) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SubjectDetailPage(subject: subject)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Image.asset('logo.png', height: 40),
            SizedBox(width: 10),
            Text('ABSENSI SMPN 1 JEMBER', style: GoogleFonts.roboto(fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout, // Tombol logout
            tooltip: 'Logout',
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
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
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    style: GoogleFonts.raleway(),
                  ),
                ),
                Expanded(
                  child: filteredSubjects.isEmpty
                      ? Center(child: Text('Tidak ada mata pelajaran ditemukan.'))
                      : ListView.builder(
                          itemCount: filteredSubjects.length,
                          itemBuilder: (context, index) {
                            final subject = filteredSubjects[index];
                            final subjectName = subject['name'] ?? 'Unknown Subject';
                            final subjectClass = subject['class'] ?? 'Unknown Class';

                            return GestureDetector(
                              onTap: () => _onSubjectTap(subject), // Handle tap
                              child: Card(
                                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                elevation: 5,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Stack(
                                  children: [
                                    Container(
                                      height: 150,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        image: DecorationImage(
                                          image: NetworkImage(
                                            'https://picsum.photos/seed/${subject['id'] ?? 1}/200/300/',
                                          ),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height: 150,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(15),
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.6),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 10,
                                      left: 10,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            subjectName,
                                            style: GoogleFonts.raleway(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            'Tahun Ajaran 2023-2024',
                                            style: GoogleFonts.raleway(
                                              color: Colors.white,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Positioned(
                                      bottom: 10,
                                      right: 10,
                                      child: Text(
                                        subjectClass,
                                        style: GoogleFonts.raleway(
                                          color: Colors.white,
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}

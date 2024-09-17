import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:google_fonts/google_fonts.dart';

class SubjectPage extends StatefulWidget {
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
      final response = await http.get(Uri.parse('http://192.168.1.14/mapel.php'));
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

  // Filter subjects based on search input
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
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircleAvatar(
              backgroundImage: AssetImage('avatar.png'),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
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
                
                // Subject List
                Expanded(
                  child: filteredSubjects.isEmpty
                      ? Center(child: Text('Tidak ada mata pelajaran ditemukan.'))
                      : ListView.builder(
                          itemCount: filteredSubjects.length,
                          itemBuilder: (context, index) {
                            final subject = filteredSubjects[index];

                            // Handle null values with default strings
                            final subjectName = subject['name'] ?? 'Unknown Subject';
                            final subjectClass = subject['class'] ?? 'Unknown Class';

                            return Card(
                              margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              elevation: 5,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Stack(
                                children: [
                                  // Background Image
                                  Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(15),
                                      image: DecorationImage(
                                        image: NetworkImage(
                                          'https://picsum.photos/seed/${subject['id'] ?? 1}/200/300/?blur', // Default ID if null
                                        ),
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                                  
                                  // Gradient Overlay for Text Readability
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
                                  
                                  // Text overlaid on image
                                  Positioned(
                                    bottom: 10,
                                    left: 10,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          subjectName, // Safe subject name
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
                                  
                                  // Class info on the right
                                  Positioned(
                                    bottom: 10,
                                    right: 10,
                                    child: Text(
                                      subjectClass, // Safe class info
                                      style: GoogleFonts.raleway(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Gunakan Google Fonts untuk font yang lebih keren
import 'database_helper.dart'; // Ganti dengan path yang sesuai

class DashboardContent extends StatefulWidget {
  @override
  _DashboardContentState createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _students = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    List<Map<String, dynamic>> students = await _dbHelper.getStudents();
    setState(() {
      _students = students;
    });
  }

  void _showAddStudentDialog() {
    final TextEditingController namaController = TextEditingController();
    final TextEditingController nisController = TextEditingController();
    final TextEditingController kelasController = TextEditingController();
    String errorMessage = '';

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white, // Background putih
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Tambahkan Siswa',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Colors.blueAccent,
                      ),
                    ),
                    SizedBox(height: 20),
                    _buildLabel('Nama Siswa'), // Tambahkan label Nama
                    _buildTextField(namaController, 'Nama Siswa'),
                    _buildLabel('NIS'), // Tambahkan label NIS
                    _buildTextField(nisController, 'NIS'),
                    _buildLabel('Kelas'), // Tambahkan label Kelas
                    _buildTextField(kelasController, 'Kelas'),
                    if (errorMessage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          errorMessage,
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop(); // Tutup dialog
                          },
                          child: Text(
                            'Batal',
                            style: GoogleFonts.poppins(
                              color: Colors.redAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: EdgeInsets.symmetric(
                              vertical: 10,
                              horizontal: 25,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () async {
                            String nama = namaController.text;
                            String nis = nisController.text;
                            String kelas = kelasController.text;

                            if (nama.isEmpty || nis.isEmpty || kelas.isEmpty) {
                              setState(() {
                                errorMessage = 'Harap lengkapi semua field';
                              });
                            } else {
                              await _dbHelper.insertStudent({
                                'nama': nama,
                                'nis': nis,
                                'kelas': kelas,
                              });

                              _loadData();

                              Navigator.of(context).pop(); // Tutup dialog
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Data siswa berhasil ditambahkan'),
                                ),
                              );
                            }
                          },
                          child: Text(
                            'Tambahkan',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.white, // Warna teks tombol tetap putih
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
      },
    );
  }

  // Fungsi tambahan untuk menampilkan label di atas TextField
  Widget _buildLabel(String labelText) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Text(
          labelText,
          style: GoogleFonts.poppins(
            color: Colors.blueAccent,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextField(
        controller: controller,
        style: TextStyle(color: Colors.black),
        decoration: InputDecoration(
          filled: true,
          fillColor: Colors.grey.shade200, // Warna background text field
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: Colors.blueAccent, width: 2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selamat Datang!',
              style: GoogleFonts.poppins(
                fontSize: 28.0,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent,
              ),
            ),
            Text(
              'Di Absensi Siswa',
              style: GoogleFonts.poppins(
                fontSize: 16.0,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: _students.isNotEmpty
                  ? ListView.builder(
                      itemCount: _students.length,
                      itemBuilder: (context, index) {
                        final student = _students[index];
                        return Card(
                          elevation: 8,
                          margin: const EdgeInsets.symmetric(vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.all(16),
                            title: Text(
                              student['nama'],
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                            subtitle: Text(
                              'NIS: ${student['nis']} | Kelas: ${student['kelas']}',
                              style: GoogleFonts.poppins(
                                color: Colors.grey.shade600,
                                fontSize: 14,
                              ),
                            ),
                            leading: CircleAvatar(
                              backgroundColor: Colors.blueAccent,
                              child: Icon(
                                Icons.person,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Belum ada data siswa',
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              color: Colors.grey,
                            ),
                          ),
                          SizedBox(height: 20), // Menambahkan jarak
                        ],
                      ),
                    ),
            ),
            // Hanya satu tombol Tambahkan Siswa di bagian bawah
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 8,
                ),
                onPressed: _showAddStudentDialog,
                child: Text(
                  'Tambahkan Siswa',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

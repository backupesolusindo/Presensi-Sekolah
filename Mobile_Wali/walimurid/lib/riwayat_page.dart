import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // Import Google Fonts
import 'database_helper.dart'; // Pastikan path ini benar
import 'package:http/http.dart' as http;
import 'dart:convert';

class RiwayatPage extends StatefulWidget {
  @override
  _RiwayatPageState createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  List<dynamic> _absensiList = [];
  List<dynamic> _filteredAbsensiList = [];
  bool _isLoading = true;
  String? _nis; // Variabel untuk menyimpan NIS dari SQLite
  DateTime? _selectedDate; // Variabel untuk menyimpan tanggal yang dipilih

  final DatabaseHelper _dbHelper = DatabaseHelper(); // Inisialisasi DatabaseHelper

  @override
  void initState() {
    super.initState();
    _getNisFromDatabase(); // Ambil NIS dari SQLite saat halaman dibuka
  }

  Future<void> _getNisFromDatabase() async {
    // Lakukan query untuk mengambil NIS dari SQLite
    List<Map<String, dynamic>> students = await _dbHelper.getStudents();
    if (students.isNotEmpty) {
      setState(() {
        _nis = students[0]['nis']; // Ambil NIS dari record pertama
      });
      _fetchData(); // Lakukan fetch data absensi setelah NIS diperoleh
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data NIS tidak ditemukan')),
      );
    }
  }

  Future<void> _fetchData() async {
    if (_nis == null) return; // Pastikan NIS tidak null sebelum melakukan request
    String url = 'https://presensi-smp1.esolusindo.com/ApiGerbang/Gerbang/ambilAbsen';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {'nis': _nis}, // Gunakan NIS dari SQLite sebagai parameter
      );

      if (response.statusCode == 200) {
        setState(() {
          _absensiList = json.decode(response.body)['data']; // Parsing respons JSON
          _filteredAbsensiList = _absensiList; // Inisialisasi daftar yang difilter
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data');
      }
    } catch (e) {
      print(e);
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data absensi')),
      );
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        // Filter data berdasarkan tanggal yang dipilih
        _filteredAbsensiList = _absensiList.where((absensi) {
          DateTime absensiDate = DateTime.parse(absensi['tanggal']);
          return absensiDate.year == _selectedDate!.year &&
              absensiDate.month == _selectedDate!.month &&
              absensiDate.day == _selectedDate!.day;
        }).toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: EdgeInsets.all(16),
        color: Colors.white, // Ubah latar belakang menjadi putih
        child: Column(
          children: [
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.date_range, // Menggunakan ikon date_range
                      color: Colors.white,
                    ),
                    SizedBox(width: 8), // Spasi antara ikon dan teks
                    Text(
                      'Pilih Tanggal',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24), // Jarak antara button dan list menjadi lebih besar
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _filteredAbsensiList.isEmpty
                    ? Center(
                        child: Text(
                          'Tidak ada data absensi',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      )
                    : Expanded(
                        child: ListView.builder(
                          itemCount: _filteredAbsensiList.length,
                          itemBuilder: (context, index) {
                            final absensi = _filteredAbsensiList[index];
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(16),
                                title: Text(
                                  'Tanggal: ${absensi['tanggal'] ?? 'N/A'}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: Text(
                                  'Status: ${absensi['status'] ?? 'N/A'}',
                                  style: GoogleFonts.poppins(
                                    color: Colors.grey.shade700,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
          ],
        ),
      ),
    );
  }
}

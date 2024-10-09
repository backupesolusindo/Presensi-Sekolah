import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'database_helper.dart'; // Sesuaikan path jika perlu
import 'package:http/http.dart' as http;
import 'dart:convert';

class RiwayatPage extends StatefulWidget {
  final List<dynamic> siswaData; // Tambahkan parameter siswaData

  const RiwayatPage({Key? key, required this.siswaData}) : super(key: key); // Konstruktor

  @override
  _RiwayatPageState createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  List<dynamic> _absensiList = [];
  bool _isLoading = true;

  final DatabaseHelper _dbHelper = DatabaseHelper();

  @override
  void initState() {
    super.initState();
    _getNisFromSiswaData(); // Ambil NIS dari siswaData saat halaman dibuka
  }

  void _getNisFromSiswaData() {
  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (widget.siswaData.isNotEmpty) {
      List<String> nisList = widget.siswaData
          .map((siswa) => siswa['nis'].toString()) // Ubah setiap NIS ke String
          .toList(); // Ambil semua NIS
      _fetchData(nisList); // Panggil API dengan semua NIS
    } else {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Data NIS tidak ditemukan')),
      );
    }
  });
}

  Future<void> _fetchData(List<String> nisList) async {
    setState(() {
      _isLoading = true; // Set loading true sebelum mulai fetch
      _absensiList.clear(); // Kosongkan daftar absensi sebelumnya
    });

    String url = 'https://presensi-smp1.esolusindo.com/ApiGerbang/Gerbang/ambilAbsen';

    try {
      // Iterasi melalui semua NIS dan panggil API untuk setiap NIS
      for (String nis in nisList) {
        final response = await http.post(
          Uri.parse(url),
          body: {'nis': nis},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'success') {
            setState(() {
              _absensiList.addAll(data['data']); // Tambahkan data ke _absensiList
            });
          } else {
            throw Exception(data['message'] ?? 'Gagal mengambil data absensi');
          }
        } else {
          throw Exception('Failed to load data: ${response.statusCode}');
        }
      }
    } catch (e) {
      print(e); // Untuk debugging di konsol
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal mengambil data absensi: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false; // Set loading false setelah fetch selesai
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Riwayat Absensi', style: GoogleFonts.poppins()),
      ),
      body: Container(
        padding: EdgeInsets.all(16),
        color: Colors.white,
        child: Column(
          children: [
            SizedBox(height: 24),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : _absensiList.isEmpty
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
                          itemCount: _absensiList.length,
                          itemBuilder: (context, index) {
                            final absensi = _absensiList[index];
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: ListTile(
                                contentPadding: EdgeInsets.all(16),
                                title: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Nama: ${absensi['nama'] ?? 'N/A'}',
                                      style: GoogleFonts.poppins(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      'Kelas: ${absensi['kelas'] ?? 'N/A'}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'NIS: ${absensi['nis'] ?? 'N/A'}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Tanggal: ${absensi['tanggal'] ?? 'N/A'}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Status: ${absensi['status'] ?? 'N/A'}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      'Waktu: ${absensi['waktu'] ?? 'N/A'}',
                                      style: GoogleFonts.poppins(
                                        color: Colors.grey.shade700,
                                        fontSize: 14,
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
      ),
    );
  }
}

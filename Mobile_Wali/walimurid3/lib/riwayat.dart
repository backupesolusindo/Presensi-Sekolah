import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home.dart';
import 'profile.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RiwayatPage extends StatefulWidget {
  @override
  _RiwayatPageState createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  String selectedNis = ''; // Untuk menyimpan NIS yang dipilih
  int _currentIndex = 1;
  bool showRiwayatMasuk = true;
  int? selectedCardIndex;
  List<dynamic> riwayatData = [];
  List<dynamic> siswaList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData(); // Ambil data saat halaman dibuka
  }

  @override
  void dispose() {
    super.dispose();
    // Tambahkan kode ini untuk membersihkan jika perlu
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? siswaJsonList = prefs.getStringList('siswa_list');

    if (siswaJsonList != null) {
      siswaList = siswaJsonList.map((siswa) => json.decode(siswa)).toList();
      // Ambil NIS dari siswa pertama sebagai default
      selectedNis = siswaList.first['nis'];
      fetchRiwayatMasuk(); // Ambil data riwayat masuk
    } else {
      print('Tidak ada data siswa yang tersimpan.');
    }
  }

  Future<void> fetchRiwayatMasuk() async {
    final String url =
        'https://presensi-smp1.esolusindo.com/Api/ApiGerbang/Gerbang/ambilAbsen/$selectedNis';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          // Periksa apakah widget masih mounted sebelum memanggil setState
          if (mounted) {
            setState(() {
              riwayatData = result['data'];
              isLoading = false;
            });
          }
        } else {
          showError(result['message']);
        }
      } else {
        showError('Gagal mengambil data. Kode: ${response.statusCode}');
      }
    } catch (e) {
      showError('Terjadi kesalahan: $e');
    }
  }

  Future<void> fetchRiwayatMapel() async {
    final String url =
        'https://presensi-smp1.esolusindo.com/Api/ApiPresensi/ApiPresensi/getPresensiSiswa/$selectedNis';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> result = json.decode(response.body);
        if (result.isNotEmpty) {
          // Periksa apakah widget masih mounted sebelum memanggil setState
          if (mounted) {
            setState(() {
              riwayatData = result; // Simpan data yang diambil
              isLoading = false;
            });
          }
        } else {
          showError('Tidak ada data presensi untuk siswa ini.');
        }
      } else {
        showError('Gagal mengambil data. Kode: ${response.statusCode}');
      }
    } catch (e) {
      showError('Terjadi kesalahan: $e');
    }
  }

  void showError(String message) {
    // Periksa apakah widget masih mounted sebelum memanggil setState
    if (mounted) {
      setState(() {
        isLoading = false;
      });
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/walibg.png'),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: <Widget>[
                  Text(
                    'Riwayat Presensi Siswa',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Dropdown untuk memilih siswa
                  DropdownButton<String>(
                    value: selectedNis,
                    items: siswaList.map((siswa) {
                      return DropdownMenuItem<String>(
                        value: siswa['nis'],
                        child: Text(siswa['nama']), // Menampilkan nama siswa
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        selectedNis = value!;
                        isLoading =
                            true; // Menampilkan loading saat mengambil data
                        fetchRiwayatMasuk();
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildRiwayatCard(
                        index: 0,
                        icon: Icons.door_front_door,
                        title: 'Riwayat\nMasuk',
                        color: Colors.orangeAccent,
                        onTap: () {
                          setState(() {
                            showRiwayatMasuk = true;
                            selectedCardIndex = 0;
                            fetchRiwayatMasuk();
                          });
                        },
                      ),
                      _buildRiwayatCard(
                        index: 1,
                        icon: Icons.book,
                        title: 'Riwayat\nMapel',
                        color: Colors.purpleAccent,
                        onTap: () {
                          setState(() {
                            showRiwayatMasuk = false;
                            selectedCardIndex = 1;
                            fetchRiwayatMapel(); // Ambil data riwayat mapel
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Bagian yang dapat digulir
                  Expanded(
                    child: isLoading
                        ? Center(child: CircularProgressIndicator())
                        : showRiwayatMasuk
                            ? _buildRiwayatMasukList()
                            : _buildRiwayatMapelList(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _buildRiwayatCard({
    required int index,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    double scale = selectedCardIndex == index ? 1.1 : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        transformAlignment: Alignment.center,
        transform: Matrix4.identity()..scale(scale),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Container(
              width: 120,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.8),
                    color.withOpacity(0.5),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 40, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

// Tambahkan method ini untuk membangun list riwayat masuk
  Widget _buildRiwayatMasukList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: riwayatData.length,
      itemBuilder: (context, index) {
        final item = riwayatData[index];
        return _buildRiwayatMasukItem(
          item['tanggal'] ?? 'Tanggal tidak tersedia',
          item['waktu'] ?? 'Waktu tidak tersedia',
          item['kelas'] ?? 'Nama Kelas tidak tersedia',
          item['status'] ?? 'Status tidak tersedia',
          index,
        );
      },
    );
  }

// TANPAMISAHINTGLWAKTU
  // Widget _buildRiwayatMapelList() {
  //   return ListView.builder(
  //     shrinkWrap: true,
  //     itemCount: riwayatData.length,
  //     itemBuilder: (context, index) {
  //       final item = riwayatData[index];
  //       return _buildRiwayatMapelItem(
  //         item['tanggal'] ?? 'Tanggal tidak tersedia',
  //         item['waktu'] ?? 'Waktu tidak tersedia',
  //         item['id_jadwal'] ?? 'ID Jadwal tidak tersedia',
  //         item['status'] ?? 'Status tidak tersedia',
  //         index,
  //       );
  //     },
  //   );
  // }

//MISAHINTGLWAKTU
// Tambahkan method ini untuk membangun list riwayat mapel
  Widget _buildRiwayatMapelList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: riwayatData.length,
      itemBuilder: (context, index) {
        final item = riwayatData[index];

        // Memisahkan tanggal dan waktu dengan penanganan kesalahan
        String tanggal = 'Tanggal tidak tersedia';
        String waktu = 'Waktu tidak tersedia';

        if (item['tanggal'] != null && item['tanggal'].isNotEmpty) {
          List<String> parts = item['tanggal'].split(' ');
          if (parts.length > 1) {
            tanggal = parts[0]; // Ambil bagian tanggal
            waktu = parts[1]; // Ambil bagian waktu
          } else {
            tanggal = parts[0]; // Jika tidak ada waktu, tetap ambil tanggal
          }
        }

        return _buildRiwayatMapelItem(
          tanggal,
          waktu,
          item['id_jadwal'] ?? 'ID Jadwal tidak tersedia',
          item['status'] ?? 'Status tidak tersedia',
          index,
        );
      },
    );
  }

// Item untuk riwayat masuk
  Widget _buildRiwayatMasukItem(
      String tanggal, String waktu, String kelas, String status, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nama Kelas: $kelas',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Tanggal: $tanggal'),
              const SizedBox(height: 8),
              Text('Waktu: $waktu'),
              const SizedBox(height: 8),
              Text('Status: $status'),
            ],
          ),
        ),
      ),
    );
  }

// TANPAMISAHINTGLWAKTU
  // Widget _buildRiwayatMapelItem(
  //     String tanggal, String waktu, String idJadwal, String status, int index) {
  //   return Padding(
  //     padding: const EdgeInsets.symmetric(vertical: 8.0),
  //     child: Card(
  //       elevation: 8,
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(15),
  //       ),
  //       child: Container(
  //         padding: const EdgeInsets.all(16.0),
  //         child: Column(
  //           crossAxisAlignment: CrossAxisAlignment.start,
  //           children: [
  //             Text('ID Jadwal: $idJadwal',
  //                 style: TextStyle(fontWeight: FontWeight.bold)),
  //             const SizedBox(height: 8),
  //             Text('Tanggal: $tanggal'),
  //             const SizedBox(height: 8),
  //             Text('Waktu: $waktu'),
  //             const SizedBox(height: 8),
  //             Text('Status: $status'),
  //           ],
  //         ),
  //       ),
  //     ),
  //   );
  // }

//MISAHINTGLWAKTU
  Widget _buildRiwayatMapelItem(
      String tanggal, String waktu, String idJadwal, String status, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('ID Jadwal: $idJadwal',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Tanggal: $tanggal'),
              const SizedBox(height: 8),
              Text(
                  'Waktu: $waktu'), // Gunakan waktu yang diambil dari bagian belakang
              const SizedBox(height: 8),
              Text('Status: $status'),
            ],
          ),
        ),
      ),
    );
  }
}

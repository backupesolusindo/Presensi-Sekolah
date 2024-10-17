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
  String? selectedSiswa;
  int _currentIndex = 1;
  bool showRiwayatMasuk = true;
  int? selectedCardIndex;
  List<dynamic> riwayatData = [];
  List<dynamic> siswaList = [];
  bool isLoading = true;
  String nis = "";
  String kelas = "";
  String namaSiswa = "";
  DateTime? selectedDate; // Variabel untuk menyimpan tanggal yang dipilih

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final prefs = await SharedPreferences.getInstance();
    List<String>? siswaJsonList = prefs.getStringList('siswa_list');
    if (siswaJsonList != null) {
      setState(() {
        siswaList = siswaJsonList.map((siswaJson) {
          return json.decode(siswaJson);
        }).toList();

        selectedSiswa = prefs.getString('selectedSiswa');
        if (selectedSiswa != null) {
          final selected =
              siswaList.firstWhere((siswa) => siswa['nama'] == selectedSiswa);
          _updateSiswaDetail(selected);
        } else {
          selectedSiswa = siswaList.first['nama'];
          _updateSiswaDetail(siswaList.first);
        }
      });
    } else {
      print('Tidak ada data siswa yang tersimpan.');
    }
  }

  void _updateSiswaDetail(Map<String, dynamic> siswa) {
    setState(() {
      namaSiswa = siswa['nama'];
      nis = siswa['nis'];
      kelas = siswa['nama_kelas'];
    });
  }

  Future<void> fetchRiwayatMasuk() async {
    final String url =
        'https://presensi-smp1.esolusindo.com/Api/ApiGerbang/Gerbang/ambilAbsen/$nis';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
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
        'https://presensi-smp1.esolusindo.com/Api/ApiPresensi/ApiPresensi/getPresensiSiswa/$nis';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final List<dynamic> result = json.decode(response.body);
        if (result.isNotEmpty) {
          if (mounted) {
            setState(() {
              riwayatData = result;
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

  // Fungsi untuk memilih tanggal
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
        _filterRiwayatByDate(); // Filter riwayat setelah memilih tanggal
      });
    }
  }

  // Fungsi untuk memfilter riwayat berdasarkan tanggal
  void _filterRiwayatByDate() {
    if (selectedDate != null) {
      final selectedDateString =
          "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}";
      riwayatData = riwayatData.where((item) {
        // Pastikan item['tanggal'] sesuai format YYYY-MM-DD
        return item['tanggal'].toString().startsWith(selectedDateString);
      }).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
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
            child: SingleChildScrollView(
              // Menambahkan SingleChildScrollView di sini
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 20),

                  // Menambahkan button untuk memilih tanggal
                  ElevatedButton(
                    onPressed: () => _selectDate(context),
                    child: Text(selectedDate == null
                        ? 'Pilih Tanggal'
                        : 'Tanggal Dipilih: ${selectedDate!.toLocal()}'
                            .split(' ')[0]),
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
                            fetchRiwayatMapel();
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Widget untuk menampilkan riwayat masuk atau mapel
                  isLoading
                      ? Center(child: Text("Pilih riwayat yang ingin dilihat"))
                      : showRiwayatMasuk
                          ? _buildRiwayatMasukList()
                          : _buildRiwayatMapelList(),
                ],
              ),
            ),
          ),
        ],
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
    return GestureDetector(
      onTap: onTap,
      child: Card(
        color: selectedCardIndex == index ? color : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(16.0),
          width: 150,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 40,
                  color:
                      selectedCardIndex == index ? Colors.white : Colors.black),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color:
                      selectedCardIndex == index ? Colors.white : Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRiwayatMasukList() {
    return ListView.builder(
      shrinkWrap: true, // Mengatur untuk membungkus tinggi
      physics:
          NeverScrollableScrollPhysics(), // Menonaktifkan scroll pada ListView ini
      itemCount: riwayatData.length,
      itemBuilder: (context, index) {
        final item = riwayatData[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            title: Text(item['tanggal'] ?? ''),
            subtitle: Text(item['status'] ?? ''),
          ),
        );
      },
    );
  }

  Widget _buildRiwayatMapelList() {
    return ListView.builder(
      shrinkWrap: true, // Mengatur untuk membungkus tinggi
      physics:
          NeverScrollableScrollPhysics(), // Menonaktifkan scroll pada ListView ini
      itemCount: riwayatData.length,
      itemBuilder: (context, index) {
        final item = riwayatData[index];
        return Card(
          margin: EdgeInsets.symmetric(vertical: 5),
          child: ListTile(
            title: Text(item['mapel'] ?? ''),
            subtitle: Text(item['tanggal'] ?? ''),
          ),
        );
      },
    );
  }
}

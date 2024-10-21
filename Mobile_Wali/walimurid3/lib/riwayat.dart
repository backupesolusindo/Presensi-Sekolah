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
  DateTime selectedDate = DateTime.now(); // Ubah menjadi non-nullable dengan nilai default
  bool isRiwayatSelected = false; // Tambahkan variabel ini

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
      initialDate: selectedDate,
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

  void _onRiwayatButtonTapped(bool isRiwayatMasuk) {
    setState(() {
      showRiwayatMasuk = isRiwayatMasuk;
      selectedCardIndex = isRiwayatMasuk ? 0 : 1;
      isRiwayatSelected = true;
      isLoading = true;
    });
    if (isRiwayatMasuk) {
      fetchRiwayatMasuk();
    } else {
      fetchRiwayatMapel();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image
          Image.asset(
            'assets/walibg.png',
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          ),
          // Content
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Laporan',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  _buildRiwayatButtons(),
                  SizedBox(height: 16),
                  _buildDatePicker(),
                  SizedBox(height: 16),
                  Expanded(
                    child: !isRiwayatSelected
                        ? Center(child: Text("Pilih riwayat yang ingin dilihat"))
                        : isLoading
                            ? Center(child: CircularProgressIndicator())
                            : showRiwayatMasuk
                                ? _buildRiwayatMasukList()
                                : _buildRiwayatMapelList(),
                  ),
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

  Widget _buildRiwayatButtons() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildRiwayatButton(
              index: 0,
              title: 'Riwayat Masuk',
              color: Colors.orange,
              onTap: () => _onRiwayatButtonTapped(true),
            ),
          ),
          Expanded(
            child: _buildRiwayatButton(
              index: 1,
              title: 'Riwayat Mapel',
              color: Colors.purple,
              onTap: () => _onRiwayatButtonTapped(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatButton({
    required int index,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    bool isSelected = selectedCardIndex == index;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Pilih Tanggal"),
          GestureDetector(
            onTap: () => _selectDate(context),
            child: Row(
              children: [
                Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                SizedBox(width: 8),
                Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                  style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatMasukList() {
    return ListView.builder(
      itemCount: riwayatData.length,
      itemBuilder: (context, index) {
        final item = riwayatData[index];
        Color cardColor = item["status"].toString() == "absen" ? Colors.teal : Colors.orange;
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Waktu Masuk:", style: TextStyle(color: Colors.white)),
                      SizedBox(height: 4),
                      Text(item['status'] ?? '', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    item['tanggal'] ?? '',
                    style: TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRiwayatMapelList() {
    return ListView.builder(
      itemCount: riwayatData.length,
      itemBuilder: (context, index) {
        final item = riwayatData[index];
        bool isHadir = item['status'] == '1';
        Color cardColor = isHadir ? Colors.green : Colors.red;
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.horizontal(left: Radius.circular(12)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("ID Jadwal: ${item['id_jadwal'] ?? 'Tidak ada'}",
                            style: TextStyle(color: Colors.white)),
                        SizedBox(height: 4),
                        Text(isHadir ? 'Hadir' : 'Tidak Hadir',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center, // Ubah ke center
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          item['tanggal'] ?? 'Tidak ada tanggal',
                          style: TextStyle(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center, // Ubah ke center
                        ),
                        SizedBox(height: 4),
                        Text(
                          item['jam'] ?? '',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center, // Ubah ke center
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

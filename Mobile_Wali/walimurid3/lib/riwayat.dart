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
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: <Widget>[
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                      color: Colors.white, // Ubah warna menjadi putih
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Expanded(child: _buildRiwayatButton(
                              index: 0,
                              icon: Icons.door_front_door,
                              title: 'Riwayat Masuk',
                              color: Colors.orangeAccent,
                              onTap: () {
                                setState(() {
                                  showRiwayatMasuk = true;
                                  selectedCardIndex = 0;
                                  fetchRiwayatMasuk();
                                });
                              },
                            )),
                            SizedBox(width: 8),
                            Expanded(child: _buildRiwayatButton(
                              index: 1,
                              icon: Icons.book,
                              title: 'Riwayat Mapel',
                              color: Colors.purpleAccent,
                              onTap: () {
                                setState(() {
                                  showRiwayatMasuk = false;
                                  selectedCardIndex = 1;
                                  fetchRiwayatMapel();
                                });
                              },
                            )),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                      elevation: 4,
                      color: Colors.white, // Ubah warna menjadi putih
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("Tanggal Filter:"),
                              Row(
                                children: [
                                  Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                                    style: TextStyle(color: Colors.blue, fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              Icon(Icons.arrow_forward_ios, color: Colors.blue, size: 16),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildRiwayatButton({
    required int index,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          color: selectedCardIndex == index ? color : Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: selectedCardIndex == index ? Colors.white : color),
            SizedBox(width: 4),
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  color: selectedCardIndex == index ? Colors.white : color,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiwayatMasukList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: riwayatData.length,
      itemBuilder: (context, index) {
        final item = riwayatData[index];
        Color WarnaBG ;
        if(item["status"].toString() == "absen"){
          WarnaBG = Colors.teal;
        }else{
          WarnaBG = Colors.orange;
        }
        return Container(
          margin: EdgeInsets.all(8),
          child: Row(
          children: [
            Expanded(
              flex: 2,
              child: 
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: WarnaBG,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(8),
                  bottomRight: Radius.circular(24),
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(24),
                )
              ),
              child: Column(
                children: [
                  Text("Waktu Masuk :", style: TextStyle(color: Colors.white)),
                  Text(item['status'] ?? '', style: TextStyle(color: Colors.white))

                ]
              )
            ),
            ),
            Expanded(
              flex: 1,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(8),
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(8),
                )
                
              ),
              child: Column(
                children: [
                  Text(item['tanggal'] ?? '', style: TextStyle(color: Colors.black))

                ]
              )
            ),)
            
          ]
        )
        );
      },
    );
  }

  Widget _buildRiwayatMapelList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: riwayatData.length,
      itemBuilder: (context, index) {
        var riwayat = riwayatData[index];
        bool isHadir = riwayat['status'] == '1';
        return Card(
          margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          color: isHadir ? Colors.green[100] : Colors.red[100],
          child: ListTile(
            title: Text('ID Jadwal: ${riwayat['id_jadwal'] ?? 'Tidak ada id jadwal'}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tanggal: ${riwayat['tanggal'] ?? 'Tidak ada tanggal'}'),
                Text(
                  isHadir ? 'Hadir' : 'Tidak Hadir',
                  style: TextStyle(
                    color: isHadir ? Colors.green[700] : Colors.red[700],
                    fontWeight: FontWeight.bold,
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

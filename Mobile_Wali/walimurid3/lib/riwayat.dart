import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'home.dart';
import 'profile.dart';

class RiwayatPage extends StatefulWidget {
  @override
  _RiwayatPageState createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  String selectedFilter = 'Semua';
  int _currentIndex = 1;
  bool showRiwayatMasuk = true;
  int? selectedCardIndex;
  List<dynamic> riwayatData = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchRiwayatMasuk(); // Ambil data saat halaman dibuka
  }

  Future<void> fetchRiwayatMasuk() async {
    final String nis = '12345'; // Ganti dengan NIS yang sesuai
    final String url =
        'https://presensi-smp1.esolusindo.com/Api/ApiGerbang/Gerbang/ambilAbsen';

    try {
      final response = await http.post(
        Uri.parse(url),
        body: {'nis': nis},
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        if (result['status'] == 'success') {
          setState(() {
            riwayatData = result['data'];
            isLoading = false;
          });
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

  void showError(String message) {
    setState(() {
      isLoading = false;
    });
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
            SingleChildScrollView(
              child: Padding(
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
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    isLoading
                        ? CircularProgressIndicator()
                        : _buildRiwayatList(),
                  ],
                ),
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

  Widget _buildRiwayatList() {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: riwayatData.length,
      itemBuilder: (context, index) {
        final item = riwayatData[index];
        return _buildListItem(
          'Tanggal: ${item['tanggal']}',
          item['status'],
          index,
        );
      },
    );
  }

  Widget _buildListItem(String title, String status, int index) {
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
              Text(title),
              const SizedBox(height: 8),
              Text('Status: $status'),
            ],
          ),
        ),
      ),
    );
  }
}

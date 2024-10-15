import 'package:flutter/material.dart';
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
  int? selectedCardIndex; // Menyimpan index kartu yang dipilih

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

                    // Cards Riwayat Masuk dan Mapel
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
                              selectedCardIndex = 0; // Set index kartu yang dipilih
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
                              selectedCardIndex = 1; // Set index kartu yang dipilih
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Daftar Riwayat
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.6,
                      child: ListView.builder(
                        itemCount: 10,
                        itemBuilder: (context, index) {
                          String status = index % 5 == 0 ? 'Hadir' : 'Tidak Hadir';

                          if (selectedFilter != 'Semua' && selectedFilter != status) {
                            return const SizedBox.shrink();
                          }

                          return showRiwayatMasuk
                              ? _buildListItem('Riwayat Masuk', status, index)
                              : _buildListItem('Riwayat Mapel', status, index);
                        },
                      ),
                    ),
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
    // Mengatur ukuran berdasarkan index yang dipilih
    double scale = selectedCardIndex == index ? 1.2 : 1.0; // Kartu yang dipilih membesar

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        transform: Matrix4.identity()
          ..scale(scale)
          ..translate(
            (selectedCardIndex == index ? -15 : 0), // Menggeser kartu yang dipilih sedikit ke kiri
            (selectedCardIndex == index ? -15 : 0), // Menggeser kartu yang dipilih sedikit ke atas
          ),
        alignment: Alignment.center, // Mengarahkan ke tengah
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(22),
          child: Card(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
            ),
            child: Container(
              width: 120,
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: color.withOpacity(0.8),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                children: [
                  Icon(icon, size: 40, color: Colors.white),
                  const SizedBox(height: 1),
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

  Widget _buildListItem(String title, String status, int index) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                status == 'Hadir' ? Colors.greenAccent : Colors.redAccent,
                Colors.white,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$title - Senin, 29 Maret 2024',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
                ),
                const Divider(color: Colors.grey),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Nama Murid: Siswa ${index + 1}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Kelas: 10A'),
                        const SizedBox(height: 4),
                        Text('No Absen: ${index + 1}'),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Keterangan: $status',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: status == 'Hadir'
                                ? Colors.green
                                : Colors.redAccent,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text('Alasan: -'),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

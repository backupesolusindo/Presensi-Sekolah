import 'package:flutter/material.dart';
import 'riwayat_siswa_page.dart'; // Impor halaman riwayat
import 'data_murid_page.dart'; // Impor halaman data murid

class PresensiSiswaPage extends StatefulWidget {
  final String namaMapel;
  final String namaKelas;
  final String namaPengajar;
  final String waktuMulai;
  final String waktuSelesai;
  final String hari;

  const PresensiSiswaPage({
    Key? key,
    required this.namaMapel,
    required this.namaKelas,
    required this.namaPengajar,
    required this.waktuMulai,
    required this.waktuSelesai,
    required this.hari,
  }) : super(key: key);

  @override
  _PresensiSiswaPageState createState() => _PresensiSiswaPageState();
}

class _PresensiSiswaPageState extends State<PresensiSiswaPage> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  // Daftar halaman untuk ditampilkan berdasarkan indeks
  Widget _getSelectedPage() {
    switch (_selectedIndex) {
      case 0:
        return _buildPresensiPage(); // Halaman Presensi
      case 1:
        return RiwayatSiswaPage(); // Halaman Riwayat
      case 2:
        return DataMuridPage(); // Halaman Data Murid
      default:
        return _buildPresensiPage();
    }
  }

  // Fungsi untuk membangun halaman presensi
  Widget _buildPresensiPage() {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/WaliRename.png'), // Pastikan path sesuai
              fit: BoxFit.cover, // Mengisi seluruh area
            ),
          ),
        ),
        // Tambahkan Container hitam dengan opacity untuk efek pudar
        Container(
          color: Colors.black.withOpacity(0.1), // 10% transparan
        ),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: <Widget>[
              // Bagian Kartu Informasi Pelajaran
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${widget.namaMapel}',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black, // Warna teks hitam
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            'Kelas: ${widget.namaKelas}',
                            style: TextStyle(fontSize: 14, color: Colors.black), // Warna teks hitam
                          ),
                          Text(
                            'Pengajar: ${widget.namaPengajar}',
                            style: TextStyle(fontSize: 14, color: Colors.black), // Warna teks hitam
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${widget.waktuMulai} - ${widget.waktuSelesai}',
                            style: TextStyle(fontSize: 14, color: Colors.black), // Warna teks hitam
                          ),
                          SizedBox(height: 8),
                          Text(
                            '${widget.hari}',
                            style: TextStyle(fontSize: 14, color: Colors.black), // Warna teks hitam
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 20),

              // Bagian Grid Siswa
              Expanded(
                child: GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4, // Menampilkan 4 siswa per baris
                    crossAxisSpacing: 16.0,
                    mainAxisSpacing: 16.0,
                    childAspectRatio: 0.75,
                  ),
                  itemCount: 20, // Jumlah siswa
                  itemBuilder: (context, index) {
                    return Column(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.blue[100],
                          child: Icon(Icons.person, size: 40, color: Colors.blue),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Siswa ${index + 1}',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black), // Warna teks hitam
                          textAlign: TextAlign.center,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Presensi Siswa'),
        centerTitle: true,
      ),
      body: _getSelectedPage(),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.check_circle),
            label: 'Presensi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history),
            label: 'Riwayat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.people),
            label: 'Data Murid',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.blue,
        onTap: _onItemTapped,
      ),
    );
  }
}

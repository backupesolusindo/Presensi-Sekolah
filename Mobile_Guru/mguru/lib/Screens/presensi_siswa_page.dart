import 'package:flutter/material.dart';
import 'riwayat_siswa_page.dart'; // Import Riwayat page
import 'data_murid_page.dart'; // Import Data Murid page

class PresensiSiswaPage extends StatefulWidget {
  final String namaMapel, namaKelas, waktuMulai, waktuSelesai, hari, tanggal;

  const PresensiSiswaPage({
    Key? key,
    required this.namaMapel,
    required this.namaKelas,
    required this.waktuMulai,
    required this.waktuSelesai,
    required this.hari,
    required this.tanggal,
  }) : super(key: key);

  @override
  _PresensiSiswaPageState createState() => _PresensiSiswaPageState();
}

class _PresensiSiswaPageState extends State<PresensiSiswaPage> {
  int _selectedIndex = 0;
  List<bool> _hadirList = List.generate(20, (_) => false); // Attendance status

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Presensi Siswa'),
        centerTitle: true,
      ),
      body: _getSelectedPage(),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // Return the selected page based on index
  Widget _getSelectedPage() {
    return _selectedIndex == 0 ? _buildPresensiPage() : _buildOtherPage();
  }

  Widget _buildOtherPage() {
    switch (_selectedIndex) {
      case 1:
        return RiwayatSiswaPage(); // History page
      case 2:
        return DataMuridPage(); // Student Data page
      default:
        return Container(); // Default to an empty container
    }
  }

  // Build attendance page
  Widget _buildPresensiPage() {
    return Stack(
      children: [
        _buildBackgroundImage(),
        _buildOverlay(),
        _buildContent(),
      ],
    );
  }

  // Build background image
  Widget _buildBackgroundImage() {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/WaliRename.png'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // Build overlay
  Widget _buildOverlay() {
    return Container(color: Colors.black.withOpacity(0.2));
  }

  // Build content
  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildInfoCard(),
          const SizedBox(height: 20),
          _buildStudentGrid(),
        ],
      ),
    );
  }

// Membangun kartu informasi
Widget _buildInfoCard() {
  return Card(
    elevation: 4, // Menambahkan bayangan pada kartu informasi
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    child: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildLessonDetails(),
          _buildScheduleDetails(),
        ],
      ),
    ),
  );
}

  // Build lesson details
  Widget _buildLessonDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.book_rounded, color: Colors.blueAccent, size: 28),
            const SizedBox(width: 8),
            Text(widget.namaMapel, style: _textStyle(20, FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Text('Kelas: ${widget.namaKelas}', style: _textStyle(14)),
        const SizedBox(height: 8),
        Text('Tanggal: ${widget.tanggal.isNotEmpty ? widget.tanggal : 'Belum ditentukan'}', style: _textStyle(14)),
      ],
    );
  }

  // Build schedule details
  Widget _buildScheduleDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('${widget.waktuMulai} - ${widget.waktuSelesai}', style: _textStyle(14)),
        const SizedBox(height: 5),
        Text(widget.hari, style: _textStyle(14)),
      ],
    );
  }

  // Build student grid
  Widget _buildStudentGrid() {
    return Expanded(
      child: GridView.builder(
        padding: EdgeInsets.zero,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.7,
        ),
        itemCount: _hadirList.length,
        itemBuilder: (context, index) => _buildStudentCard(index),
      ),
    );
  }

 // Membangun kartu siswa
Widget _buildStudentCard(int index) {
  return Card(
    elevation: 4, // Menambahkan bayangan pada kartu siswa
    margin: const EdgeInsets.all(8),
    child: InkWell(
      onTap: () {
        setState(() {
          _hadirList[index] = !_hadirList[index];
        });
      },
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: Colors.blue[100],
              child: Icon(
                Icons.person,
                size: 20,
                color: _hadirList[index] ? Colors.blue : Colors.grey,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              'Siswa ${index + 1}', // Placeholder for student name
              style: _textStyle(12),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Icon(
              _hadirList[index] ? Icons.check_circle : Icons.check_circle_outline,
              color: _hadirList[index] ? Colors.blue : Colors.grey,
              size: 24, // Menambahkan ukuran untuk ikon indikator
            ),
          ],
        ),
      ),
    ),
  );
}


  // Build bottom navigation bar
  BottomNavigationBar _buildBottomNavigationBar() {
    return BottomNavigationBar(
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.check_circle), label: 'Presensi'),
        BottomNavigationBarItem(icon: Icon(Icons.history), label: 'Riwayat'),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Data Murid'),
      ],
      currentIndex: _selectedIndex,
      selectedItemColor: Colors.blue,
      onTap: (index) => setState(() => _selectedIndex = index),
    );
  }

  // Helper method for text style
  TextStyle _textStyle(double size, [FontWeight weight = FontWeight.normal]) {
    return TextStyle(fontSize: size, fontWeight: weight, color: Colors.black);
  }
}

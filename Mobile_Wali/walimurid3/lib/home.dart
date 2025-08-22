import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'editpassword.dart';
import 'recognition/RegistrationScreen.dart';
import 'riwayat.dart';
import 'profile.dart';

class ApiErrorHandler {
  static String getErrorMessage(dynamic error) {
    if (error.toString().contains('TimeoutException')) {
      return 'Koneksi timeout. Periksa koneksi internet Anda.';
    } else if (error.toString().contains('SocketException')) {
      return 'Tidak dapat terhubung ke server. Periksa koneksi internet.';
    } else if (error.toString().contains('FormatException')) {
      return 'Format data tidak valid dari server.';
    } else if (error.toString().contains('Server error: 404')) {
      return 'Endpoint API tidak ditemukan.';
    } else if (error.toString().contains('Server error: 500')) {
      return 'Server sedang mengalami masalah.';
    } else {
      return 'Terjadi kesalahan: ${error.toString()}';
    }
  }

  static void showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFF44336),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  String namaWali = '';
  String noHp = '';
  int _currentIndex = 0;
  String _currentTime = '';
  String _currentDate = '';
  late Timer _timer;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  List<dynamic> siswaList = [];
  String? selectedSiswaNama;
  Map<String, dynamic>? get selectedSiswa {
      if (selectedSiswaNama == null || siswaList.isEmpty) return null;
      try {
          return siswaList.firstWhere((siswa) => siswa['nama'] == selectedSiswaNama);
      } catch (e) {
          return null;
      }
  }

  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFF42A5F5);
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color backgroundBlue = Color(0xFF0D47A1);
  static const Color cardWhite = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);

  @override
  void initState() {
    super.initState();
    _initializeLocale();
    _ensureConsistentData();
    _loadUserData();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  Future<void> _ensureConsistentData() async {
    final prefs = await SharedPreferences.getInstance();
    
    String? noHp = prefs.getString('no_hp');
    String? noHpOrtu = prefs.getString('no_hp_ortu');
    
    if (noHp != null && noHpOrtu == null) {
      await prefs.setString('no_hp_ortu', noHp);
    } else if (noHpOrtu != null && noHp == null) {
      await prefs.setString('no_hp', noHpOrtu);
    }
  }

  Future<void> _initializeLocale() async {
    await initializeDateFormatting('id_ID', null);
    _updateTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      _updateTime();
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      namaWali = prefs.getString('nama_wali') ?? 'Nama Wali';
      noHp = prefs.getString('no_hp') ?? prefs.getString('no_hp_ortu') ?? 'Nomor HP';
    });
    await _fetchSiswaData();
    
    String? savedSiswaNama = prefs.getString('selected_siswa_nama');
    if (savedSiswaNama != null && siswaList.any((s) => s['nama'] == savedSiswaNama)) {
        setState(() {
            selectedSiswaNama = savedSiswaNama;
        });
    }
  }

  Future<void> _fetchSiswaData() async {
    final url = Uri.parse(
        'https://presensi-smp1.esolusindo.com/Api/ApiMobile/ApiSiswa/bynohp/$noHp');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['data'] != null && data['data'].isNotEmpty) {
          setState(() {
            siswaList = data['data'];
            if (selectedSiswaNama == null) {
                selectedSiswaNama = siswaList.first['nama'];
                _saveSelectedSiswa(siswaList.first);
            }
          });
        } else {
          print('Data siswa kosong atau tidak ditemukan.');
        }
      } else {
        print('Gagal mengambil data siswa: ${response.statusCode}');
      }
    } catch (e) {
      print('Terjadi kesalahan: $e');
      if(mounted) ApiErrorHandler.showErrorSnackBar(context, ApiErrorHandler.getErrorMessage(e));
    }
  }

  void _updateTime() {
    final now = DateTime.now();
    setState(() {
      _currentTime = DateFormat('HH:mm').format(now);
      _currentDate = DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now);
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 1) {
      if (selectedSiswa == null) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => RiwayatPage(
          selectedSiswaNis: selectedSiswa!['nis'],
          selectedSiswaNama: selectedSiswa!['nama'],
        )),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    }
  }
  
  void _navigateToRiwayat() {
    if (selectedSiswa == null) {
      ApiErrorHandler.showErrorSnackBar(context, 'Silakan pilih siswa terlebih dahulu.');
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => RiwayatPage(
        selectedSiswaNis: selectedSiswa!['nis'],
        selectedSiswaNama: selectedSiswa!['nama'],
      )),
    );
  }

  Future<void> _saveSelectedSiswa(Map<String, dynamic> siswa) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_siswa_nama', siswa['nama']);
    await prefs.setString('selected_siswa_nis', siswa['nis']);
  }

  // --- PENAMBAHAN: Fungsi untuk menangani refresh ---
  Future<void> _handleRefresh() async {
    // Memberi sedikit jeda agar animasi loading terlihat lebih mulus
    await Future.delayed(const Duration(milliseconds: 500));
    await _loadUserData();
    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: const Text('Data berhasil diperbarui'),
                backgroundColor: Colors.green,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                ),
            ),
        );
    }
  }
  // --- Akhir Penambahan ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      body: SafeArea(
        // --- PENAMBAHAN: Widget RefreshIndicator ---
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: primaryBlue,
          backgroundColor: Colors.white,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
              // Physics ditambahkan agar RefreshIndicator selalu bisa dipicu
              // bahkan ketika konten tidak cukup panjang untuk di-scroll.
              physics: const AlwaysScrollableScrollPhysics(), 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEnhancedHeader(),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSearchBar(),
                        const SizedBox(height: 24),
                        _buildWelcomeSection(),
                        const SizedBox(height: 20),
                        _buildDropdownSiswa(),
                        const SizedBox(height: 20),
                        _buildCategorySection(),
                        const SizedBox(height: 24),
                        _buildDoctorCard(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // --- Akhir Penambahan ---
      ),
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }
  
  // ... Sisa kode widget lainnya (tidak ada yang diubah dari sini) ...

  Widget _buildEnhancedHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            backgroundBlue,
            primaryBlue,
          ],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.menu,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hi, ${namaWali.split(' ')[0]}',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w300,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(
            Icons.search,
            color: Colors.grey[400],
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            'Search...',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              color: cardWhite,
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                'assets/Logo_SMPN_3_Jember.png',
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.school,
                    color: primaryBlue,
                    size: 24,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  namaWali,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  noHp,
                  style: const TextStyle(
                    fontSize: 14,
                    color: textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: primaryBlue),
                    const SizedBox(width: 4),
                    Text(
                      _currentTime,
                      style: const TextStyle(
                        fontSize: 12,
                        color: primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSiswa() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih Siswa',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          siswaList.isEmpty
              ? const Text('Memuat data...')
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: cardWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: DropdownButton<String>(
                    value: selectedSiswaNama,
                    hint: const Text('Pilih Siswa'),
                    isExpanded: true,
                    underline: Container(),
                    icon: const Icon(Icons.keyboard_arrow_down, color: primaryBlue),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textPrimary,
                    ),
                    items: siswaList.map((siswa) {
                      return DropdownMenuItem<String>(
                        value: siswa['nama'],
                        child: Text(siswa['nama']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value == null) return;
                      setState(() {
                        selectedSiswaNama = value;
                        final siswaToSave = siswaList.firstWhere((s) => s['nama'] == value);
                        _saveSelectedSiswa(siswaToSave);
                      });
                    },
                  ),
                ),
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              'See all',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildCategoryCard(
                Icons.face_retouching_natural,
                'Daftarkan\nWajah',
                '156 Siswa',
                primaryBlue,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const RegistrationScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCategoryCard(
                Icons.history_rounded,
                'Riwayat\nPresensi',
                'Lihat Detail',
                lightBlue,
                _navigateToRiwayat,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildCategoryCard(
                Icons.lock_outline_rounded,
                'Edit\nPassword',
                'Security',
                accentBlue,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const EditPasswordPage()),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategoryCard(IconData icon, String title, String subtitle, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 24),
            const SizedBox(height: 12),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDoctorCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: lightBlue.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: primaryBlue,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Siswa Terpilih',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Informasi Siswa',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: primaryBlue,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: lightBlue.withOpacity(0.1),
                  ),
                  child: const Icon(
                    Icons.person,
                    color: primaryBlue,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedSiswaNama ?? 'Pilih Siswa',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        selectedSiswa?['nama_kelas'] ?? 'SMP Negeri 1',
                        style: const TextStyle(
                          fontSize: 14,
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'NIS: ${selectedSiswa?['nis'] ?? '-'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernBottomNav() {
    return Container(
      margin: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white,
          elevation: 0,
          selectedItemColor: primaryBlue,
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history_rounded),
              label: 'Riwayat',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
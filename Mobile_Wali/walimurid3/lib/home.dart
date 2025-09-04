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
import 'pengumuman_screen.dart'; // Import pengumuman screen

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

// Core API config class (sesuaikan dengan project Anda)
class Core {
  String get ApiUrl => 'https://presensi-smp3.esolusindo.com/'; // Sesuaikan dengan URL API Anda
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
  String? selectedSiswanisn;
  String? selectedSiswaNama;
  
  // Pengumuman variables
  List<Map<String, dynamic>> ListPengumuman = [];
  bool isLoadingPengumuman = false;
  late PageController _pageController;
  
  Map<String, dynamic>? get selectedSiswa {
    if (selectedSiswanisn == null || siswaList.isEmpty) return null;
    try {
      return siswaList.firstWhere((siswa) => siswa['nisn'] == selectedSiswanisn);
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
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
    fetchPengumuman(); // Fetch pengumuman saat init
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    _pageController.dispose();
    super.dispose();
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

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      namaWali = prefs.getString('nama_wali') ?? 'Nama Wali';
      noHp = prefs.getString('no_hp') ?? prefs.getString('no_hp_ortu') ?? 'Nomor HP';
    });
    
    // Load saved student selection FIRST
    selectedSiswanisn = prefs.getString('selected_siswa_nisn');
    selectedSiswaNama = prefs.getString('selected_siswa_nama');
    
    await _fetchSiswaData();
    
    // Validate and ensure selected student still exists
    if (selectedSiswanisn != null) {
      bool siswaExists = siswaList.any((s) => s['nisn'] == selectedSiswanisn);
      if (!siswaExists && siswaList.isNotEmpty) {
        // If saved student doesn't exist, select first student
        await _selectFirstSiswa();
      }
    } else if (siswaList.isNotEmpty) {
      // If no student selected, select first one
      await _selectFirstSiswa();
    }
    
    if (mounted) setState(() {});
  }

  Future<void> _selectFirstSiswa() async {
    if (siswaList.isNotEmpty) {
      final firstSiswa = siswaList.first;
      selectedSiswanisn = firstSiswa['nisn'];
      selectedSiswaNama = firstSiswa['nama'];
      await _saveSelectedSiswa(firstSiswa);
    }
  }

  Future<void> _fetchSiswaData() async {
    final url = Uri.parse(
        'https://presensi-smp3.esolusindo.com/Api/ApiMobile/ApiSiswa/bynohp/$noHp');
    try {
      final response = await http.get(url).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['data'] != null && data['data'].isNotEmpty) {
          setState(() {
            siswaList = data['data'];
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

  // Fetch pengumuman from API
  Future<void> fetchPengumuman() async {
    setState(() {
      isLoadingPengumuman = true;
    });

    try {
      var url = Uri.parse("${Core().ApiUrl}Api/ApiMobile/ApiPengumuman/getPengumuman");
      print("Debug: Fetching pengumuman from: $url");

      var response = await http.get(url, headers: {
        "Accept": "application/json",
        "Content-Type": "application/json",
      });

      print("Debug: Response status code: ${response.statusCode}");
      print("Debug: Response body: ${response.body}");

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);

        if (jsonResponse['status'] == true) {
          var items = jsonResponse['data'];
          setState(() {
            ListPengumuman = List<Map<String, dynamic>>.from(items ?? []);
            isLoadingPengumuman = false;
          });
          print("Debug: Number of announcements received: ${ListPengumuman.length}");
        } else {
          print("Debug: API returned false status: ${jsonResponse['message']}");
          setState(() {
            ListPengumuman = [];
            isLoadingPengumuman = false;
          });
        }
      } else {
        print("Debug: HTTP Response status code: ${response.statusCode}");
        setState(() {
          ListPengumuman = [];
          isLoadingPengumuman = false;
        });
      }
    } catch (e) {
      print("Error fetching pengumuman: $e");
      setState(() {
        ListPengumuman = [];
        isLoadingPengumuman = false;
      });
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
      _navigateToRiwayat();
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
        selectedSiswaNisn: selectedSiswa!['nisn'],
        selectedSiswaNama: selectedSiswa!['nama'],
      )),
    );
  }

  Future<void> _saveSelectedSiswa(Map<String, dynamic> siswa) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_siswa_nisn', siswa['nisn']);
    await prefs.setString('selected_siswa_nama', siswa['nama']);
    await prefs.setString('selected_siswa_kelas', siswa['nama_kelas'] ?? '');
    
    // Update local state
    selectedSiswanisn = siswa['nisn'];
    selectedSiswaNama = siswa['nama'];
  }

  Future<void> _handleRefresh() async {
    await Future.delayed(const Duration(milliseconds: 500));
    await _loadUserData();
    await fetchPengumuman(); // Refresh pengumuman juga
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

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return 'Tanggal belum ditentukan';
    }
    
    try {
      DateTime parsedDate = DateTime.parse(date);
      List<String> months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      
      return '${parsedDate.day} ${months[parsedDate.month - 1]} ${parsedDate.year}';
    } catch (e) {
      return 'Tanggal tidak valid';
    }
  }

  // Helper method untuk validasi URL gambar
  String? _getValidImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }
    
    // Jika URL sudah lengkap, gunakan apa adanya
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    
    // Ambil base URL dari Core
    String baseUrl = Core().ApiUrl;
    
    // Pastikan base URL tidak berakhir dengan slash
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    
    // Buat URL lengkap
    String fullUrl = "$baseUrl/public_html/foto/foto_pengumuman/$imageUrl";
    
    return fullUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _handleRefresh,
          color: primaryBlue,
          backgroundColor: Colors.white,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SingleChildScrollView(
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
                        _buildCombinedUserCard(), // Kartu gabungan untuk wali dan siswa
                        const SizedBox(height: 24),
                        _buildPengumumanSection(), // <<< PENGUMUMAN DIPINDAHKAN KE SINI
                        const SizedBox(height: 24),
                        _buildCategorySection(), // Bagian kategori
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

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

  // ### MODIFIED WIDGET ###
  // Kartu gabungan yang lebih ringkas untuk info wali dan dropdown siswa
  Widget _buildCombinedUserCard() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bagian info pengguna
          Row(
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
          
          const SizedBox(height: 16), // Mengurangi jarak vertikal
          
          // Bagian pemilihan siswa (dibuat lebih ringkas)
          siswaList.isEmpty
              ? const Text('Memuat data siswa...')
              : Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: cardWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: DropdownButton<String>(
                    value: selectedSiswanisn,
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
                        value: siswa['nisn'],
                        child: Text(siswa['nama']),
                      );
                    }).toList(),
                    onChanged: (value) async {
                      if (value == null) return;
                      final siswaToSave = siswaList.firstWhere((s) => s['nisn'] == value);
                      await _saveSelectedSiswa(siswaToSave);
                      setState(() {});
                    },
                  ),
                ),
          
          // Menampilkan info siswa yang dipilih jika tersedia
          if (selectedSiswa != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: lightBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: lightBlue.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: primaryBlue.withOpacity(0.1),
                    ),
                    child: const Icon(
                      Icons.person,
                      color: primaryBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          selectedSiswaNama ?? 'Siswa Terpilih',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        Text(
                          selectedSiswa?['nama_kelas'] ?? 'Kelas',
                          style: const TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                        Text(
                          'NISN: ${selectedSiswa?['nisn'] ?? '-'}',
                          style: const TextStyle(
                            fontSize: 11,
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
        ],
      ),
    );
  }

  Widget _buildCategorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Category',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
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

  // Bagian Pengumuman
  Widget _buildPengumumanSection() {
    return Container(
      padding: const EdgeInsets.all(20.0),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pengumuman Terbaru',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const PengumumanScreen(),
                    ),
                  );
                },
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 12.0,
                    color: primaryBlue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isLoadingPengumuman)
            const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(
                  color: primaryBlue,
                ),
              ),
            )
          else if (ListPengumuman.isEmpty)
            Container(
              padding: const EdgeInsets.all(15.0),
              width: double.infinity,
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: primaryBlue,
                    size: 24,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Tidak ada pengumuman terbaru",
                      style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 120,
              child: PageView.builder(
                controller: _pageController,
                scrollDirection: Axis.horizontal,
                itemCount: ListPengumuman.length > 3 ? 3 : ListPengumuman.length,
                itemBuilder: (context, index) {
                  final item = ListPengumuman[index];
                  final String? imageUrl = _getValidImageUrl(item['gambar']);

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const PengumumanScreen(),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 10.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.0),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Background image or color
                            if (imageUrl != null && imageUrl.isNotEmpty)
                              Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Container(
                                    color: primaryBlue.withOpacity(0.1),
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        color: primaryBlue,
                                      ),
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: primaryBlue.withOpacity(0.1),
                                    child: const Center(
                                      child: Icon(
                                        Icons.broken_image,
                                        color: primaryBlue,
                                        size: 40,
                                      ),
                                    ),
                                  );
                                },
                              )
                            else
                              Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      primaryBlue.withOpacity(0.8),
                                      lightBlue.withOpacity(0.6),
                                    ],
                                  ),
                                ),
                              ),

                            // Overlay for better text readability
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.black.withOpacity(0.6),
                                    Colors.black.withOpacity(0.3),
                                    Colors.transparent
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  stops: const [0.0, 0.4, 1.0],
                                ),
                              ),
                            ),

                            // Content text
                            Positioned(
                              bottom: 10,
                              left: 12,
                              right: 12,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    item['judul'] ?? 'Judul tidak tersedia',
                                    style: const TextStyle(
                                      fontSize: 14.0,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      shadows: [
                                        Shadow(
                                          blurRadius: 4.0,
                                          color: Colors.black54,
                                          offset: Offset(1.0, 1.0),
                                        )
                                      ],
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item['isi'] ?? 'Konten tidak tersedia',
                                    style: TextStyle(
                                      fontSize: 11.0,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  if (item['tanggal'] != null)
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.access_time_filled,
                                          size: 12,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          _formatDate(item['tanggal']),
                                          style: const TextStyle(
                                            fontSize: 10.0,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          if (ListPengumuman.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Center(
                child: Text(
                  "Geser untuk melihat pengumuman lainnya • ${ListPengumuman.length} total",
                  style: const TextStyle(
                    fontSize: 10.0,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
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
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'home.dart';
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

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  _RiwayatPageState createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> with TickerProviderStateMixin {
  int _currentIndex = 1;
  List<dynamic> riwayatList = [];
  bool isLoading = true;
  String errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  // Enhanced Color Palette
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFF42A5F5);
  static const Color accentBlue = Color(0xFF2196F3);
  static const Color backgroundBlue = Color(0xFF0D47A1);
  static const Color cardWhite = Color(0xFFFAFAFA);
  static const Color textPrimary = Color(0xFF1A1A1A);
  static const Color textSecondary = Color(0xFF757575);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFF9800);
  static const Color dangerRed = Color(0xFFF44336);

  @override
  void initState() {
    super.initState();
    _ensureConsistentData();
    _fetchRiwayat();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();
  }

  Future<void> _ensureConsistentData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Pastikan konsistensi data nomor HP
    String? noHp = prefs.getString('no_hp');
    String? noHpOrtu = prefs.getString('no_hp_ortu');
    
    if (noHp != null && noHpOrtu == null) {
      await prefs.setString('no_hp_ortu', noHp);
    } else if (noHpOrtu != null && noHp == null) {
      await prefs.setString('no_hp', noHpOrtu);
    }
    
    // Debug log
    print('no_hp: ${prefs.getString('no_hp')}');
    print('no_hp_ortu: ${prefs.getString('no_hp_ortu')}');
    print('nama_wali: ${prefs.getString('nama_wali')}');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchRiwayat() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      String? noHpOrtu = prefs.getString('no_hp_ortu') ?? prefs.getString('no_hp');

      if (noHpOrtu == null || noHpOrtu.isEmpty) {
        setState(() {
          isLoading = false;
          errorMessage = 'Nomor HP orang tua tidak ditemukan. Silakan login kembali.';
        });
        return;
      }

      print('Fetching data for phone: $noHpOrtu'); // Debug log

      // PERBAIKAN: URL API yang konsisten
      final response = await http.get(
        Uri.parse('https://presensi-smp1.esolusindo.com/Api/ApiMobile/ApiAbsen/ByNoHp/$noHpOrtu'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['status'] == true) {
          setState(() {
            riwayatList = responseData['data'] ?? [];
            isLoading = false;
          });
          
          print('Data loaded successfully: ${riwayatList.length} records'); // Debug log
        } else {
          setState(() {
            riwayatList = [];
            isLoading = false;
            errorMessage = responseData['message'] ?? 'Gagal mengambil data';
          });
        }
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching riwayat: $e');
      setState(() {
        isLoading = false;
        errorMessage = ApiErrorHandler.getErrorMessage(e);
      });
      ApiErrorHandler.showErrorSnackBar(context, errorMessage);
    }
  }

  // Test API Connection - untuk debugging
  Future<void> _testApiConnection() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      String? noHpOrtu = prefs.getString('no_hp_ortu') ?? prefs.getString('no_hp');
      
      final response = await http.get(
        Uri.parse('https://presensi-smp1.esolusindo.com/Api/ApiMobile/ApiAbsen/ByNoHp/${noHpOrtu ?? "0855555"}'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      
      print('Test API Response: ${response.statusCode}');
      print('Test API Body: ${response.body}');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API Test: ${response.statusCode} - ${response.body}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e) {
      print('Test API Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('API Test Error: $e'),
          backgroundColor: dangerRed,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  // Hitung statistik dari data riwayat
  Map<String, int> _calculateStats() {
    Map<String, int> stats = {
      'hadir': 0,
      'terlambat': 0,
      'alpha': 0,
      'sakit': 0,
      'izin': 0,
    };

    for (var item in riwayatList) {
      String status = (item['status'] ?? 'alpha').toString().toLowerCase();
      if (stats.containsKey(status)) {
        stats[status] = stats[status]! + 1;
      } else if (status.contains('hadir')) {
        stats['hadir'] = stats['hadir']! + 1;
      }
    }

    return stats;
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    }
  }

  // Handler untuk back button - PERBAIKAN
  void _handleBackButton() {
    // Kembali ke HomePage alih-alih Navigator.pop()
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'hadir':
        return successGreen;
      case 'terlambat':
        return warningOrange;
      case 'sakit':
      case 'izin':
        return primaryBlue;
      case 'alpha':
        return dangerRed;
      default:
        return textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'hadir':
        return Icons.check_circle_outline;
      case 'terlambat':
        return Icons.access_time;
      case 'sakit':
      case 'izin':
        return Icons.local_hospital_outlined;
      case 'alpha':
        return Icons.cancel_outlined;
      default:
        return Icons.help_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundBlue,
      body: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.3),
          end: Offset.zero,
        ).animate(_slideAnimation),
        child: FadeTransition(
          opacity: _slideAnimation,
          child: SafeArea(
            child: Column(
              children: [
                _buildEnhancedHeader(),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    decoration: const BoxDecoration(
                      color: cardWhite,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                    ),
                    child: _buildContent(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildModernBottomNav(),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: primaryBlue),
            SizedBox(height: 16),
            Text(
              'Memuat data riwayat...',
              style: TextStyle(
                color: textSecondary,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    if (errorMessage.isNotEmpty && riwayatList.isEmpty) {
      return _buildErrorState();
    }

    if (riwayatList.isEmpty) {
      return _buildEmptyState();
    }

    return _buildRiwayatList();
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: dangerRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.error_outline,
              size: 64,
              color: dangerRed,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Gagal Memuat Data',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              errorMessage,
              style: const TextStyle(
                fontSize: 14,
                color: textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton.icon(
                onPressed: _fetchRiwayat,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              ElevatedButton.icon(
                onPressed: _testApiConnection,
                icon: const Icon(Icons.bug_report),
                label: const Text('Test API'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: warningOrange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _handleBackButton, // PERBAIKAN: gunakan handler khusus
                  icon: const Icon(
                    Icons.arrow_back_ios,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
              const Text(
                'Riwayat Presensi',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  onPressed: _fetchRiwayat,
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildStatsCards(),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    Map<String, int> stats = _calculateStats();
    
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.check_circle,
            title: 'Hadir',
            value: '${stats['hadir']}',
            color: successGreen,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.access_time,
            title: 'Terlambat',
            value: '${stats['terlambat']}',
            color: warningOrange,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            icon: Icons.cancel,
            title: 'Alpha',
            value: '${stats['alpha']}',
            color: dangerRed,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRiwayatList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Riwayat Terbaru',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${riwayatList.length} Data',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primaryBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchRiwayat,
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: riwayatList.length,
              itemBuilder: (context, index) {
                final item = riwayatList[index];
                return _buildRiwayatCard(item, index);
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRiwayatCard(Map<String, dynamic> item, int index) {
    final status = item['status']?.toString() ?? 'Unknown';
    final statusColor = _getStatusColor(status);
    final statusIcon = _getStatusIcon(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            // Handle tap - bisa ditambahkan detail view
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Detail Presensi'),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Nama: ${item['nama'] ?? '-'}'),
                    Text('NIS: ${item['nis'] ?? '-'}'),
                    Text('Tanggal: ${item['tanggal'] ?? '-'}'),
                    Text('Status: ${item['status'] ?? '-'}'),
                    Text('Waktu Masuk: ${item['waktu_masuk'] ?? '-'}'),
                    Text('Waktu Keluar: ${item['waktu_keluar'] ?? '-'}'),
                    Text('Keterangan: ${item['keterangan'] ?? '-'}'),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        statusIcon,
                        color: statusColor,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['tanggal']?.toString() ?? '-',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['keterangan']?.toString() ?? '-',
                            style: const TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: statusColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildTimeInfo(
                        'Masuk',
                        item['waktu_masuk']?.toString() ?? '-',
                        Icons.login,
                        primaryBlue,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildTimeInfo(
                        'Pulang',
                        item['waktu_keluar']?.toString() ?? '-',
                        Icons.logout,
                        accentBlue,
                      ),
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

  Widget _buildTimeInfo(String label, String time, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 10,
                  color: textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                time,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(
              Icons.history,
              size: 64,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Belum Ada Riwayat',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Riwayat presensi akan muncul di sini',
            style: TextStyle(
              fontSize: 14,
              color: textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchRiwayat,
            icon: const Icon(Icons.refresh),
            label: const Text('Muat Ulang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
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
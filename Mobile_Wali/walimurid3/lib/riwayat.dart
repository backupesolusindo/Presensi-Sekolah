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
  final String? selectedSiswaNisn;
  final String? selectedSiswaNama;

  const RiwayatPage({
    super.key,
    this.selectedSiswaNisn,
    this.selectedSiswaNama,
  });

  @override
  _RiwayatPageState createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> with TickerProviderStateMixin {
  int _currentIndex = 1;
  List<dynamic> allRiwayatList = [];
  List<dynamic> filteredRiwayatList = [];
  bool isLoading = true;
  String errorMessage = '';
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;

  String? _currentNisn;
  String? _currentNama;

  // Color palette
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
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );
    _animationController.forward();

    _initializeSiswaData();
  }

  Future<void> _initializeSiswaData() async {
    // Priority: Use passed parameters first, then SharedPreferences
    if (widget.selectedSiswaNisn != null && widget.selectedSiswaNama != null) {
      _currentNisn = widget.selectedSiswaNisn;
      _currentNama = widget.selectedSiswaNama;
      
      // Save to SharedPreferences for consistency
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('selected_siswa_nisn', _currentNisn!);
      await prefs.setString('selected_siswa_nama', _currentNama!);
    } else {
      // Fallback to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      _currentNisn = prefs.getString('selected_siswa_nisn');
      _currentNama = prefs.getString('selected_siswa_nama');
    }
    
    if (mounted) {
      setState(() {});
      _fetchRiwayat();
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _fetchRiwayat() async {
    if (_currentNisn == null || _currentNisn!.isEmpty) {
        setState(() {
            isLoading = false;
            errorMessage = 'Siswa belum dipilih. Silakan kembali ke Beranda dan pilih siswa.';
        });
        return;
    }
    
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

      final response = await http.get(
        Uri.parse('https://presensi-smp3.esolusindo.com/Api/ApiMobile/ApiAbsen/ByNoHp/$noHpOrtu'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['status'] == true && responseData['data'] != null) {
          allRiwayatList = responseData['data'];
          // Filter by selected student NIS
          filteredRiwayatList = allRiwayatList
              .where((item) => item['nisn'] == _currentNisn)
              .toList();

          setState(() {
            isLoading = false;
          });
        } else {
          setState(() {
            allRiwayatList = [];
            filteredRiwayatList = [];
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
      if(mounted) ApiErrorHandler.showErrorSnackBar(context, errorMessage);
    }
  }

  Map<String, int> _calculateStats() {
    Map<String, int> stats = {
      'hadir': 0, 'terlambat': 0, 'alpha': 0, 'sakit': 0, 'izin': 0,
    };
    for (var item in filteredRiwayatList) {
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

  void _handleBackButton() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'hadir': return successGreen;
      case 'terlambat': return warningOrange;
      case 'sakit': case 'izin': return primaryBlue;
      case 'alpha': return dangerRed;
      default: return textSecondary;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'hadir': return Icons.check_circle_outline;
      case 'terlambat': return Icons.access_time;
      case 'sakit': case 'izin': return Icons.local_hospital_outlined;
      case 'alpha': return Icons.cancel_outlined;
      default: return Icons.help_outline;
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
            Text('Memuat data riwayat...', style: TextStyle(color: textSecondary, fontSize: 14)),
          ],
        ),
      );
    }

    if (errorMessage.isNotEmpty && filteredRiwayatList.isEmpty) {
      return _buildErrorState();
    }

    if (filteredRiwayatList.isEmpty) {
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
            decoration: BoxDecoration(color: dangerRed.withOpacity(0.1), borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.error_outline, size: 64, color: dangerRed),
          ),
          const SizedBox(height: 24),
          const Text('Gagal Memuat Data', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(errorMessage, style: const TextStyle(fontSize: 14, color: textSecondary), textAlign: TextAlign.center),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchRiwayat,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
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
          begin: Alignment.topCenter, end: Alignment.bottomCenter,
          colors: [backgroundBlue, primaryBlue],
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: IconButton(
                  onPressed: _handleBackButton,
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
                  padding: EdgeInsets.zero,
                ),
              ),
              Column(
                  children: [
                      const Text(
                        'Riwayat Presensi',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      if (_currentNama != null)
                        Text(
                          _currentNama!,
                          style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.8)),
                        ),
                  ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                child: IconButton(
                  onPressed: _fetchRiwayat,
                  icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
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
        Expanded(child: _buildStatCard(icon: Icons.check_circle, title: 'Hadir', value: '${stats['hadir']}', color: successGreen)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(icon: Icons.access_time, title: 'Terlambat', value: '${stats['terlambat']}', color: warningOrange)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(icon: Icons.cancel, title: 'Alpha', value: '${stats['alpha']}', color: dangerRed)),
      ],
    );
  }

  Widget _buildStatCard({required IconData icon, required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12, color: textSecondary, fontWeight: FontWeight.w500)),
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
              const Text('Riwayat Terbaru', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Text('${filteredRiwayatList.length} Data', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: primaryBlue)),
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
              itemCount: filteredRiwayatList.length,
              itemBuilder: (context, index) {
                final item = filteredRiwayatList[index];
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Detail Presensi'),
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Nama: ${item['nama'] ?? '-'}'),
                    Text('NISN: ${item['nisn'] ?? '-'}'),
                    Text('Tanggal: ${item['tanggal'] ?? '-'}'),
                    Text('Status: ${item['status'] ?? '-'}'),
                    Text('Waktu Masuk: ${item['waktu_masuk'] ?? '-'}'),
                    Text('Waktu Keluar: ${item['waktu_keluar'] ?? '-'}'),
                    Text('Keterangan: ${item['keterangan'] ?? '-'}'),
                  ],
                ),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup'))],
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
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Icon(statusIcon, color: statusColor, size: 20),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['tanggal']?.toString() ?? '-', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textPrimary)),
                          const SizedBox(height: 4),
                          Text(item['keterangan']?.toString() ?? '-', style: const TextStyle(fontSize: 12, color: textSecondary)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTimeInfo('Masuk', item['waktu_masuk']?.toString() ?? '-', Icons.login, primaryBlue)),
                    const SizedBox(width: 16),
                    Expanded(child: _buildTimeInfo('Pulang', item['waktu_keluar']?.toString() ?? '-', Icons.logout, accentBlue)),
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
              Text(label, style: const TextStyle(fontSize: 10, color: textSecondary, fontWeight: FontWeight.w500)),
              Text(time, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
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
            decoration: BoxDecoration(color: primaryBlue.withOpacity(0.1), borderRadius: BorderRadius.circular(24)),
            child: const Icon(Icons.history, size: 64, color: primaryBlue),
          ),
          const SizedBox(height: 24),
          const Text('Belum Ada Riwayat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textPrimary)),
          const SizedBox(height: 8),
          const Text('Riwayat presensi siswa ini akan muncul di sini', style: TextStyle(fontSize: 14, color: textSecondary), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _fetchRiwayat,
            icon: const Icon(Icons.refresh),
            label: const Text('Muat Ulang'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue, foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        color: Colors.white, borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onItemTapped,
          backgroundColor: Colors.white, elevation: 0,
          selectedItemColor: primaryBlue, unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          type: BottomNavigationBarType.fixed,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_rounded), label: 'Beranda'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded), label: 'Riwayat'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded), label: 'Profil'),
          ],
        ),
      ),
    );
  }
}
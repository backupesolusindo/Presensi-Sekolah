import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

// Core API config class
class Core {
  String get ApiUrl => 'https://presensi-smp3.esolusindo.com/'; // Sesuaikan dengan URL API Anda
}

class PengumumanScreen extends StatefulWidget {
  const PengumumanScreen({super.key});

  @override
  _PengumumanScreenState createState() => _PengumumanScreenState();
}

class _PengumumanScreenState extends State<PengumumanScreen> {
  List<Map<String, dynamic>> _listPengumuman = [];
  bool _isLoading = true;
  String _currentFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchPengumuman();
  }

  /// Fetches announcements from the API based on the filter.
  Future<void> _fetchPengumuman({String filter = 'all'}) async {
    setState(() {
      _isLoading = true;
      _currentFilter = filter;
    });

    try {
      String endpoint;
      switch (filter) {
        case 'active':
          endpoint = "Api/ApiMobile/ApiPengumuman/getPengumumanAktif";
          break;
        case 'all':
        default:
          endpoint = "Api/ApiMobile/ApiPengumuman/getPengumuman";
      }

      var url = Uri.parse("${Core().ApiUrl}$endpoint");
      var response = await http.get(url);

      if (response.statusCode == 200) {
        var jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == true && jsonResponse['data'] != null) {
          setState(() {
            _listPengumuman = List<Map<String, dynamic>>.from(jsonResponse['data']);
          });
        } else {
          setState(() {
            _listPengumuman = [];
          });
        }
      } else {
        throw Exception('Failed to load announcements. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print("Error fetching pengumuman: $e");
      setState(() {
        _listPengumuman = [];
      });
      _showSnackbar('Gagal memuat pengumuman. Silakan coba lagi.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  /// Formats a date string to 'dd MMM yyyy' format.
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'Tanggal tidak tersedia';
    }
    try {
      DateTime date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      print("Error parsing date: $e");
      return dateString;
    }
  }

  /// Checks if an announcement is currently active.
  bool _isPengumumanActive(Map<String, dynamic> pengumuman) {
    String? tanggalSelesai = pengumuman['tanggal_selesai'];
    if (tanggalSelesai == null || tanggalSelesai.isEmpty) {
      return true;
    }
    try {
      DateTime selesai = DateTime.parse(tanggalSelesai);
      return DateTime.now().isBefore(selesai);
    } catch (e) {
      return true;
    }
  }

  /// Gets the status text for an announcement.
  String _getStatusPengumuman(Map<String, dynamic> pengumuman) {
    String? tanggalSelesai = pengumuman['tanggal_selesai'];
    if (tanggalSelesai == null || tanggalSelesai.isEmpty) {
      return 'Permanen';
    }
    try {
      DateTime selesai = DateTime.parse(tanggalSelesai);
      DateTime now = DateTime.now();

      if (now.isAfter(selesai)) {
        return 'Berakhir';
      } else {
        Duration difference = selesai.difference(now);
        if (difference.inDays > 0) {
          return '${difference.inDays} hari lagi';
        } else if (difference.inHours > 0) {
          return '${difference.inHours} jam lagi';
        } else if (difference.inMinutes > 0) {
          return '${difference.inMinutes} menit lagi';
        } else {
          return 'Segera berakhir';
        }
      }
    } catch (e) {
      return 'Permanen';
    }
  }

  /// Gets the status color for an announcement.
  Color _getStatusColor(Map<String, dynamic> pengumuman) {
    String? tanggalSelesai = pengumuman['tanggal_selesai'];
    if (tanggalSelesai == null || tanggalSelesai.isEmpty) {
      return Colors.green;
    }
    try {
      DateTime selesai = DateTime.parse(tanggalSelesai);
      DateTime now = DateTime.now();

      if (now.isAfter(selesai)) {
        return Colors.red;
      } else {
        Duration difference = selesai.difference(now);
        if (difference.inDays <= 1) {
          return Colors.orange;
        } else if (difference.inDays <= 7) {
          return Colors.amber;
        } else {
          return Colors.green;
        }
      }
    } catch (e) {
      return Colors.green;
    }
  }

  /// Helper method to validate and construct the full image URL.
  String? _getValidImageUrl(String? imageUrl) {
    if (imageUrl == null || imageUrl.isEmpty) {
      return null;
    }
    if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
      return imageUrl;
    }
    String baseUrl = Core().ApiUrl;
    if (baseUrl.endsWith('/')) {
      baseUrl = baseUrl.substring(0, baseUrl.length - 1);
    }
    return "$baseUrl/public_html/foto/foto_pengumuman/$imageUrl";
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showDetailPengumuman(Map<String, dynamic> pengumuman) {
    final String? imageUrl = _getValidImageUrl(pengumuman['gambar']);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          contentPadding: const EdgeInsets.all(0),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (imageUrl != null)
                  ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 180,
                          color: Colors.grey[200],
                          child: const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pengumuman['judul'] ?? 'Judul tidak tersedia',
                        style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _formatDate(pengumuman['tanggal']),
                        style: Theme.of(context).textTheme.bodySmall!.copyWith(
                              color: Colors.grey,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        pengumuman['isi'] ?? 'Konten tidak tersedia',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.blue[600],
        title: const Text('Pengumuman', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 20)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.light,
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) => _fetchPengumuman(filter: value),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'all',
                child: Row(
                  children: [
                    Icon(Icons.list, color: _currentFilter == 'all' ? Colors.blue : Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Semua Pengumuman'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'active',
                child: Row(
                  children: [
                    Icon(Icons.schedule, color: _currentFilter == 'active' ? Colors.blue : Colors.grey),
                    const SizedBox(width: 8),
                    const Text('Hanya Aktif'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.blue[600]!, Colors.blue[400]!, Colors.white],
            stops: const [0.0, 0.15, 0.4],
          ),
        ),
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : RefreshIndicator(
                onRefresh: () => _fetchPengumuman(filter: _currentFilter),
                child: _listPengumuman.isEmpty ? _buildEmptyState() : _buildPengumumanList(),
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.1),
                    blurRadius: 20,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Icon(
                Icons.announcement_outlined,
                size: 80,
                color: Colors.blue[300],
              ),
            ),
            const SizedBox(height: 30),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                children: [
                  Text(
                    'Tidak Ada Pengumuman',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Colors.blue[800],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada pengumuman yang tersedia saat ini.\nSilakan cek kembali nanti.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blue[600],
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPengumumanList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _listPengumuman.length,
      itemBuilder: (context, index) {
        final pengumuman = _listPengumuman[index];
        return _buildPengumumanCard(pengumuman, index);
      },
    );
  }

  Widget _buildPengumumanCard(Map<String, dynamic> pengumuman, int index) {
    bool isActive = _isPengumumanActive(pengumuman);
    String status = _getStatusPengumuman(pengumuman);
    Color statusColor = _getStatusColor(pengumuman);
    final String? imageUrl = _getValidImageUrl(pengumuman['gambar']);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: !isActive ? Border.all(color: Colors.red.withOpacity(0.3), width: 1) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.08),
            blurRadius: 20,
            spreadRadius: 1,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showDetailPengumuman(pengumuman),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: Stack(
                    children: [
                      Image.network(
                        imageUrl,
                        height: 180,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 180,
                            width: double.infinity,
                            color: Colors.grey[200],
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                    : null,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 180,
                            width: double.infinity,
                            color: Colors.grey[100],
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image_outlined, color: Colors.grey[400], size: 40),
                                const SizedBox(height: 8),
                                Text('Gambar tidak dapat dimuat', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                              ],
                            ),
                          );
                        },
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isActive ? [Colors.blue[400]!, Colors.blue[600]!] : [Colors.grey[400]!, Colors.grey[600]!],
                            ),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: (isActive ? Colors.blue : Colors.grey).withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Icon(
                            isActive ? Icons.announcement : Icons.announcement_outlined,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                pengumuman['judul'] ?? 'Judul tidak tersedia',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: isActive ? Colors.grey[800] : Colors.grey[500],
                                  decoration: !isActive ? TextDecoration.lineThrough : null,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  _buildInfoChip(
                                    _formatDate(pengumuman['tanggal']),
                                    Icons.access_time,
                                    Colors.blue[600]!,
                                  ),
                                  const SizedBox(width: 8),
                                  _buildInfoChip(
                                    status,
                                    status == 'Berakhir'
                                        ? Icons.schedule_outlined
                                        : status == 'Permanen'
                                            ? Icons.all_inclusive
                                            : Icons.timer_outlined,
                                    statusColor,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      pengumuman['isi'] ?? 'Konten tidak tersedia',
                      style: TextStyle(
                        fontSize: 14,
                        color: isActive ? Colors.grey[600] : Colors.grey[400],
                        height: 1.6,
                      ),
                      maxLines: imageUrl != null && imageUrl.isNotEmpty ? 2 : 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
  import 'dart:convert';
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:http/http.dart' as http;
  import 'package:mobile_presensi_kdtg/core.dart'; // Pastikan path import ini benar

  class PengumumanScreen extends StatefulWidget {
    const PengumumanScreen({super.key});

    @override
    _PengumumanScreenState createState() => _PengumumanScreenState();
  }

  class _PengumumanScreenState extends State<PengumumanScreen> {
    List<Map<String, dynamic>> listPengumuman = [];
    bool isLoading = true;

    @override
    void initState() {
      super.initState();
      // Test URL configuration
      print("=== URL CONFIGURATION TEST ===");
      print("Core().ApiUrl: '${Core().ApiUrl}'");
      print("Test image URL: '${_getValidImageUrl('test.jpg')}'");
      print("================================");
      fetchPengumuman();
    }

    Future<void> fetchPengumuman() async {
      setState(() {
        isLoading = true;
      });

      try {
        // Mengambil data dari API yang sudah diupdate dengan field gambar
        var url = Uri.parse("${Core().ApiUrl}ApiMobile/ApiPengumuman/getPengumuman");
        var response = await http.get(url);
        
        print("Debug: Response status code: ${response.statusCode}");
        print("Debug: Response body: ${response.body}");
        
        if (response.statusCode == 200) {
          var jsonResponse = json.decode(response.body);
          if (jsonResponse['status'] == true && jsonResponse['data'] != null) {
            setState(() {
              listPengumuman = List<Map<String, dynamic>>.from(jsonResponse['data']);
              isLoading = false;
            });
            print("Debug: Number of announcements received: ${listPengumuman.length}");
            
            // Debug untuk melihat struktur data yang diterima
            for (var item in listPengumuman) {
              print("Debug: Pengumuman data: $item");
              print("Debug: Gambar field: '${item['gambar']}'");
              if (item['gambar'] != null) {
                print("Debug: Processed image URL: '${_getValidImageUrl(item['gambar'])}'");
              }
            }
          } else {
            print("Debug: API returned false status or null data");
            setState(() {
              listPengumuman = [];
              isLoading = false;
            });
          }
        } else {
          print("Debug: HTTP Response status code: ${response.statusCode}");
          setState(() {
            listPengumuman = [];
            isLoading = false;
          });
        }
      } catch (e) {
        print("Error fetching pengumuman: $e");
        setState(() {
          listPengumuman = [];
          isLoading = false;
        });
      }
    }

    // Method untuk mengecek apakah pengumuman masih aktif
    bool _isPengumumanActive(Map<String, dynamic> pengumuman) {
      String? tanggalSelesai = pengumuman['tanggal_selesai'];
      if (tanggalSelesai == null || tanggalSelesai.isEmpty) {
        return true; // Jika tidak ada tanggal selesai, dianggap selalu aktif
      }
      
      try {
        DateTime selesai = DateTime.parse(tanggalSelesai);
        DateTime now = DateTime.now();
        return now.isBefore(selesai);
      } catch (e) {
        return true; // Jika error parsing, dianggap aktif
      }
    }

    // Method untuk mendapatkan status pengumuman
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

    // Method untuk mendapatkan warna status
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

    // Method helper untuk validasi URL gambar
    String? _getValidImageUrl(String? imageUrl) {
      if (imageUrl == null || imageUrl.isEmpty) {
        return null;
      }
      
      print("Debug: Input imageUrl: '$imageUrl'");
      
      // Jika URL sudah lengkap, gunakan apa adanya
      if (imageUrl.startsWith('http://') || imageUrl.startsWith('https://')) {
        print("Debug: URL sudah lengkap: '$imageUrl'");
        return imageUrl;
      }
      
      // Ambil base URL dari Core
      String baseUrl = Core().ApiUrl;
      print("Debug: Base URL dari Core: '$baseUrl'");
      
      // Pastikan base URL tidak berakhir dengan slash
      if (baseUrl.endsWith('/')) {
        baseUrl = baseUrl.substring(0, baseUrl.length - 1);
      }
      
      // Buat URL lengkap
      String fullUrl = "$baseUrl/application/document/foto_pengumuman/$imageUrl";
      print("Debug: Final URL yang dibentuk: '$fullUrl'");
      
      
      return fullUrl;
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.blue[600],
          title: const Text(
            'Pengumuman',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back,
              color: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          elevation: 0,
          systemOverlayStyle: const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.light,
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.filter_list, color: Colors.white),
              onSelected: (String value) {
                if (value == 'active') {
                  _filterPengumumanAktif();
                } else if (value == 'all') {
                  fetchPengumuman();
                }
              },
              itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                const PopupMenuItem<String>(
                  value: 'all',
                  child: Row(
                    children: [
                      Icon(Icons.list, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Semua Pengumuman'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'active',
                  child: Row(
                    children: [
                      Icon(Icons.schedule, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Hanya Aktif'),
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
              colors: [
                Colors.blue[600]!,
                Colors.blue[400]!,
                Colors.white,
              ],
              stops: const [0.0, 0.15, 0.4],
            ),
          ),
          child: isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    strokeWidth: 3.0,
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchPengumuman,
                  color: Colors.blue[600],
                  backgroundColor: Colors.white,
                  child: listPengumuman.isEmpty
                      ? _buildEmptyState()
                      : _buildPengumumanList(),
                ),
        ),
      );
    }

    Future<void> _filterPengumumanAktif() async {
      setState(() {
        isLoading = true;
      });

      try {
        var url = Uri.parse("${Core().ApiUrl}ApiMobile/ApiPengumuman/getPengumumanAktif");
        var response = await http.get(url);
        
        if (response.statusCode == 200) {
          var jsonResponse = json.decode(response.body);
          if (jsonResponse['status'] == true && jsonResponse['data'] != null) {
            setState(() {
              listPengumuman = List<Map<String, dynamic>>.from(jsonResponse['data']);
              isLoading = false;
            });
          } else {
            setState(() {
              listPengumuman = [];
              isLoading = false;
            });
          }
        } else {
          setState(() {
            listPengumuman = [];
            isLoading = false;
          });
        }
      } catch (e) {
        print("Error fetching pengumuman aktif: $e");
        setState(() {
          listPengumuman = [];
          isLoading = false;
        });
      }
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
        itemCount: listPengumuman.length,
        itemBuilder: (context, index) {
          final pengumuman = listPengumuman[index];
          return _buildPengumumanCard(pengumuman, index);
        },
      );
    }

    Widget _buildPengumumanCard(Map<String, dynamic> pengumuman, int index) {
      bool isActive = _isPengumumanActive(pengumuman);
      String status = _getStatusPengumuman(pengumuman);
      Color statusColor = _getStatusColor(pengumuman);

      // Ambil URL gambar dan validasi
      final String? imageUrl = _getValidImageUrl(pengumuman['gambar']);
      
      print("Debug: Original image data for card $index: ${pengumuman['gambar']}"); 
      print("Debug: Processed image URL for card $index: $imageUrl"); 

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
            onTap: () {
              _showDetailPengumuman(pengumuman);
            },
            // Menggunakan Column agar bisa menumpuk gambar dan konten
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Widget untuk menampilkan gambar
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
                          // Tambahkan headers untuk request
                          headers: const {
                            'User-Agent': 'Flutter App',
                          },
                          // Tampilkan loading indicator saat gambar dimuat
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 180,
                              width: double.infinity,
                              color: Colors.grey[200],
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Memuat gambar...',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                          // Tampilkan icon error jika gambar gagal dimuat
                          errorBuilder: (context, error, stackTrace) {
                            print("Debug: Error loading image $imageUrl: $error");
                            print("Debug: Original gambar data: '${pengumuman['gambar']}'");
                            print("Debug: Core().ApiUrl: '${Core().ApiUrl}'");
                            return Container(
                              height: 180,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[100],
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.grey[400],
                                    size: 40,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Gambar tidak dapat dimuat',
                                    style: TextStyle(
                                      color: Colors.grey[500],
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      'URL: ${imageUrl.length > 40 ? '${imageUrl.substring(0, 40)}...' : imageUrl}',
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 9,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Original: ${pengumuman['gambar'] ?? 'null'}',
                                    style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 8,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        // Overlay gradient untuk readability teks jika ada teks di atas gambar
                        if (!isActive)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.3),
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(20),
                                  topRight: Radius.circular(20),
                                ),
                              ),
                            ),
                          ),
                        // Badge status di pojok kanan atas gambar
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
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Konten teks yang sudah ada sebelumnya
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
                                colors: isActive 
                                    ? [Colors.blue[400]!, Colors.blue[600]!]
                                    : [Colors.grey[400]!, Colors.grey[600]!],
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
                                    height: 1.2,
                                    decoration: !isActive ? TextDecoration.lineThrough : null,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.access_time,
                                            size: 14,
                                            color: Colors.blue[600],
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            _formatDate(pengumuman['tanggal']),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.blue[600],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: statusColor.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            status == 'Berakhir' ? Icons.schedule_outlined :
                                            status == 'Permanen' ? Icons.all_inclusive :
                                            Icons.timer_outlined,
                                            size: 14,
                                            color: statusColor,
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            status,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: statusColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          if (pengumuman['penulis'] != null) ...[
                            Icon(
                              Icons.person_outline,
                              size: 16,
                              color: Colors.grey[500],
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Oleh: ${pengumuman['penulis']}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                            const Spacer(),
                          ],
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isActive 
                                    ? [Colors.blue[500]!, Colors.blue[700]!]
                                    : [Colors.grey[400]!, Colors.grey[600]!],
                              ),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(
                                  color: (isActive ? Colors.blue : Colors.grey).withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (imageUrl != null && imageUrl.isNotEmpty) ...[
                                  const Icon(
                                    Icons.image,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                const Text(
                                  'Baca Selengkapnya',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
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
    }

    void _showDetailPengumuman(Map<String, dynamic> pengumuman) {
      bool isActive = _isPengumumanActive(pengumuman);
      String status = _getStatusPengumuman(pengumuman);
      Color statusColor = _getStatusColor(pengumuman);

      // Ambil URL gambar untuk ditampilkan di detail
      final String? imageUrl = _getValidImageUrl(pengumuman['gambar']);

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.4,
          builder: (context, scrollController) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  height: 5,
                  width: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    padding: EdgeInsets.zero, 
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Widget untuk menampilkan gambar di bagian atas detail
                        if (imageUrl != null && imageUrl.isNotEmpty)
                          Stack(
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(30),
                                  topRight: Radius.circular(30),
                                ),
                                child: Image.network(
                                  imageUrl,
                                  height: 250,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                  // Tambahkan headers untuk request
                                  headers: const {
                                    'User-Agent': 'Flutter App',
                                  },
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Container(
                                      height: 250,
                                      width: double.infinity,
                                      color: Colors.grey[200],
                                      child: Center(
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[600]!),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              'Memuat gambar...',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    print("Debug: Error loading image in detail $imageUrl: $error");
                                    return Container(
                                      height: 250,
                                      width: double.infinity,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFF5F5F5),
                                        borderRadius: BorderRadius.only(
                                          topLeft: Radius.circular(30),
                                          topRight: Radius.circular(30),
                                        ),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.broken_image_outlined,
                                            color: Colors.grey[400],
                                            size: 60,
                                          ),
                                          const SizedBox(height: 12),
                                          Text(
                                            'Gambar tidak dapat dimuat',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 14,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 20),
                                            child: Text(
                                              'URL: ${imageUrl.length > 60 ? '${imageUrl.substring(0, 60)}...' : imageUrl}',
                                              style: TextStyle(
                                                color: Colors.grey[400],
                                                fontSize: 10,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ),
                              // Overlay untuk gambar yang tidak aktif
                              if (!isActive)
                                Positioned.fill(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.4),
                                      borderRadius: const BorderRadius.only(
                                        topLeft: Radius.circular(30),
                                        topRight: Radius.circular(30),
                                      ),
                                    ),
                                  ),
                                ),
                              // Badge status di pojok
                              Positioned(
                                top: 20,
                                right: 20,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.9),
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    status,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        
                        // Padding untuk konten teks
                        Padding(
                          padding: const EdgeInsets.all(25),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(15),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isActive 
                                            ? [Colors.blue[400]!, Colors.blue[600]!]
                                            : [Colors.grey[400]!, Colors.grey[600]!],
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isActive ? Colors.blue : Colors.grey).withOpacity(0.3),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      isActive ? Icons.announcement : Icons.announcement_outlined,
                                      color: Colors.white,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Detail Pengumuman',
                                          style: TextStyle(
                                            fontSize: 22,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.grey[800],
                                          ),
                                        ),
                                        if (!isActive)
                                          Container(
                                            margin: const EdgeInsets.only(top: 4),
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.red[50],
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(color: Colors.red[200]!),
                                            ),
                                            child: Text(
                                              'TIDAK AKTIF',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.red[600],
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: () => Navigator.pop(context),
                                    icon: Icon(Icons.close, color: Colors.grey[400]),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 25),
                              Text(
                                pengumuman['judul'] ?? 'Judul tidak tersedia',
                                style: TextStyle(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: isActive ? Colors.grey[800] : Colors.grey[500],
                                  height: 1.3,
                                  decoration: !isActive ? TextDecoration.lineThrough : null,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Wrap(
                                spacing: 12,
                                runSpacing: 8,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.blue[50],
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.blue[200]!),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.access_time,
                                          size: 16,
                                          color: Colors.blue[600],
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Mulai: ${_formatDate(pengumuman['tanggal'])}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.blue[600],
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (pengumuman['tanggal_selesai'] != null && pengumuman['tanggal_selesai'].toString().isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: statusColor.withOpacity(0.3)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.event_busy,
                                            size: 16,
                                            color: statusColor,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Berakhir: ${_formatDate(pengumuman['tanggal_selesai'])}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: statusColor,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: statusColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: statusColor.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          status == 'Berakhir' ? Icons.schedule_outlined :
                                          status == 'Permanen' ? Icons.all_inclusive :
                                          Icons.timer_outlined,
                                          size: 16,
                                          color: statusColor,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Status: $status',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: statusColor,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (pengumuman['penulis'] != null)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.grey[50],
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.grey[200]!),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.person_outline,
                                            size: 16,
                                            color: Colors.grey[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            pengumuman['penulis'],
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  // Badge untuk menunjukkan ada gambar
                                  if (imageUrl != null && imageUrl.isNotEmpty)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.green[50],
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.green[200]!),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.image,
                                            size: 16,
                                            color: Colors.green[600],
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Dengan Gambar',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: Colors.green[600],
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 25),
                              Container(
                                width: double.infinity,
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      (isActive ? Colors.blue[300]! : Colors.grey[300]!).withOpacity(0.5),
                                      Colors.transparent,
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(height: 25),
                              Text(
                                pengumuman['isi'] ?? 'Konten tidak tersedia',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: isActive ? Colors.grey[700] : Colors.grey[500],
                                  height: 1.7,
                                ),
                              ),
                              const SizedBox(height: 40),
                              // Tombol untuk melihat gambar dalam full screen
                              if (imageUrl != null && imageUrl.isNotEmpty)
                                Center(
                                  child: ElevatedButton.icon(
                                    onPressed: () {
                                      _showFullScreenImage(imageUrl);
                                    },
                                    icon: const Icon(Icons.fullscreen, size: 20),
                                    label: const Text('Lihat Gambar Penuh'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue[600],
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      elevation: 3,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Method untuk menampilkan gambar dalam full screen
    void _showFullScreenImage(String imageUrl) {
      showDialog(
        context: context,
        barrierColor: Colors.black.withOpacity(0.9), // Menggunakan barrierColor sebagai gantinya
        builder: (context) => Dialog.fullscreen(
          backgroundColor: Colors.black.withOpacity(0.9),
          child: Stack(
            children: [
              Center(
                child: InteractiveViewer(
                  panEnabled: true,
                  boundaryMargin: const EdgeInsets.all(20),
                  minScale: 0.5,
                  maxScale: 3.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    // Tambahkan headers untuk request
                    headers: const {
                      'User-Agent': 'Flutter App',
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Memuat gambar...',
                              style: TextStyle(color: Colors.white),
                            ),
                          ],
                        ),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      print("Debug: Error loading fullscreen image $imageUrl: $error");
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.broken_image_outlined,
                              color: Colors.white,
                              size: 80,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Gambar tidak dapat dimuat',
                              style: TextStyle(color: Colors.white),
                            ),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 40),
                              child: Text(
                                'URL: $imageUrl',
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
              Positioned(
                top: 50,
                right: 20,
                child: IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white,
                    size: 30,
                  ),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.5),
                  ),
                ),
              ),
              Positioned(
                bottom: 50,
                left: 20,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Pinch untuk zoom • Drag untuk menggeser',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
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
  }
import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/Harian/absen_harian_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/Harian/absen_pulang_harian_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/AktifGPS/aktifgps_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Kegiatan/absen_kegiatan_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Kegiatan/absen_kegiatan_wfh_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/LokasiKampus/lokasi_kampus_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/semua_menu.dart';
import 'package:mobile_presensi_kdtg/Screens/pengumuman_screen.dart'; 
import 'package:mobile_presensi_kdtg/constants.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:trust_location/trust_location.dart';
// import 'package:launch_review/launch_review.dart';
import 'package:mobile_presensi_kdtg/Screens/presensi_siswa_page.dart';
import 'Absen/WorkFrom/absen_selesai_wf_screen.dart';
import 'Absen/WorkFrom/absen_wf_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  String NIP = "", Nama = "", UUID = "";
  String LokasiAnda = "Pilih Lokasi Anda Sekarang";
  String Foto = "desain/POLIJE_mini.png";
  String jam = "", jam_pulang = "Belum Presensi Pulang", tgl_pulang = "";
  String KeteranganMulai = "", KeteranganSelesai = "";
  String jam_istirahat = "";
  List<Map<String, dynamic>> ListJadwalMapel = [];
  List<Map<String, dynamic>> ListPengumuman = []; // Tambahan untuk pengumuman
  var DataAbsen,
      DataPegawai,
      DataLokasi,
      DataAbsenPulang,
      DataIstirahat,
      DataSelesaiIstirahat,
      DataDinasLuar,
      DataTugasBelajar;
  int StatusDinasLuar = 1;
  int statusWF = 1;
  int AdaDinasLuar = 0;
  int AdaTugasBelajar = 0;
  List DataKegiatan = [];
  List ListKegiatan = [];
  int statusLoading = 1;
  bool ssHeader = false;
  bool ssBody = false;
  bool ssFooter = false;
  int status_lintashari = 0;
  int JenisAbsen = 0;
  bool isLoadingPengumuman = false; // Loading state untuk pengumuman

  // --- PENAMBAHAN PageController ---
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    // --- INISIALISASI PageController ---
    _pageController = PageController();
    statusLoading = 1;
    ssHeader = false;
    ssBody = false;
    ssFooter = false;
    WidgetsBinding.instance.addObserver(this);
    getPref();
    cekFakeGPS();
    Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
  }

  // --- PENAMBAHAN dispose UNTUK PageController ---
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> cekFakeGPS() async {
    bool isMockLocation = await TrustLocation.isMockLocation;
    print("Fake GPS: $isMockLocation");
  }

  void _getTime() {
    setState(() {
      jam = formatDate(DateTime.now(), [HH, ':', nn, ':', ss]);
    });
  }

  Future<void> getPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    UUID = prefs.getString("ID") ?? '';
    NIP = prefs.getString("NIP") ?? '';
    Nama = prefs.getString("Nama") ?? '';

    if (prefs.getInt("CameraSelect") == null) {
      prefs.setInt("CameraSelect", 1);
    }

    bool status = await Geolocator.isLocationServiceEnabled();
    if (!status) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (context) => const AktifGPS()));
    }

    var url = Uri.parse("${Core().ApiUrl}Login/set_token");
    var response = await http.post(url, body: {
      "uuid": prefs.getString("ID"),
      "token": prefs.getString("token"),
    });
    print("Response Body: ${response.body}");
    print("Login Pref: $UUID");

    getDataDash();
    fetchKegiatan();
    fetchJadwalMapel();
    fetchPengumuman(); // Tambahan untuk fetch pengumuman
  }

  Future<String> getDataDash() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    try {
      var res = await http.get(Uri.parse("${Core().ApiUrl}Dash/get_dash/$UUID"),
          headers: {"Accept": "application/json"});

      var resBody = json.decode(res.body);
      print("Response Body: $resBody");

      setState(() {
        statusLoading = 0;
        ssHeader = true;
        Timer(const Duration(milliseconds: 250), () {
          ssBody = true;
          Timer(const Duration(milliseconds: 250), () {
            ssFooter = true;
          });
        });

        DataPegawai = resBody['data']["pegawai"];
        DataLokasi = resBody['data']["lokasi"];
        DataAbsen = resBody['data']["absen"];
        DataAbsenPulang = resBody['data']["absensi_pulang"];
        DataIstirahat = resBody['data']["istirahat"];
        DataSelesaiIstirahat = resBody['data']["selesai_istirahat"];
        DataKegiatan = resBody['data']["kegiatan"];
        DataDinasLuar = resBody['data']["dinasluar"];
        DataTugasBelajar = resBody['data']["tugas_belajar"];

        StatusDinasLuar = int.parse(DataDinasLuar?['status'] ?? '0');
        AdaDinasLuar = int.parse(DataDinasLuar?['ada_surat'] ?? '0');
        AdaTugasBelajar =
            int.parse(DataTugasBelajar?['ada_tugas_belajar'] ?? '0');
        Foto = DataPegawai?["foto_profil"] ?? '';

        prefs.setString("NIP", DataPegawai?['NIP'] ?? '');
        prefs.setString("Nama", DataPegawai?['nama_pegawai'] ?? '');
        prefs.setString("Lokasi", DataLokasi?['nama_kampus'] ?? '');
        LokasiAnda = prefs.getString("Lokasi") ?? '';
        prefs.setString("idKampus", DataLokasi?['idkampus'] ?? '');
        prefs.setDouble("LokasiLat",
            double.tryParse(DataLokasi?['latitude']?.trim() ?? '0.0') ?? 0.0);
        prefs.setDouble("LokasiLng",
            double.tryParse(DataLokasi?['longtitude']?.trim() ?? '0.0') ?? 0.0);
        prefs.setDouble("Radius",
            double.tryParse(DataLokasi?['radius'].toString() ?? '0.0') ?? 0.0);

        if (resBody['data']["version"] > Core().Version) {
          print("Update Available");
          _showNotifUpdate();
        }

        if (resBody['data']["jabatan"]?["lintas_hari"] != null) {
          status_lintashari =
              int.parse(resBody['data']["jabatan"]["lintas_hari"]);
          print("Status Lintas Hari: $status_lintashari");
        }

        if (DataAbsen?["jenis_absen"] == "1") {
          statusWF = 1;
          KeteranganMulai = "Jam Presensi Datang";
          KeteranganSelesai = "Jam Presensi Pulang";
        } else if (DataAbsen?["jenis_absen"] == "4") {
          statusWF = 4;
          KeteranganMulai = "Jam Presensi Mulai WFH";
          KeteranganSelesai = "Jam Presensi Selesai WFH";
        }
        print("Status Kerja: $statusWF");

        if (DataAbsenPulang?['waktu'] != null) {
          jam_pulang = formatDate(
              DateTime.parse(DataAbsenPulang['waktu']), [HH, ':', nn, ':', ss]);
          tgl_pulang = formatDate(DateTime.parse(DataAbsenPulang['waktu']),
              [dd, '/', mm, '/', yyyy]);
          print("Jam Pulang: $jam_pulang, Tanggal Pulang: $tgl_pulang");
        }

        if (DataIstirahat?['waktu'] != null) {
          jam_istirahat = formatDate(
              DateTime.parse(DataIstirahat['waktu']), [HH, ':', nn, ':', ss]);
          if (DataSelesaiIstirahat?['waktu'] != null) {
            jam_istirahat +=
                " s/d ${formatDate(DateTime.parse(DataSelesaiIstirahat['waktu']), [HH, ':', nn, ':', ss])}";
          } else {
            jam_istirahat += " - Belum Presensi";
          }
        }
        print("Jam Istirahat: $jam_istirahat");
      });

      await fetchJadwalMapel();
      return "";
    } catch (e) {
      print("Error fetching data: $e");
      return "Error";
    }
  }

  Future<void> fetchKegiatan() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var url = Uri.parse("${Core().ApiUrl}Dash/getKegiatanTerkini");
    var response = await http.post(url, body: {
      "uuid": prefs.getString("ID"),
    });
    print(response.body);
    if (response.statusCode == 200) {
      var items = json.decode(response.body)['data'];
      setState(() {
        ListKegiatan = items;
      });
    } else {
      ListKegiatan = [];
    }
  }

  Future<void> fetchJadwalMapel() async {
    String uuid = await SharedPreferences.getInstance()
        .then((prefs) => prefs.getString('NIP') ?? '');

    var url = Uri.parse(
        "${Core().ApiUrl}ApiJadwalMapel/JadwalMapel/getJadwalMapel_byUUID/$uuid");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        if (jsonResponse['status'] == true) {
          final List<dynamic> data = jsonResponse['data'] ?? [];

          if (data.isNotEmpty) {
            ListJadwalMapel = List<Map<String, dynamic>>.from(data);
            print(
                "Debug: Number of schedules received: ${ListJadwalMapel.length}");
          } else {
            print("Debug: No schedules found.");
          }
        } else {
          print("Debug: API Error: ${jsonResponse['message']['message']}");
        }
      } else {
        print("Debug: HTTP Response status code: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching data: $e");
    }
  }

  Future<void> fetchPengumuman() async {
    setState(() {
      isLoadingPengumuman = true;
    });

    try {
      var url =
          Uri.parse("${Core().ApiUrl}ApiMobile/ApiPengumuman/getPengumuman");
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
          print(
              "Debug: Number of announcements received: ${ListPengumuman.length}");
        } else {
          print(
              "Debug: API returned false status: ${jsonResponse['message']}");
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

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        color: CBackground, // Background color
        child: Stack(
          children: [
            // Positioned background image to cover the full screen
            Positioned.fill(
              child: Image.asset(
                "assets/images/WaliRename.png",
                fit: BoxFit
                    .cover, // Ensures the image covers the full background
              ),
            ),

            // The rest of the scrollable content
            CustomScrollView(
              physics: const ClampingScrollPhysics(),
              slivers: <Widget>[
                _buildHeader(screenHeight),
                SliverToBoxAdapter(
                  child: (statusLoading == 1)
                      ? Container(
                          width: size.width,
                          alignment: Alignment.center,
                          child: const CircularProgressIndicator(),
                        )
                      : const SizedBox(),
                ),
                (statusWF == 1)
                    ? _buildMenuWFO(screenHeight)
                    : _buildMenuWFH(screenHeight),
                _buildPengumumanSection(screenHeight),
                _buildBox(screenHeight),
                _buildKegiatanTerkini(screenHeight),
                _buildJadwalMapelHariIni(screenHeight),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- WIDGET PENGUMUMAN YANG DIPERBAIKI ---
  SliverToBoxAdapter _buildPengumumanSection(double screenHeight) {
    Size size = MediaQuery.of(context).size;

    return SliverToBoxAdapter(
      child: AnimatedOpacity(
        opacity: ssBody ? 1 : 0,
        duration: const Duration(milliseconds: 500),
        child: AnimatedContainer(
          margin: ssBody
              ? const EdgeInsets.only(top: 10)
              : const EdgeInsets.only(top: 30),
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastEaseInToSlowEaseOut,
          child: Container(
            padding: const EdgeInsets.all(20.0),
            margin:
                const EdgeInsets.symmetric(vertical: 5.0, horizontal: 15.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(4, 4),
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
                      'Pengumuman Terbaru :',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.w600,
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
                          color: Colors.blue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10.0),
                if (isLoadingPengumuman)
                  const SizedBox(
                    height: 150, // Sesuaikan tinggi
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Colors.blue,
                      ),
                    ),
                  )
                else if (ListPengumuman.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(15.0),
                    width: size.width,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10.0),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue,
                          size: 24,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            "Tidak ada pengumuman terbaru",
                            style: TextStyle(
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                else
// --- PENGUMUMAN DENGAN GAMBAR DARI API ---
                  SizedBox(
                    height: 150, // Tinggi tetap untuk PageView
                    child: PageView.builder(
                      key: const PageStorageKey<String>('pengumumanPageView'),
                      controller: _pageController,
                      scrollDirection: Axis.horizontal,
                      itemCount: ListPengumuman.length > 3
                          ? 3
                          : ListPengumuman.length,
                      itemBuilder: (context, index) {
                        final item = ListPengumuman[index];

                        // Ambil gambar dari API
                        final String? imageUrl = item['gambar'];

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
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12.0),
                              child: Stack(
                                fit: StackFit.expand,
                                children: [
                                  // --- Background Gambar dari API ---
                                  if (imageUrl != null && imageUrl.isNotEmpty)
                                    Image.network(
                                      imageUrl,
                                      fit: BoxFit.cover,
                                      loadingBuilder: (context, child, loadingProgress) {
                                        if (loadingProgress == null) return child;
                                        return Container(
                                          color: Colors.blue.shade100,
                                          child: const Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.blue,
                                            ),
                                          ),
                                        );
                                      },
                                      errorBuilder: (context, error, stackTrace) {
                                        return Container(
                                          color: Colors.blue.shade100,
                                          child: const Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              color: Colors.white,
                                              size: 40,
                                            ),
                                          ),
                                        );
                                      },
                                    )
                                  else
                                    Container(
                                      color: Colors.blue.shade100,
                                      child: const Center(
                                        child: Icon(
                                          Icons.image_not_supported,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                      ),
                                    ),

                                  // --- Overlay Gelap untuk Teks ---
                                  Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Colors.black.withOpacity(0.7),
                                          Colors.black.withOpacity(0.2),
                                          Colors.transparent
                                        ],
                                        begin: Alignment.bottomCenter,
                                        end: Alignment.topCenter,
                                        stops: const [0.0, 0.5, 1.0],
                                      ),
                                    ),
                                  ),

                                  // --- Konten Teks ---
                                  Positioned(
                                    bottom: 12,
                                    left: 12,
                                    right: 12,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          item['judul'] ?? 'Judul tidak tersedia',
                                          style: const TextStyle(
                                            fontSize: 16.0,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                            shadows: [
                                              Shadow(
                                                blurRadius: 4.0,
                                                color: Colors.black54,
                                                offset: Offset(2.0, 2.0),
                                              )
                                            ],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item['isi'] ?? 'Konten tidak tersedia',
                                          style: TextStyle(
                                            fontSize: 13.0,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        if (item['tanggal'] != null)
                                          Row(
                                            children: [
                                              const Icon(
                                                Icons.access_time_filled,
                                                size: 14,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                _formatDate(item['tanggal']),
                                                style: const TextStyle(
                                                  fontSize: 11.0,
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
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildBox(double screenHeight) {
    Size size = MediaQuery.of(context).size;

    return SliverToBoxAdapter(
      child: AnimatedOpacity(
        opacity: ssFooter ? 1 : 0,
        duration: const Duration(milliseconds: 500),
        child: AnimatedContainer(
          margin: ssFooter
              ? const EdgeInsets.only(top: 0)
              : const EdgeInsets.only(top: 30),
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastEaseInToSlowEaseOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Text(
                  'Presensi Anda :',
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              // Card untuk absen yang belum dilakukan
              if (DataAbsen == null &&
                  DataKegiatan.isEmpty &&
                  StatusDinasLuar == 1)
                Container(
                  padding: const EdgeInsets.all(15.0),
                  margin: const EdgeInsets.symmetric(
                      vertical: 0, horizontal: 15.0),
                  width: size.width,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.5),
                        blurRadius: 4,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.white70,
                        size: 24,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Anda Hari Ini Belum Melakukan Presensi",
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              // Kartu untuk Absen jika tersedia
              if (DataAbsen != null)
                Row(
                  children: <Widget>[
                    _buildStatCard(
                      KeteranganMulai,
                      formatDate(DateTime.parse(DataAbsen['waktu']),
                          [HH, ':', nn, ':', ss]),
                      formatDate(DateTime.parse(DataAbsen['waktu']),
                          [dd, '/', mm, '/', yyyy]),
                      Colors.lightBlue,
                    ),
                    _buildStatCard(
                      KeteranganSelesai,
                      jam_pulang,
                      tgl_pulang,
                      Colors.cyan,
                    ),
                  ],
                ),
              // Kartu untuk Istirahat jika tersedia
              if (DataIstirahat != null)
                Row(
                  children: <Widget>[
                    _buildStatCard(
                      'Jam Presensi Istirahat',
                      jam_istirahat,
                      "",
                      Colors.lightGreen,
                    ),
                  ],
                ),
              // Kartu untuk Dinas Luar jika berlaku
              if (AdaDinasLuar == 1)
                Container(
                  width: size.width,
                  margin: const EdgeInsets.symmetric(
                      vertical: 5.0, horizontal: 15.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.8),
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.8),
                        blurRadius: 4,
                        offset: const Offset(4, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        "Dinas Luar :",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DataDinasLuar['no_surat'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DataDinasLuar['nama_surat'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Tanggal: " +
                            DataDinasLuar['tanggal_mulai'] +
                            " s/d " +
                            DataDinasLuar['tanggal_selesai'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              // Kartu untuk Tugas Belajar jika berlaku
              if (AdaTugasBelajar == 1)
                Container(
                  width: size.width,
                  margin: const EdgeInsets.symmetric(
                      vertical: 5.0, horizontal: 15.0),
                  padding: const EdgeInsets.all(12.0),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        "Tugas Belajar :",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Kampus: " +
                            DataTugasBelajar['tugas_belajar']['nama_kampus'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Keterangan: " +
                            DataTugasBelajar['tugas_belajar']['keterangan'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "Tahun: " + DataTugasBelajar['tugas_belajar']['tahun'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
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

  SliverToBoxAdapter _buildKegiatanTerkini(double screenHeight) {
    Size size = MediaQuery.of(context).size;

    // If there are no activities, return an empty container, which results in no UI being shown
    if (ListKegiatan.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    // If there are activities, show the 'Kegiatan Anda' section and the list
    return SliverToBoxAdapter(
      child: AnimatedOpacity(
        opacity: ssFooter ? 1 : 0,
        duration: const Duration(milliseconds: 500),
        child: AnimatedContainer(
          margin: ssFooter
              ? const EdgeInsets.only(top: 0)
              : const EdgeInsets.only(top: 30),
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastEaseInToSlowEaseOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.only(top: 8, left: 20),
                child: Text(
                  'Kegiatan Anda :',
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(
                width: double.infinity,
                height: size.height * 0.3,
                child: ListView.builder(
                  itemCount: ListKegiatan.length,
                  itemBuilder: (context, index) {
                    return getCardKegiatan(ListKegiatan[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildJadwalMapelHariIni(double screenHeight) {
    Size size = MediaQuery.of(context).size;

    return SliverToBoxAdapter(
      child: AnimatedOpacity(
        opacity: ssFooter ? 1 : 0,
        duration: const Duration(milliseconds: 500),
        child: AnimatedContainer(
          margin: ssFooter
              ? const EdgeInsets.only(top: 0)
              : const EdgeInsets.only(top: 30),
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastEaseInToSlowEaseOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const SizedBox(height: 10),
              const Padding(
                padding: EdgeInsets.only(top: 8, left: 20),
                child: Text(
                  'Jadwal Mapel :',
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (ListJadwalMapel.isEmpty)
                Container(
                  padding: const EdgeInsets.all(15.0),
                  margin: const EdgeInsets.symmetric(
                      vertical: 5, horizontal: 20.0),
                  width: size.width,
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(10.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.5),
                        blurRadius: 3,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.white70,
                        size: 24,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Tidak ada jadwal mapel untuk hari ini.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  itemCount: ListJadwalMapel.length,
                  shrinkWrap: true, // GridView akan menyusut sesuai isi
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (context, index) {
                    return getCardJadwalMapel(ListJadwalMapel[index]);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget getCardJadwalMapel(Map<String, dynamic> item) {
    return GestureDetector(
      onTap: () {
        // Parse id_kelas safely, ensuring that it is an integer
        int idKelas = item['kelas'] != null
            ? int.tryParse(item['kelas'].toString()) ?? 0
            : 0; // Parse kelas to idKelas

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PresensiSiswaPage(
              namaMapel: item['nama_mapel'] ?? 'Tidak ada data', // nama_mapel
              namaKelas: item['nama_kelas'] ?? 'Tidak ada data', // nama_kelas
              idKelas: idKelas, // Pass the idKelas as an integer
              idMapel: item['id_mapel'] ?? 'Tidak ada data', // id_mapel
              idJadwal: item['id_jadwal'] ?? 'Tidak ada data', // id_jadwal
              waktuMulai: item['waktu_mulai'] ?? '-', // waktu_mulai
              waktuSelesai: item['waktu_selesai'] ?? '-', // waktu_selesai
              hari: item['hari'] ?? '-', // hari
              tanggal: item['tanggal'] ?? 'Tanggal belum ditentukan', // tanggal
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 20.0),
        padding: const EdgeInsets.all(20.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8.0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header: Mata pelajaran dan ikon buku
            Row(
              children: [
                const Icon(
                  Icons.book_rounded,
                  color: Colors.blueAccent,
                  size: 28,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item['nama_mapel'] ?? 'Tidak ada data', // nama_mapel
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12), // Jarak antar elemen

            // Lokasi (Kelas)
            Row(
              children: [
                const Icon(
                  Icons.class_rounded,
                  color: Colors.purpleAccent,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  item['nama_kelas'] ?? 'Tidak ada data', // nama_kelas
                  style: const TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // Jarak antar elemen

            // Waktu pelajaran
            Row(
              children: [
                const Icon(
                  Icons.access_time_filled_rounded,
                  color: Colors.orangeAccent,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  "${item['waktu_mulai'] ?? '-'} - ${item['waktu_selesai'] ?? '-'}", // waktu_mulai and waktu_selesai
                  style: const TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // Jarak antar elemen

            // Hari pelajaran
            Row(
              children: [
                const Icon(
                  Icons.calendar_today_rounded,
                  color: Colors.greenAccent,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  "Hari: ${item['hari'] ?? '-'}", // hari
                  style: const TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // Jarak antar elemen

            // Tanggal
            Row(
              children: [
                const Icon(
                  Icons.date_range_rounded,
                  color: Colors.redAccent,
                  size: 20,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDate(
                      item['tanggal']), // Use the new method to format the date
                  style: const TextStyle(
                    fontSize: 16.0,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10), // Jarak antar elemen
          ],
        ),
      ),
    );
  }

  Widget getCardKegiatan(item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.white70,
            blurRadius: 4,
            offset: Offset(4, 4), // Shadow position
          ),
        ],
      ),
      margin: const EdgeInsets.only(bottom: 8, left: 10, right: 10),
      child: TextButton(
        onPressed: () {
          _showDialogKegiatan(
            item['idkegiatan'],
            double.parse(item['latitude']),
            double.parse(item['longtitude']),
            double.parse(item['radius']),
          );
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
          margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(item['nama_kegiatan'],
                  style: const TextStyle(
                      color: CText,
                      fontSize: 16,
                      fontWeight: FontWeight.w800)),
              const SizedBox(
                height: 4,
              ),
              Text(
                (item['tanggal'] == item['tanggal_selesai'])
                    ? "Pelaksanaan : ${formatDate(DateTime.parse(item['tanggal']), [dd, '-', mm, '-', yyyy])}"
                    : "Pelaksanaan : ${formatDate(DateTime.parse(item['tanggal']), [dd, '-', mm, '-', yyyy])} s/d ${formatDate(DateTime.parse(item['tanggal_selesai']), [dd, '-', mm, '-', yyyy])}",
                style: const TextStyle(
                    color: kDarkPrimaryColor, fontWeight: FontWeight.w600),
              ),
              Row(
                children: <Widget>[
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Jam Mulai",
                        style: TextStyle(fontSize: 12, color: CText),
                      ),
                      Text("Jam Selesai",
                          style: TextStyle(fontSize: 12, color: CText)),
                      Text("Lokasi",
                          style: TextStyle(fontSize: 12, color: CText)),
                      Text("PIC",
                          style: TextStyle(fontSize: 12, color: CText)),
                      Text("Unit Pengadaan",
                          style: TextStyle(fontSize: 12, color: CText)),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(": " + item['jam_mulai'],
                          style: const TextStyle(fontSize: 12, color: CText)),
                      Text(": " + item['jam_selesai'],
                          style: const TextStyle(fontSize: 12, color: CText)),
                      Text(
                          (item['nama_gedung'] != null)
                              ? ": " +
                                  item['nama_gedung'] +
                                  ", " +
                                  item['nama_kampus']
                              : ": " + item['nama_kampus'],
                          style: const TextStyle(fontSize: 12, color: CText)),
                      Text(": " + item['nama_pegawai'],
                          style: const TextStyle(fontSize: 12, color: CText)),
                      Text(": " + item['nama_unit'],
                          style: const TextStyle(fontSize: 12, color: CText)),
                    ],
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDialogKegiatan(String IdKegiatan, double latitude,
      double longtitude, double jarak) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AlertDialog(
            title: const Text("Presensi Kegiatan"),
            content: const SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text("Pilih Lokasi Presensi Kegiatan !"),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Presensi Di Lokasi'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AbsenKegiatanScreen(
                                idkegiatan: IdKegiatan,
                                latitude: latitude,
                                longtitude: longtitude,
                                jarak_radius: jarak,
                              )));
                },
              ),
              TextButton(
                child: const Text('Presensi Online'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AbsenKegiatanWFHScreen(
                                idkegiatan: IdKegiatan,
                                latitude: latitude,
                                longtitude: longtitude,
                                jarak: jarak,
                              )));
                },
              )
            ],
          ),
        );
      },
    );
  }

  SliverToBoxAdapter _buildHeader(double screenHeight) {
    Size size = MediaQuery.of(context).size;
    return SliverToBoxAdapter(
      child: AnimatedOpacity(
        opacity: ssHeader ? 1 : 0,
        duration: const Duration(milliseconds: 500),
        child: AnimatedContainer(
          padding: const EdgeInsets.only(
              left: 20.0, right: 20.0, bottom: 0.0, top: 40.0),
          margin: ssHeader
              ? const EdgeInsets.only(top: 0)
              : const EdgeInsets.only(top: 8),
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastEaseInToSlowEaseOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white, // Putih polos
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1), // Shadow tipis
                      blurRadius: 10,
                      spreadRadius: 2,
                      offset: const Offset(0, 5), // Shadow posisi ke bawah
                    ),
                  ],
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      height: 59,
                      width: 59,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(70),
                        image: const DecorationImage(
                          image: AssetImage('assets/images/smp1logo.png'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            "Good Day!",
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: CText,
                            ),
                          ),
                          Text(
                            Nama,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            overflow: TextOverflow.visible,
                          ),
                          Text(
                            (NIP == "") ? "-" : NIP,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: CText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  Expanded(
                    child: Container(
                      height: 125,
                      width: size.width * 0.43,
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white, // Putih polos
                        borderRadius: BorderRadius.circular(12.0),
                        boxShadow: [
                          BoxShadow(
                            color:
                                Colors.black.withOpacity(0.1), // Shadow tipis
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          const Icon(
                            Icons.watch_later_outlined,
                            color: Colors.blue,
                          ),
                          Text(
                            jam,
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: CText),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            formatDate(DateTime.now(),
                                [D, ', ', dd, ' ', M, ' ', yyyy]),
                            style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: CText),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return const LokasiKampusScreen();
                        }));
                      },
                      child: Container(
                        height: 125,
                        width: size.width * 0.43,
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white, // Putih polos
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color:
                                  Colors.black.withOpacity(0.1), // Shadow tipis
                              blurRadius: 10,
                              spreadRadius: 2,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            const Icon(
                              Icons.location_on_outlined,
                              color: Colors.blue,
                            ),
                            Text(
                              LokasiAnda,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: CText),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              "Lokasi Anda",
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: CText),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Expanded _buildStatCard(
      String title, String count, String ket, MaterialColor color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 8.0),
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(2, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12.0,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14.0,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            if (ket.isNotEmpty)
              Text(
                ket,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  // Semua Menu
  SliverToBoxAdapter _buildMenuWFO(double screenHeight) {
    return SliverToBoxAdapter(
      child: AnimatedOpacity(
        opacity: ssBody ? 1 : 0,
        duration: const Duration(milliseconds: 500),
        child: AnimatedContainer(
          margin: EdgeInsets.only(top: ssBody ? 0 : 10),
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastEaseInToSlowEaseOut,
          child: Container(
            padding: const EdgeInsets.all(20.0),
            margin:
                const EdgeInsets.symmetric(vertical: 5.0, horizontal: 15.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 10,
                  spreadRadius: 2,
                  offset: const Offset(4, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Menu Presensi :',
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Semua Menu Button
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SemuaMenu(),
                              ));
                        },
                        child: Column(
                          children: [
                            Image.asset(
                              "assets/icons/semua_menu.png",
                              height: screenHeight * 0.07,
                            ),
                            SizedBox(height: screenHeight * 0.003),
                            const Text(
                              "Semua\nMenu",
                              style: TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      // Presensi Masuk Button
                      TextButton(
                        onPressed: () {
                          if (JenisAbsen == 0 || JenisAbsen == 1) {
                            if (StatusDinasLuar == 1) {
                              if (DataAbsen == null) {
                                _showMyDialog(
                                  "Presensi Harian",
                                  "Anda belum melakukan Presensi Harian. Silakan Presensi Harian terlebih dahulu!",
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AbsenHarianScreen(),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AbsenHarianScreen(),
                                    ));
                              }
                            } else {
                              _showNotif(
                                "Presensi Harian",
                                "Anda Dilarang Melakukan Presensi Karena Sedang Dinas Luar",
                              );
                            }
                          }
                        },
                        child: Column(
                          children: [
                            Image.asset(
                              StatusDinasLuar == 1
                                  ? "assets/icons/presensi_datang_warna.png"
                                  : "assets/icons/presensi_datang_monokrom.png",
                              height: screenHeight * 0.07,
                            ),
                            SizedBox(height: screenHeight * 0.003),
                            const Text(
                              "Presensi\nMasuk",
                              style: TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                      // Presensi Pulang Button
                      TextButton(
                        onPressed: () {
                          if (JenisAbsen == 0 || JenisAbsen == 1) {
                            if (StatusDinasLuar == 1) {
                              if (DataAbsen == null) {
                                _showMyDialog(
                                  "Presensi Harian",
                                  "Anda belum melakukan Presensi Harian. Silakan Presensi Harian terlebih dahulu!",
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const AbsenHarianScreen(),
                                  ),
                                );
                              } else {
                                if (DataAbsenPulang == null) {
                                  Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const AbsenPulangHarianScreen(),
                                      ));
                                } else {
                                  _showMyDialog(
                                    "Presensi Harian",
                                    "Apakah Anda Memperbarui Pulang Sebelumnya?",
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const AbsenPulangHarianScreen(),
                                    ),
                                  );
                                }
                              }
                            } else {
                              _showNotif(
                                "Presensi Harian",
                                "Anda Dilarang Melakukan Presensi Karena Sedang Dinas Luar",
                              );
                            }
                          }
                        },
                        child: Column(
                          children: [
                            Image.asset(
                              StatusDinasLuar == 1
                                  ? "assets/icons/presensi_pulang_warna.png"
                                  : "assets/icons/presensi_pulang_monokrom.png",
                              height: screenHeight * 0.07,
                            ),
                            SizedBox(height: screenHeight * 0.003),
                            const Text(
                              "Presensi\nPulang",
                              style: TextStyle(
                                fontSize: 11.0,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildMenuWFH(double screenHeight) {
    return SliverToBoxAdapter(
        child: AnimatedOpacity(
            opacity: ssBody ? 1 : 0,
            duration: const Duration(milliseconds: 500),
            child: AnimatedContainer(
              margin: ssBody
                  ? const EdgeInsets.only(top: 0)
                  : const EdgeInsets.only(top: 30),
              duration: const Duration(milliseconds: 500),
              curve: Curves.fastEaseInToSlowEaseOut,
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.white70,
                      blurRadius: 4,
                      offset: Offset(4, 4), // Shadow position
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Menu Presensi :',
                      style: TextStyle(
                        fontSize: 15.0,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 10.0),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            TextButton(
                                onPressed: () {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return const SemuaMenu();
                                  }));
                                },
                                child: Column(
                                  children: <Widget>[
                                    Image.asset(
                                      "assets/icons/semua_menu.png",
                                      height: screenHeight * 0.07,
                                    ),
                                    SizedBox(height: screenHeight * 0.003),
                                    const Text(
                                      "Semua\nMenu",
                                      style: TextStyle(
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    )
                                  ],
                                )),
                            TextButton(
                                onPressed: () {
                                  if (StatusDinasLuar == 1) {
                                    if (DataAbsen == null) {
                                      Navigator.push(context,
                                          MaterialPageRoute(builder: (context) {
                                        return const AbsenWFScreen();
                                      }));
                                    } else {
                                      if (DataAbsenPulang == null) {
                                        _showMyDialog(
                                            "Presensi WFH",
                                            "Anda belum melakukan Presensi Selesai WFH. Silakan Presensi Selesai WFH terlebih dahulu !",
                                            MaterialPageRoute(
                                                builder: (context) {
                                          return const AbsenSelesaiWFScreen();
                                        }));
                                      } else {
                                        _showNotif("Presensi WFH",
                                            "Anda Sudah Melakukan Presensi Hari ini");
                                      }
                                    }
                                  } else {
                                    _showNotif("Presensi WFH",
                                        "Anda Dilarang Melakukan Presensi Karena Sedang Dinas Luar");
                                  }
                                },
                                child: Column(
                                  children: <Widget>[
                                    Image.asset(
                                      (StatusDinasLuar == 1)
                                          ? "assets/icons/mulai_wfh_warna.png"
                                          : "assets/icons/mulai_wfh_monokrom.png",
                                      height: screenHeight * 0.07,
                                    ),
                                    SizedBox(height: screenHeight * 0.003),
                                    const Text(
                                      "Presensi\nMulai WFH",
                                      style: TextStyle(
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    )
                                  ],
                                )),
                            TextButton(
                                onPressed: () {
                                  if (StatusDinasLuar == 1) {
                                    if (DataAbsen == null) {
                                      _showMyDialog(
                                          "Presensi WFH",
                                          "Anda belum melakukan Presensi WFH. Silakan Presensi WFH terlebih dahulu !",
                                          MaterialPageRoute(builder: (context) {
                                        return const AbsenWFScreen();
                                      }));
                                    } else {
                                      if (DataAbsenPulang == null) {
                                        Navigator.push(context,
                                            MaterialPageRoute(
                                                builder: (context) {
                                          return const AbsenSelesaiWFScreen();
                                        }));
                                      } else {
                                        _showMyDialog(
                                            "Presensi WFH",
                                            "Apakah Anda Membatalkan Selesai WFH Sebelumnya ?",
                                            MaterialPageRoute(
                                                builder: (context) {
                                          return const AbsenSelesaiWFScreen();
                                        }));
                                      }
                                    }
                                  } else {
                                    _showNotif("Presensi WFH",
                                        "Anda Dilarang Melakukan Presensi Karena Sedang Dinas Luar");
                                  }
                                },
                                // padding:
                                //     EdgeInsets.symmetric(vertical: 0, horizontal: -10),
                                child: Column(
                                  children: <Widget>[
                                    Image.asset(
                                      (StatusDinasLuar == 1)
                                          ? "assets/icons/selesai_wfh_warna.png"
                                          : "assets/icons/selesai_wfh_monokrom.png",
                                      height: screenHeight * 0.07,
                                    ),
                                    SizedBox(height: screenHeight * 0.003),
                                    const Text(
                                      "Presensi\nSelesai WFH",
                                      style: TextStyle(
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    )
                                  ],
                                )),
                          ]),
                    ),
                  ],
                ),
              ),
            )));
  }

  Future<void> _showMyDialog(
      String Title, String Keterangan, MaterialPageRoute link) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AlertDialog(
            title: Text(Title),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(Keterangan),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Keluar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(context, link);
                },
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _showNotif(String Title, String Keterangan) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AlertDialog(
            title: Text(Title),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(Keterangan),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Keluar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showNotifUpdate() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AlertDialog(
            title: const Text("Perbarui Aplikasi"),
            content: const SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text("Mohon Untuk Perbarui Aplikasi Anda Saat Ini."),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text(
                  'Lanjut Tanpa Pembaharuan',
                  style: TextStyle(color: CWarning),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              // TextButton(
              //   child: Text('Perbarui Sekarang'),
              //   onPressed: () {
              //     LaunchReview.launch();
              //   },
              // )
            ],
          ),
        );
      },
    );
  }

  String formatTanggal(String tanggal) {
    // Mengubah string tanggal dari "YYYY-MM-DD" menjadi "DD-MM-YYYY"
    DateTime dateTime = DateTime.parse(tanggal);
    return '${dateTime.day.toString().padLeft(2, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.year}';
  }

  String _formatDate(String? date) {
    if (date == null || date.isEmpty) {
      return 'Tanggal belum ditentukan'; // Return default message if date is null or empty
    }

    try {
      DateTime parsedDate = DateTime.parse(date); // Parse the date string
      return '${parsedDate.day.toString().padLeft(2, '0')}-${parsedDate.month.toString().padLeft(2, '0')}-${parsedDate.year}'; // Format to DD-MM-YYYY
    } catch (e) {
      return 'Tanggal tidak valid'; // Return error message if parsing fails
    }
  }
}
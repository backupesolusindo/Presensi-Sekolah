import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/Harian/absen_harian_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/Harian/absen_pulang_harian_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/Istirahat/absen_istirahat_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/Istirahat/absen_selesai_istirahat_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/Istirahat/istirahat_post.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/absen_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/AktifGPS/aktifgps_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Kegiatan/absen_kegiatan_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Kegiatan/absen_kegiatan_wfh_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/LokasiKampus/lokasi_kampus_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/semua_menu.dart';
import 'package:mobile_presensi_kdtg/config/palette.dart';
import 'package:mobile_presensi_kdtg/config/styles.dart';
import 'package:mobile_presensi_kdtg/constants.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'package:mobile_presensi_kdtg/data/data.dart';
import 'package:mobile_presensi_kdtg/widgets/widgets.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:trust_location/trust_location.dart';
import 'package:launch_review/launch_review.dart';
import 'Absen/WorkFrom/absen_selesai_wf_screen.dart';
import 'Absen/WorkFrom/absen_wf_screen.dart';

class HomeScreen extends StatefulWidget {
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

  @override
  void initState() {
    // TODO: implement initState
    // WidgetsBinding.instance.addPostFrameCallback(getPref());
    super.initState();
    statusLoading = 1;
    ssHeader = false;
    ssBody = false;
    ssFooter = false;
    WidgetsBinding.instance.addObserver(this);
    getPref();
    cekFakeGPS();
    Timer.periodic(Duration(seconds: 1), (Timer t) => _getTime());
  }

  cekFakeGPS() async {
    bool _isMockLocation = await TrustLocation.isMockLocation;
    print("fake GPS :");
    print(_isMockLocation);
  }

  _getTime() {
    setState(() {
      jam = formatDate(DateTime.now(), [HH, ':', nn, ':', ss]);
    });
  }

  getPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    UUID = prefs.getString("ID")!;
    NIP = prefs.getString("NIP")!;
    Nama = prefs.getString("Nama")!;

    if (prefs.getInt("CameraSelect") == null) {
      prefs.setInt("CameraSelect", 1);
    }

    bool status = await Geolocator.isLocationServiceEnabled();
    if (!status) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
        return AktifGPS();
      }));
    }

    var url = Uri.parse(Core().ApiUrl + "Login/set_token");
    var response = await http.post(url, body: {
      "uuid": prefs.getString("ID"),
      "token": prefs.getString("token"),
    });
    print(response.body);
    print("Login Pref :" + UUID);
    getDataDash();
    fetchKegiatan();
  }

  Future<String> getDataDash() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var res = await http.get(Uri.parse(Core().ApiUrl + "Dash/get_dash/" + UUID),
        headers: {"Accept": "application/json"});
    var resBody = json.decode(res.body);
    setState(() {
      statusLoading = 0;
      ssHeader = true;
      Timer(Duration(milliseconds: 250), () {
        ssBody = true;
        Timer(Duration(milliseconds: 250), () {
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
      StatusDinasLuar = int.parse(DataDinasLuar['status']);
      AdaDinasLuar = int.parse(DataDinasLuar['ada_surat']);
      AdaTugasBelajar = int.parse(DataTugasBelajar['ada_tugas_belajar']);
      Foto = DataPegawai["foto_profil"];

      prefs.setString("NIP", DataPegawai['NIP']);
      prefs.setString("Nama", DataPegawai['nama_pegawai']);
      prefs.setString("Lokasi", DataLokasi['nama_kampus']);
      LokasiAnda = prefs.getString("Lokasi")!;
      prefs.setString("idKampus", DataLokasi['idkampus']);
      prefs.setDouble("LokasiLat", double.parse(DataLokasi['latitude']));
      prefs.setDouble("LokasiLng", double.parse(DataLokasi['longtitude']));
      prefs.setDouble("Radius", double.parse(DataLokasi['radius']));

      if (resBody['data']["version"] > Core().Version) {
        _showNotifUpdate();
      }
      // print("Lintas Hari : "+resBody['data']["jabatan"]["lintas_hari"]);
      if (resBody['data']["jabatan"]["lintas_hari"] != null) {
        status_lintashari =
            int.parse(resBody['data']["jabatan"]["lintas_hari"]);
      }

      if (DataAbsen["jenis_absen"] == "1") {
        statusWF = 1;
        KeteranganMulai = "Jam Presensi Datang";
        KeteranganSelesai = "Jam Presensi Pulang";
      } else if (DataAbsen["jenis_absen"] == "4") {
        statusWF = 4;
        KeteranganMulai = "Jam Presensi Mulai WFH";
        KeteranganSelesai = "Jam Presensi Selesai WFH";
      }
      if (DataAbsenPulang != null) {
        jam_pulang = formatDate(
            DateTime.parse(DataAbsenPulang['waktu']), [HH, ':', nn, ':', ss]);
        tgl_pulang = formatDate(
            DateTime.parse(DataAbsenPulang['waktu']), [dd, '/', mm, '/', yyyy]);
      }
      if (DataSelesaiIstirahat != null) {
        jam_istirahat = formatDate(DateTime.parse(DataIstirahat['waktu']),
                [HH, ':', nn, ':', ss]) +
            " s/d " +
            formatDate(DateTime.parse(DataSelesaiIstirahat['waktu']),
                [HH, ':', nn, ':', ss]);
      } else {
        jam_istirahat = formatDate(DateTime.parse(DataIstirahat['waktu']),
                [HH, ':', nn, ':', ss]) +
            " - Belum Presensi";
      }
    });
    print(resBody);
    return "";
  }

  fetchKegiatan() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var url = Uri.parse(Core().ApiUrl + "Dash/getKegiatanTerkini");
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

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      // appBar: CustomAppBar(),
      body: Container(
        color: CBackground,
        child: Stack(children: [
          Positioned(
            top: 0,
            right: 0,
            child: Image.asset(
              "assets/images/dash_tr.png",
              height: size.height * 0.4,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            child: Image.asset(
              "assets/images/blob_left.png",
              height: size.height * 0.4,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Image.asset(
              "assets/images/dash_bl.png",
              // height: size.height * 0.3,
              width: size.width,
              fit: BoxFit.fill,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Image.asset(
              "assets/images/dash_br.png",
              height: size.height * 0.3,
            ),
          ),
          CustomScrollView(
            physics: ClampingScrollPhysics(),
            slivers: <Widget>[
              _buildHeader(screenHeight),
              SliverToBoxAdapter(
                child: (statusLoading == 1)
                    ? Container(
                        width: size.width,
                        alignment: Alignment.center,
                        child: CircularProgressIndicator(),
                      )
                    : SizedBox(),
              ),
              (statusWF == 1)
                  ? _buildMenuWFO(screenHeight)
                  : _buildMenuWFH(screenHeight),
              _buildBox(screenHeight),
              _buildKegiatanTerkini(screenHeight),
              _buildJadwalMapelHariIni(screenHeight),
            ],
          ),
        ]),
      ),
    );
  }

  //box counter
  SliverToBoxAdapter _buildBox(double screenHeight) {
    Size size = MediaQuery.of(context).size;
    return SliverToBoxAdapter(
        child: AnimatedOpacity(
            opacity: ssFooter ? 1 : 0,
            duration: const Duration(milliseconds: 500),
            child: AnimatedContainer(
                margin: ssFooter
                    ? EdgeInsets.only(top: 0)
                    : EdgeInsets.only(top: 30),
                duration: const Duration(milliseconds: 500),
                curve: Curves.fastEaseInToSlowEaseOut,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 8),
                      child: Text(
                        'Presensi Anda :',
                        style: const TextStyle(
                          fontSize: 15.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (DataAbsen == null &&
                        DataKegiatan.length < 1 &&
                        StatusDinasLuar == 1)
                      Container(
                        padding: const EdgeInsets.all(20.0),
                        margin: const EdgeInsets.symmetric(
                            vertical: 0, horizontal: 15.0),
                        width: size.width,
                        decoration: BoxDecoration(
                          color: CWarning,
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: CWarning,
                              blurRadius: 4,
                              offset: Offset(4, 4), // Shadow position
                            ),
                          ],
                        ),
                        child: Text(
                          "Anda Hari Ini Belum Melakukan Presensi",
                          style: const TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    if (DataAbsen != null)
                      Row(
                        children: <Widget>[
                          _buildStatCard(
                              KeteranganMulai,
                              formatDate(DateTime.parse(DataAbsen['waktu']),
                                  [HH, ':', nn, ':', ss]),
                              formatDate(DateTime.parse(DataAbsen['waktu']),
                                  [dd, '/', mm, '/', yyyy]),
                              Colors.lightBlue),
                          _buildStatCard(KeteranganSelesai, jam_pulang,
                              tgl_pulang, Colors.cyan),
                        ],
                      ),
                    if (DataIstirahat != null)
                      Row(
                        children: <Widget>[
                          _buildStatCard('Jam Presensi Istirahat',
                              jam_istirahat, "", Colors.lightGreen),
                        ],
                      ),
                    if (AdaDinasLuar == 1)
                      Container(
                        width: size.width,
                        margin: const EdgeInsets.symmetric(
                            vertical: 5.0, horizontal: 15.0),
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: kPrimaryColor.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: kPrimaryColor.withOpacity(0.8),
                              blurRadius: 4,
                              offset: Offset(4, 4), // Shadow position
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              "Dinas Luar :",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(
                              height: 8,
                            ),
                            Text(
                              DataDinasLuar['no_surat'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(
                              height: 4,
                            ),
                            Text(
                              DataDinasLuar['nama_surat'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Tanggal : " +
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
                    if (AdaTugasBelajar == 1)
                      Container(
                        width: size.width,
                        margin: const EdgeInsets.symmetric(
                            vertical: 5.0, horizontal: 15.0),
                        padding: const EdgeInsets.all(10.0),
                        decoration: BoxDecoration(
                          color: kPrimaryColor,
                          borderRadius: BorderRadius.circular(10.0),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              "Tugas Belajar :",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(
                              height: 8,
                            ),
                            Text(
                              "Kampus : " +
                                  DataTugasBelajar['tugas_belajar']
                                      ['nama_kampus'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(
                              height: 4,
                            ),
                            Text(
                              "Keterangan : " +
                                  DataTugasBelajar['tugas_belajar']
                                      ['keterangan'],
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Tahun : " +
                                  DataTugasBelajar['tugas_belajar']['tahun'],
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
                ))));
  }

  SliverToBoxAdapter _buildKegiatanTerkini(double screenHeight) {
  Size size = MediaQuery.of(context).size;

  // If there are no activities, return an empty container, which results in no UI being shown
  if (ListKegiatan.isEmpty) {
    return SliverToBoxAdapter(child: SizedBox.shrink());
  }

  // If there are activities, show the 'Kegiatan Anda' section and the list
  return SliverToBoxAdapter(
    child: AnimatedOpacity(
      opacity: ssFooter ? 1 : 0,
      duration: const Duration(milliseconds: 500),
      child: AnimatedContainer(
        margin: ssFooter ? EdgeInsets.only(top: 0) : EdgeInsets.only(top: 30),
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastEaseInToSlowEaseOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 20),
              child: Text(
                'Kegiatan Anda :',
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Container(
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
        margin: ssFooter ? EdgeInsets.only(top: 0) : EdgeInsets.only(top: 30),
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastEaseInToSlowEaseOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 20),
              child: Text(
                'Jadwal Mapel Hari Ini :',
                style: const TextStyle(
                  fontSize: 15.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            // If there are no schedules, show a message
            if (ListJadwalMapel.isEmpty)
              Container(
                padding: const EdgeInsets.all(20.0),
                margin: const EdgeInsets.symmetric(
                    vertical: 5, horizontal: 15.0),
                width: size.width,
                decoration: BoxDecoration(
                  color: CWarning,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
                    BoxShadow(
                      color: CWarning,
                      blurRadius: 4,
                      offset: Offset(4, 4), // Shadow position
                    ),
                  ],
                ),
                child: Text(
                  "Tidak ada jadwal mapel untuk hari ini.",
                  style: const TextStyle(
                      color: Colors.white70, fontWeight: FontWeight.w600),
                ),
              )
            else // Otherwise, show the list of schedules
              Container(
                width: double.infinity,
                height: size.height * 0.3,
                child: ListView.builder(
                  itemCount: ListJadwalMapel.length,
                  itemBuilder: (context, index) {
                    return getCardJadwalMapel(ListJadwalMapel[index]);
                  },
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

Widget getCardJadwalMapel(Map<String, dynamic> item) {
  return Container(
    margin: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
    padding: const EdgeInsets.all(16.0),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12.0),
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 6.0,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          item['nama_mapel'],
          style: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8),
        Text("Jam: ${item['jam_mulai']} - ${item['jam_selesai']}"),
        Text("Ruang: ${item['ruang_kelas']}"),
      ],
    ),
  );
}



  Widget getCardKegiatan(item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white70,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
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
          margin: EdgeInsets.symmetric(vertical: 10, horizontal: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(item['nama_kegiatan'],
                  style: const TextStyle(
                      color: CText, fontSize: 16, fontWeight: FontWeight.w800)),
              SizedBox(
                height: 4,
              ),
              Text(
                (item['tanggal'] == item['tanggal_selesai'])
                    ? "Pelaksanaan : " +
                        formatDate(DateTime.parse(item['tanggal']),
                            [dd, '-', mm, '-', yyyy])
                    : "Pelaksanaan : " +
                        formatDate(DateTime.parse(item['tanggal']),
                            [dd, '-', mm, '-', yyyy]) +
                        " s/d " +
                        formatDate(DateTime.parse(item['tanggal_selesai']),
                            [dd, '-', mm, '-', yyyy]),
                style: const TextStyle(
                    color: kDarkPrimaryColor, fontWeight: FontWeight.w600),
              ),
              Row(
                children: <Widget>[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Jam Mulai",
                        style: const TextStyle(fontSize: 12, color: CText),
                      ),
                      Text("Jam Selesai",
                          style: const TextStyle(fontSize: 12, color: CText)),
                      Text("Lokasi",
                          style: const TextStyle(fontSize: 12, color: CText)),
                      Text("PIC",
                          style: const TextStyle(fontSize: 12, color: CText)),
                      Text("Unit Pengadaan",
                          style: const TextStyle(fontSize: 12, color: CText)),
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
            title: Text("Presensi Kegiatan"),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text("Pilih Lokasi Presensi Kegiatan !"),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Presensi Di Lokasi'),
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
                child: Text('Presensi Online'),
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

  //lengkungan atas
  SliverToBoxAdapter _buildHeader(double screenHeight) {
    Size size = MediaQuery.of(context).size;
    return SliverToBoxAdapter(
        child: AnimatedOpacity(
      opacity: ssHeader ? 1 : 0,
      duration: const Duration(milliseconds: 500),
      child: AnimatedContainer(
        padding: const EdgeInsets.only(
            left: 20.0, right: 20.0, bottom: 10.0, top: 40.0),
        margin: ssHeader ? EdgeInsets.only(top: 0) : EdgeInsets.only(top: 30),
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastEaseInToSlowEaseOut,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white70,
                    borderRadius: BorderRadius.circular(12.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white70,
                        blurRadius: 4,
                        offset: Offset(2, 4), // Shadow position
                      ),
                    ],
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        height: 59,
                        width: 59,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(50),
                          image: DecorationImage(
                              image: NetworkImage(Core().Url + Foto)),
                        ),
                      ),
                      SizedBox(
                        width: 15,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            "Selamat Datang , namawali!"  ,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: CText),
                          ),
                          Text(
                            Nama,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: CText),
                          ),
                          Text(
                            (NIP == "") ? "-" : NIP,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w400,
                                color: CText),
                          )
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: 15,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        height: 125,
                        width: size.width * 0.43,
                        margin: EdgeInsets.only(right: 4),
                        padding:
                            EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white70,
                          borderRadius: BorderRadius.circular(12.0),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white70,
                              blurRadius: 4,
                              offset: Offset(4, 4), // Shadow position
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            Icon(
                              Icons.watch_later_outlined,
                              color: Colors.blue,
                            ),
                            Text(
                              jam,
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w500,
                                  color: CText),
                            ),
                            SizedBox(
                              height: 5,
                            ),
                            Text(
                              formatDate(DateTime.now(),
                                  [D, ', ', dd, ' ', MM, ' ', yyyy]),
                              style: TextStyle(
                                  fontSize: 16,
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
                              return LokasiKampusScreen();
                            }));
                          },
                          child: Container(
                            height: 125,
                            width: size.width * 0.43,
                            margin: EdgeInsets.only(left: 4),
                            padding: EdgeInsets.symmetric(
                                horizontal: 18, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white70,
                              borderRadius: BorderRadius.circular(12.0),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.white70,
                                  blurRadius: 4,
                                  offset: Offset(4, 4), // Shadow position
                                ),
                              ],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: <Widget>[
                                Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.blue,
                                ),
                                Text(
                                  LokasiAnda,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w500,
                                      color: CText),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  "Lokasi Anda",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: CText),
                                ),
                              ],
                            ),
                          )),
                    )
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    ));
  }

  Expanded _buildStatCard(
      String title, String count, String ket, MaterialColor color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 15.0),
        padding: const EdgeInsets.all(10.0),
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.8),
              blurRadius: 4,
              offset: Offset(2, 4), // Shadow position
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
            ),
            SizedBox(
              height: 1,
            ),
            Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            (ket != "")
                ? Text(
                    ket,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.0,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : SizedBox(),
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
              margin:
                  ssBody ? EdgeInsets.only(top: 0) : EdgeInsets.only(top: 30),
              duration: const Duration(milliseconds: 500),
              curve: Curves.fastEaseInToSlowEaseOut,
              child: Container(
                padding: const EdgeInsets.all(20.0),
                margin:
                    const EdgeInsets.symmetric(vertical: 5.0, horizontal: 15.0),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
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
                    Text(
                      'Menu Presensi :',
                      style: const TextStyle(
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
                                    return SemuaMenu();
                                  }));
                                },
                                child: Column(
                                  children: <Widget>[
                                    Image.asset(
                                      "assets/icons/semua_menu.png",
                                      height: screenHeight * 0.07,
                                    ),
                                    SizedBox(height: screenHeight * 0.003),
                                    Text(
                                      "Semua\nMenu",
                                      style: const TextStyle(
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
                                        return AbsenHarianScreen();
                                      }));
                                    } else {
                                      if (DataAbsenPulang == null) {
                                        _showMyDialog("Presensi Harian",
                                            "Anda belum melakukan Presensi Pulang Harian. Silakan Presensi Pulang Harian terlebih dahulu !",
                                            MaterialPageRoute(
                                                builder: (context) {
                                          return AbsenPulangHarianScreen();
                                        }));
                                      } else {
                                        if (status_lintashari == 1) {
                                          Navigator.push(context,
                                              MaterialPageRoute(
                                                  builder: (context) {
                                            return AbsenHarianScreen();
                                          }));
                                        } else {
                                          _showNotif("Presensi Harian",
                                              "Anda Sudah Melakukan Presensi Hari ini");
                                        }
                                      }
                                    }
                                  } else {
                                    _showNotif("Presensi Harian",
                                        "Anda Dilarang Melakukan Presensi Karena Sedang Dinas Luar");
                                  }
                                },
                                child: Column(
                                  children: <Widget>[
                                    Image.asset(
                                      (StatusDinasLuar == 1)
                                          ? "assets/icons/presensi_datang_warna.png"
                                          : "assets/icons/presensi_datang_monokrom.png",
                                      height: screenHeight * 0.07,
                                    ),
                                    SizedBox(height: screenHeight * 0.003),
                                    Text(
                                      "Presensi\nMasuk",
                                      style: const TextStyle(
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    )
                                  ],
                                )),
                            // TextButton(
                            //     onPressed: () {
                            //       if (StatusDinasLuar == 1) {
                            //         if (DataIstirahat == null) {
                            //           Navigator.push(context,
                            //               MaterialPageRoute(builder: (context) {
                            //             return AbsenIstirahatScreen();
                            //           }));
                            //         } else {
                            //           _showMyDialog("Presensi Mata",
                            //               "Anda belum melakukan Presensi Selesai Istirahat. Silakan Presensi Selesai Istirahat terlebih dahulu !",
                            //               MaterialPageRoute(builder: (context) {
                            //             return AbsenSelesaiIstirahatScreen();
                            //           }));
                            //         }
                            //       } else {
                            //         _showNotif("Presensi Harian",
                            //             "Anda Dilarang Melakukan Presensi Karena Sedang Dinas Luar");
                            //       }
                            //     },
                            //     child: Column(
                            //       children: <Widget>[
                            //         Image.asset(
                            //           (StatusDinasLuar == 1)
                            //               ? "assets/icons/istirahat_keluar_warna.png"
                            //               : "assets/icons/istirahat_keluar_monokrom.png",
                            //           height: screenHeight * 0.07,
                            //         ),
                            //         SizedBox(height: screenHeight * 0.003),
                            //         Text(
                            //           "Istirahat\nKeluar",
                            //           style: const TextStyle(
                            //             fontSize: 11.0,
                            //             fontWeight: FontWeight.w500,
                            //           ),
                            //           textAlign: TextAlign.center,
                            //         )
                            //       ],
                            //     )),
                            TextButton(
                                onPressed: () {
                                  if (StatusDinasLuar == 1) {
                                    if (DataAbsen == null) {
                                      _showMyDialog("Presensi Harian",
                                          "Anda belum melakukan Presensi Harian. Silakan Presensi Harian terlebih dahulu !",
                                          MaterialPageRoute(builder: (context) {
                                        return AbsenHarianScreen();
                                      }));
                                    } else {
                                      if (DataAbsenPulang == null) {
                                        Navigator.push(context,
                                            MaterialPageRoute(
                                                builder: (context) {
                                          return AbsenPulangHarianScreen();
                                        }));
                                      } else {
                                        _showMyDialog("Presensi Harian",
                                            "Apakah Anda Membatalkan Pulang Sebelumnya ?",
                                            MaterialPageRoute(
                                                builder: (context) {
                                          return AbsenPulangHarianScreen();
                                        }));
                                      }
                                    }
                                  } else {
                                    _showNotif("Presensi Harian",
                                        "Anda Dilarang Melakukan Presensi Karena Sedang Dinas Luar");
                                  }
                                },
                                // padding:
                                //     EdgeInsets.symmetric(vertical: 0, horizontal: -10),
                                child: Column(
                                  children: <Widget>[
                                    Image.asset(
                                      (StatusDinasLuar == 1)
                                          ? "assets/icons/presensi_pulang_warna.png"
                                          : "assets/icons/presensi_pulang_monokrom.png",
                                      height: screenHeight * 0.07,
                                    ),
                                    SizedBox(height: screenHeight * 0.003),
                                    Text(
                                      "Presensi\nPulang",
                                      style: const TextStyle(
                                        fontSize: 11.0,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    )
                                  ],
                                )),
                            
                    ),
                  ],
                ),
              ),
            )));
  }

  SliverToBoxAdapter _buildMenuWFH(double screenHeight) {
    return SliverToBoxAdapter(
        child: AnimatedOpacity(
            opacity: ssBody ? 1 : 0,
            duration: const Duration(milliseconds: 500),
            child: AnimatedContainer(
              margin:
                  ssBody ? EdgeInsets.only(top: 0) : EdgeInsets.only(top: 30),
              duration: const Duration(milliseconds: 500),
              curve: Curves.fastEaseInToSlowEaseOut,
              child: Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Colors.white70,
                  borderRadius: BorderRadius.circular(12.0),
                  boxShadow: [
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
                    Text(
                      'Menu Presensi :',
                      style: const TextStyle(
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
                                    return SemuaMenu();
                                  }));
                                },
                                child: Column(
                                  children: <Widget>[
                                    Image.asset(
                                      "assets/icons/semua_menu.png",
                                      height: screenHeight * 0.07,
                                    ),
                                    SizedBox(height: screenHeight * 0.003),
                                    Text(
                                      "Semua\nMenu",
                                      style: const TextStyle(
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
                                        return AbsenWFScreen();
                                      }));
                                    } else {
                                      if (DataAbsenPulang == null) {
                                        _showMyDialog("Presensi WFH",
                                            "Anda belum melakukan Presensi Selesai WFH. Silakan Presensi Selesai WFH terlebih dahulu !",
                                            MaterialPageRoute(
                                                builder: (context) {
                                          return AbsenSelesaiWFScreen();
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
                                    Text(
                                      "Presensi\nMulai WFH",
                                      style: const TextStyle(
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
                                      _showMyDialog("Presensi WFH",
                                          "Anda belum melakukan Presensi WFH. Silakan Presensi WFH terlebih dahulu !",
                                          MaterialPageRoute(builder: (context) {
                                        return AbsenWFScreen();
                                      }));
                                    } else {
                                      if (DataAbsenPulang == null) {
                                        Navigator.push(context,
                                            MaterialPageRoute(
                                                builder: (context) {
                                          return AbsenSelesaiWFScreen();
                                        }));
                                      } else {
                                        _showMyDialog("Presensi WFH",
                                            "Apakah Anda Membatalkan Selesai WFH Sebelumnya ?",
                                            MaterialPageRoute(
                                                builder: (context) {
                                          return AbsenSelesaiWFScreen();
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
                                    Text(
                                      "Presensi\nSelesai WFH",
                                      style: const TextStyle(
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
                child: Text('Keluar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('OK'),
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
                child: Text('Keluar'),
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
            title: Text("Perbarui Aplikasi"),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text("Mohon Untuk Perbarui Aplikasi Anda Saat Ini."),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text(
                  'Lanjut Tanpa Pembaharuan',
                  style: TextStyle(color: CWarning),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Perbarui Sekarang'),
                onPressed: () {
                  LaunchReview.launch();
                },
              )
            ],
          ),
        );
      },
    );
  }
}

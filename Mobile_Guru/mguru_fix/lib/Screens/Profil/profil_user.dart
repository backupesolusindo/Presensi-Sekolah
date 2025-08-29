// import 'package:mobile_presensi_kdtg/circular_profile_avatar.dart';
import 'dart:convert';
import 'dart:io';

import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:flutter/material.dart';
// Import untuk foto_profil dihapus karena tidak digunakan lagi
// import 'package:mobile_presensi_kdtg/Screens/Profil/foto_profil.dart';
import 'package:mobile_presensi_kdtg/constants.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'package:mobile_presensi_kdtg/utils/custom_clipper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ProfilUser extends StatefulWidget {
  const ProfilUser({super.key});

  @override
  _ProfilUserState createState() => _ProfilUserState();
}

class _ProfilUserState extends State<ProfilUser> {
  String UUID = "";
  String NamaPegawai = ""; // Default value
  String NIP = ""; // Default value
  String Foto = "desain/user.png";
  String Email = "", Unit = "";
  var DataPegawai;
  int jmlPre = 0, jmlCuti = 0, jmlKegiatan = 0;

  @override
  void initState() {
    super.initState();
    getPref(); // Ambil data dari SharedPreferences
    getDataDash(); // Ambil data dari API
  }

  Future<void> getPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      // Ambil NamaPegawai dan NIP dari SharedPreferences
      NamaPegawai = prefs.getString("NamaPegawai") ?? "";
      NIP = prefs.getString("NIP") ?? "";
    });
  }

  Future<void> getDataDash() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    UUID = prefs.getString("ID") ?? "";

    if (UUID.isNotEmpty) {
      var res = await http.get(
        Uri.parse("${Core().ApiUrl}Dash/get_dash/$UUID"),
        headers: {"Accept": "application/json"},
      );

      if (res.statusCode == 200) {
        var resBody = json.decode(res.body);
        setState(() {
          DataPegawai = resBody['data']["pegawai"];
          jmlCuti = resBody['data']['jmlCutiBln'];
          jmlKegiatan = resBody['data']['jmlKegiatanBln'];
          jmlPre = resBody['data']['jmlPresensiBln'];
          // Hanya update jika data tersedia
          if (DataPegawai != null) {
            NamaPegawai = DataPegawai["nama_pegawai"] ?? NamaPegawai;
            NIP = DataPegawai["NIP"] ?? NIP;
            Email = DataPegawai["email"] ?? Email;
            Unit = DataPegawai["unit"] ?? Unit;
            
            String? fotoFromAPI = DataPegawai["foto_profil"];
            Foto = (fotoFromAPI != null && fotoFromAPI.isNotEmpty && !fotoFromAPI.contains("logo.png")) 
                   ? fotoFromAPI 
                   : "desain/user.png";
          }
        });
      } else {
        print("Error: ${res.statusCode}");
      }
    }
  }

  // Fungsi untuk mendapatkan path foto dari SharedPreferences per user
  Future<String?> getFotoFromPreferences() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String key = "foto_profil_path_$UUID"; // Gunakan UUID sebagai identifier
      return prefs.getString(key);
    } catch (e) {
      print("Error getting foto from preferences: $e");
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: CBackground,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            SizedBox(
              height: 300.0,
              width: size.width,
              child: Stack(
                children: <Widget>[
                  ClipPath(
                    clipper: MyCustomClipper(),
                    child: Container(
                      decoration: const BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/gedung_smpn_3_jember.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: const Alignment(0, 1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        // Menghapus TextButton dan navigasi ke halaman upload
                        // Foto profil sekarang hanya display saja, tidak bisa diklik
                        _buildProfileAvatar(),
                        const SizedBox(height: 4.0),
                        Text(
                          NamaPegawai,
                          style: const TextStyle(
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          softWrap: true,
                        ),
                        const SizedBox(height: 4.0),
                        Text(
                          NIP,
                          style: TextStyle(
                            fontSize: 14.0,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _CartItem(
              "Email",
              Email,
              const Icon(
                Icons.mail_outline_rounded,
                size: 40.0,
                color: kPrimaryColor,
              ),
            ),
            _CartItem(
              "Unit",
              Unit,
              const Icon(
                Icons.location_city_rounded,
                size: 40.0,
                color: kPrimaryColor,
              ),
            ),
            _CartItem(
              "Jumlah Presensi Bulan Ini",
              "$jmlPre Presensi",
              const Icon(
                Icons.alarm_on,
                size: 40.0,
                color: approval_presensi,
              ),
            ),
            _CartItem(
              "Jumlah Kegiatan Bulan Ini",
              "$jmlKegiatan Kegiatan",
              const Icon(
                Icons.directions_walk_outlined,
                size: 40.0,
                color: approval_kegiatan,
              ),
            ),
            _CartItem(
              "Jumlah Cuti Bulan Ini",
              "$jmlCuti Cuti",
              const Icon(
                Icons.home_work_rounded,
                size: 40.0,
                color: approval_cuti,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget untuk menampilkan avatar profil dengan prioritas dari SharedPreferences
  // Sekarang tidak bisa diklik lagi
  Widget _buildProfileAvatar() {
    return FutureBuilder<String?>(
      future: getFotoFromPreferences(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          String? savedPath = snapshot.data;
          if (savedPath != null && File(savedPath).existsSync()) {
            // Gunakan foto dari SharedPreferences jika ada
            return Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4.0),
                image: DecorationImage(
                  image: FileImage(File(savedPath)),
                  fit: BoxFit.cover,
                ),
              ),
            );
          }
        }
        
        // Fallback ke CircularProfileAvatar dengan network image
        return CircularProfileAvatar(
          Core().Url + Foto,
          borderWidth: 4.0,
          radius: 60.0,
          errorWidget: (context, url, error) {
            return Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4.0),
                color: Colors.grey[300],
              ),
              child: const Icon(
                Icons.person,
                size: 60,
                color: Colors.grey,
              ),
            );
          },
        );
      },
    );
  }

  Container _CartItem(String Title, String Ket, Icon icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 4,
            offset: const Offset(4, 4), // Shadow position
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 21.0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            icon,
            const SizedBox(width: 24.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  Ket,
                  style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4.0),
                Text(
                  Title,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
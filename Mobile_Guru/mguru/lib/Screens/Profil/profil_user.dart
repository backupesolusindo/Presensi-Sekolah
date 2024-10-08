// import 'package:mobile_presensi_kdtg/circular_profile_avatar.dart';
import 'dart:convert';

import 'package:circular_profile_avatar/circular_profile_avatar.dart';
import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/Login/login_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Login/post_logout.dart';
import 'package:mobile_presensi_kdtg/Screens/Profil/foto_profil.dart';
import 'package:mobile_presensi_kdtg/constants.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'package:mobile_presensi_kdtg/utils/custom_clipper.dart';
import 'package:mobile_presensi_kdtg/widgets/top_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class ProfilUser extends StatefulWidget {
  @override
  _ProfilUserState createState() => _ProfilUserState();
}

class _ProfilUserState extends State<ProfilUser> {
  String UUID = "";
  String NamaPegawai = "Nama Pegawai";
  String NIP = "-";
  String Foto = "desain/POLIJE_mini.png";
  String Email = "", Unit = "";
  var DataPegawai;
  int jmlPre = 0, jmlCuti = 0, jmlKegiatan = 0;
  int statusLoading = 0;

  @override
  void initState() {
    // TODO: implement initState
    // WidgetsBinding.instance.addPostFrameCallback(getPref());
    super.initState();
    getDataDash();
  }

  Future<String> getDataDash() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    UUID = prefs.getString("ID")!;
    var res = await http.get(Uri.parse(Core().ApiUrl + "Dash/get_dash/" + UUID),
        headers: {"Accept": "application/json"});
    var resBody = json.decode(res.body);
    setState(() {
      DataPegawai = resBody['data']["pegawai"];
      jmlCuti = resBody['data']['jmlCutiBln'];
      jmlKegiatan = resBody['data']['jmlKegiatanBln'];
      jmlPre = resBody['data']['jmlPresensiBln'];
      NamaPegawai = DataPegawai["nama_pegawai"];
      NIP = DataPegawai["NIP"];
      Email = DataPegawai["email"];
      Unit = DataPegawai["unit"];
      Foto = DataPegawai["foto_profil"];
    });
    print(resBody);
    return "";
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: CBackground,
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            Container(
              height: 300.0,
              width: size.width,
              child: Stack(
                children: <Widget>[
                  Container(),
                  ClipPath(
                    clipper: MyCustomClipper(),
                    child: Container(
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image: AssetImage('assets/images/gedung_klinik.jpg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment(0, 1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        TextButton(
                            onPressed: () {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return Foto_Profil();
                              }));
                            },
                            child: CircularProfileAvatar(
                              Core().Url + Foto,
                              borderWidth: 4.0,
                              radius: 60.0,
                            )),
                        SizedBox(height: 4.0),
                        Text(
                          NamaPegawai,
                          style: TextStyle(
                            fontSize: 21.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4.0),
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
            SizedBox(height: 16),
            _CartItem(
                "Email",
                Email,
                Icon(
                  Icons.mail_outline_rounded,
                  size: 40.0,
                  color: kPrimaryColor,
                )),
            _CartItem(
                "Unit",
                Unit,
                Icon(
                  Icons.location_city_rounded,
                  size: 40.0,
                  color: kPrimaryColor,
                )),
            _CartItem(
                "Jumlah Presensi Bulan Ini",
                jmlPre.toString() + " Presensi",
                Icon(
                  Icons.alarm_on,
                  size: 40.0,
                  color: approval_presensi,
                )),
            _CartItem(
                "Jumlah Kegiatan Bulan Ini",
                jmlKegiatan.toString() + " Kegiatan",
                Icon(
                  Icons.directions_walk_outlined,
                  size: 40.0,
                  color: approval_kegiatan,
                )),
            _CartItem(
                "Jumlah Cuti Bulan Ini",
                jmlCuti.toString() + " Cuti",
                Icon(
                  Icons.home_work_rounded,
                  size: 40.0,
                  color: approval_cuti,
                )),
            // SizedBox(height: 30,),
            // TextButton(onPressed: ()async{
            //   SharedPreferences prefs = await SharedPreferences.getInstance();
            //   print("Logout");
            //   PostLogout.connectToApi(prefs.getString("ID")).then((value) {
            //     setState(() {
            //       // pesan = "tes api";
            //       // pesan = value.message;
            //       statusLoading = 0;
            //     });
            //       prefs.clear();
            //       Navigator.of(context).pop();
            //       Navigator.push(
            //         context,
            //         MaterialPageRoute(
            //           builder: (context) {
            //             return LoginScreen();
            //           },
            //         ),
            //       );
            //     });
            // }, child: (statusLoading == 1) ? CircularProgressIndicator() : _CartItem("Log Out Aplikasi Monitoring", "LOG OUT",
            //     Icon(
            //       Icons.logout,
            //       size: 40.0,
            //       color: CDanger,
            //     ))),
          ],
        ),
      ),
    );
  }

  Container _CartItem(String Title, String Ket, Icon _icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.0),
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 4,
            offset: Offset(4, 4), // Shadow position
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
            _icon,
            SizedBox(width: 24.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  Ket,
                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.w700),
                ),
                SizedBox(height: 4.0),
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

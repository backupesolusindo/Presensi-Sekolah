import 'dart:ui';

import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/absen_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/JadwalWF/JadwalWF_Post.dart';
import 'package:mobile_presensi_kdtg/Screens/JadwalWF/components/background.dart';
import 'package:mobile_presensi_kdtg/Screens/Login/post_login.dart';
import 'package:mobile_presensi_kdtg/components/already_have_an_account_acheck.dart';
import 'package:mobile_presensi_kdtg/components/rounded_button.dart';
import 'package:mobile_presensi_kdtg/components/rounded_date_field.dart';
import 'package:mobile_presensi_kdtg/components/rounded_input_field.dart';
import 'package:file_picker/file_picker.dart';
import 'package:mobile_presensi_kdtg/constants.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_presensi_kdtg/components/rounded_password_field.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Body extends StatefulWidget {
  @override
  _Body createState() => _Body();
}

class _Body extends State<Body> {
  List jadwal = [];
  bool isLoading = false;
  String _SelecTahun = formatDate(DateTime.now(), [yyyy]);
  String _SelecBulan = formatDate(DateTime.now(), [mm]);
  String UUID = "";
  String status_approval = "Menunggu Approval";
  int s_approv = 0;
  Color color = CWarning;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchJadwal();
    getTanggal();
  }

  List dataBulan = []; //edited line
  List dataTahun = []; //edited line
  Future<String> getTanggal() async {
    print("getJenis");
    var res = await http.get(Uri.parse(Core().ApiUrl + "JadwalWF/getTanggal"),
        headers: {"Accept": "application/json"});
    var resBody = json.decode(res.body);
    setState(() {
      dataBulan = resBody['bulan'];
      dataTahun = resBody['tahun'];
    });
    print(resBody);
    return "";
  }

  fetchJadwal() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var url = Uri.parse(Core().ApiUrl + "JadwalWF/getJadwal");
    var response = await http.post(url, body: {
      "uuid": prefs.getString("ID"),
      "tahun": _SelecTahun,
      "bulan": _SelecBulan,
    });
    UUID = prefs.getString("ID")!;
    print(response.body);
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      s_approv = int.parse(data['status_approval']);
      if (s_approv == 1) {
        status_approval = "Jadwal Kerja Approved";
        color = kPrimaryColor;
      } else if (s_approv == 2) {
        status_approval = "Jadwal Kerja Ditolak";
        color = CDanger;
      } else {
        status_approval = "Menunggu Approval";
        color = CWarning;
      }
      var items = data['data'];
      setState(() {
        jadwal = items;
        isLoading = false;
      });
    } else {
      jadwal = [];
      isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Background(
        filter: Container(
          child: Column(
            children: <Widget>[
              SizedBox(height: 32),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: size.width * 0.35,
                    child: Column(
                      children: [
                        Container(
                          width: size.width * 0.45,
                          child: Text("Pilih Tahun"),
                        ),
                        DropdownButton(
                          hint: Text("Pilih Tahun : "),
                          dropdownColor: Colors.white,
                          icon: Icon(Icons.arrow_drop_down),
                          iconSize: 24,
                          isExpanded: true,
                          underline: SizedBox(),
                          style: TextStyle(color: Colors.black, fontSize: 16),
                          items: dataTahun.map((item) {
                            return new DropdownMenuItem(
                              child: new Text(item['tahun']),
                              value: item['tahun'].toString(),
                            );
                          }).toList(),
                          onChanged: (newVal) {
                            setState(() {
                              _SelecTahun = newVal as String;
                            });
                          },
                          value: _SelecTahun,
                        )
                      ],
                    ),
                  ),
                  SizedBox(width: 32),
                  Container(
                    width: size.width * 0.35,
                    child: Column(
                      children: [
                        Container(
                          width: size.width * 0.45,
                          child: Text("Pilih Bulan"),
                        ),
                        DropdownButton(
                          hint: Text("Pilih Bulan : "),
                          dropdownColor: Colors.white,
                          icon: Icon(Icons.arrow_drop_down),
                          iconSize: 24,
                          isExpanded: true,
                          underline: SizedBox(),
                          style: TextStyle(color: Colors.black, fontSize: 16),
                          items: dataBulan.map((item) {
                            return new DropdownMenuItem(
                              child: new Text(item['bulan']),
                              value: item['kode'].toString(),
                            );
                          }).toList(),
                          onChanged: (newVal) {
                            setState(() {
                              _SelecBulan = newVal as String;
                            });
                          },
                          value: _SelecBulan,
                        )
                      ],
                    ),
                  ),
                  Container(
                    margin: EdgeInsets.only(top: 12, right: 6),
                    width: size.width * 0.15,
                    decoration: BoxDecoration(
                      color: kPrimaryLightColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextButton(
                        onPressed: () {
                          fetchJadwal();
                        },
                        child: Icon(
                          Icons.filter_alt_rounded,
                          color: kPrimaryColor,
                        )),
                  )
                ],
              ),
              Container(
                  width: size.width,
                  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10.0),
                      boxShadow: [
                        BoxShadow(
                          color: softblue,
                          offset: Offset(1.0, 3), //(x,y)
                          blurRadius: 5.0,
                        ),
                      ]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Text("Status Persetujuan :"),
                      SizedBox(height: 4),
                      Text(status_approval,
                          style: TextStyle(
                              color: color,
                              fontSize: 16,
                              fontWeight: FontWeight.w700)),
                    ],
                  ))
            ],
          ),
        ),
        child: Container(
          margin: EdgeInsets.only(top: size.height * 0.24),
          child: getBody(),
        ));
  }

  Widget getBody() {
    Size size = MediaQuery.of(context).size;
    if (jadwal.contains(null) || isLoading) {
      return Center(
          child: CircularProgressIndicator(
        valueColor: new AlwaysStoppedAnimation<Color>(kPrimaryColor),
      ));
    }
    if (jadwal.length <= 0) {
      return Container(
          child: Image.asset(
        "assets/icons/jadwal_kerja.png",
        width: size.width * 0.8,
      ));
    } else {
      return GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, mainAxisSpacing: 16, crossAxisSpacing: 4),
          itemCount: jadwal.length,
          itemBuilder: (context, index) {
            return getCard(jadwal[index]);
          });
    }
  }

  Widget getCard(item) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: (item["kode_jenis"] == "99")
                  ? CDanger
                  : (item["kode_jenis"] == "1")
                      ? kDarkPrimaryColor
                      : (item["kode_jenis"] == "2")
                          ? CSuccess
                          : softblue,
              offset: Offset(1.0, 3), //(x,y)
              blurRadius: 5.0,
            ),
          ]),
      child: TextButton(
        onPressed: () {
          if (s_approv == 1 || item["kode_jenis"] == "99") {
          } else {
            _showMyDialog(item["tglF"].toString(), UUID);
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              item["jenis_kerja"],
              style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 2),
            Text(
              item["tanggal"].toString(),
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
            ),
            Text(
              item["hari"],
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w400),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showMyDialog(String Tanggal, String UUID) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AlertDialog(
            title: Text("Approval Kegiatan"),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text("Pilih Jadwal Kerja Anda Pada Tanggal : " +
                      Tanggal +
                      "?"),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('WFH'),
                onPressed: () {
                  JadwalWFPost.connectToApi(Tanggal, UUID, "2")
                      .then((value) {});
                  setState(() {
                    fetchJadwal();
                  });
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('WFO'),
                onPressed: () {
                  JadwalWFPost.connectToApi(Tanggal, UUID, "1")
                      .then((value) {});
                  setState(() {
                    fetchJadwal();
                  });
                  Navigator.of(context).pop();
                },
              )
            ],
          ),
        );
      },
    );
  }
}

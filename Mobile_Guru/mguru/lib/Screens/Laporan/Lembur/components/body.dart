import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/absen_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Laporan/Lembur/components/background.dart';
import 'package:mobile_presensi_kdtg/Screens/dashboard_screen.dart';
import 'package:mobile_presensi_kdtg/components/flat_date_field.dart';
import 'package:mobile_presensi_kdtg/components/rounded_date_field.dart';
import 'package:mobile_presensi_kdtg/constants.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Body extends StatefulWidget {
  @override
  _Body createState() => _Body();
}

class _Body extends State<Body> {
  List users = [];
  bool isLoading = false;
  String warnaPilih = "";
  final txtTanggalMulai = TextEditingController();
  final txtTanggalAkhir = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    txtTanggalMulai.text = formatDate(DateTime.now(), [dd, '-', mm, '-', yyyy]);
    txtTanggalAkhir.text = formatDate(DateTime.now(), [dd, '-', mm, '-', yyyy]);
    fetchUser();
  }

  fetchUser() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var url = Uri.parse(Core().ApiUrl + "RiwayatAbsen/laporan_lembur");
    var response = await http.post(url, body: {
      "uuid": prefs.getString("ID"),
      "status": warnaPilih,
      "mulai": txtTanggalMulai.text,
      "akhir": txtTanggalAkhir.text,
    });
    print(response.body);
    if (response.statusCode == 200) {
      var items = json.decode(response.body)['data'];
      setState(() {
        users = items;
        isLoading = false;
      });
    } else {
      users = [];
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
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  FlatDateField(
                    width: size.width * 0.37,
                    hintText: "Awal",
                    IdCon: txtTanggalMulai,
                  ),
                  FlatDateField(
                    width: size.width * 0.37,
                    hintText: "Akhir",
                    IdCon: txtTanggalAkhir,
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
                          fetchUser();
                        },
                        child: Icon(
                          Icons.filter_alt_rounded,
                          color: kPrimaryColor,
                        )),
                  )
                ],
              ),
              SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 0, horizontal: 8),
                        width: size.width * 0.3,
                        height: size.height * 0.05,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: TextButton(
                            // padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                            // color: kPrimaryColor,
                            onPressed: () {
                              warnaPilih = "";
                              fetchUser();
                            },
                            child: Text(
                              "Semua",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 0, horizontal: 1),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: TextButton(
                            // padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                            // color: warnaPilih == "1" ? softblue : Colors.white,
                            onPressed: () {
                              setState(() {
                                warnaPilih = "1";
                                fetchUser();
                              });
                            },
                            child: Text(
                              "Diterima",
                              style: TextStyle(color: kPrimaryColor),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 0, horizontal: 1),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: TextButton(
                            // padding: EdgeInsets.symmetric(
                            //     vertical: 10, horizontal: 20),
                            // color: warnaPilih == "2" ? softblue : Colors.white,
                            onPressed: () {
                              setState(() {
                                warnaPilih = "2";
                                fetchUser();
                              });
                            },
                            child: Text(
                              "Ditolak",
                              style: TextStyle(color: kPrimaryColor),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin:
                            EdgeInsets.symmetric(vertical: 0, horizontal: 1),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: TextButton(
                            // padding: EdgeInsets.symmetric(
                            //     vertical: 10, horizontal: 20),
                            // color: warnaPilih == "0" ? softblue : Colors.white,
                            onPressed: () {
                              setState(() {
                                warnaPilih = "0";
                                fetchUser();
                              });
                            },
                            child: Text(
                              "Menunggu Respon",
                              style: TextStyle(color: kPrimaryColor),
                            ),
                          ),
                        ),
                      )
                    ]),
              ),
            ],
          ),
        ),
        child: Expanded(
          child: getBody(),
        ));
  }

  Widget getBody() {
    Size size = MediaQuery.of(context).size;
    if (users.contains(null) || isLoading) {
      return Center(
          child: CircularProgressIndicator(
        valueColor: new AlwaysStoppedAnimation<Color>(kPrimaryColor),
      ));
    }
    if (users.length <= 0) {
      return Container(
          child: Image.asset(
        "assets/ilustrasi/laporankegiatan.png",
        width: size.width * 0.8,
      ));
    } else {
      return ListView.builder(
          scrollDirection: Axis.vertical,
          shrinkWrap: true,
          itemCount: users.length,
          itemBuilder: (context, index) {
            return getCard(users[index]);
          });
    }
  }

  Widget getCard(item) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: (item['status_aproval'] == "1")
                  ? Colors.blue.withOpacity(0.4)
                  : (item['status_aproval'] == "2")
                      ? Colors.redAccent.withOpacity(0.2)
                      : Colors.deepOrange.withOpacity(0.4),
              offset: Offset(1.0, 3), //(x,y)
              blurRadius: 5.0,
            ),
          ]),
      child: TextButton(
        onPressed: () {},
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: [
                Column(children: [
                  // (_image == null) ?
                  Container(
                    margin: EdgeInsets.only(right: 8.0, top: 8.0),
                    height: 60,
                    width: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(3),
                      image: DecorationImage(
                          image: NetworkImage(Core().Url + item["foto"])),
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  // Row(
                  //   children: <Widget>[
                  //     Column(
                  //       crossAxisAlignment: CrossAxisAlignment.center,
                  //       children: [
                  //         Text(item["jam_presensi"], style: const TextStyle(fontSize: 12)),
                  //         Text(item["tgl_presensi"], style: const TextStyle(fontSize: 10)),
                  //       ],
                  //     ),
                  //     Column(
                  //       crossAxisAlignment: CrossAxisAlignment.start,
                  //       children: [
                  //
                  //       ],
                  //     )
                  //   ],
                  // ),
                ]),
                Padding(
                  padding:
                      EdgeInsets.only(left: 25, bottom: 5, top: 15, right: 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(item['lembur']['keterangan_lembur'],
                          style: const TextStyle(
                              color: kPrimaryColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w800)),
                      SizedBox(
                        height: 4,
                      ),
                      Row(
                        children: <Widget>[
                          Container(
                              width: size.width * 0.21,
                              child: Text("Unit",
                                  style: const TextStyle(fontSize: 12))),
                          Container(
                              width: size.width * 0.37,
                              child: Text(": " + item['lembur']['nama_unit'],
                                  style: const TextStyle(fontSize: 12)))
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Container(
                              width: size.width * 0.21,
                              child: Text("Tanggal",
                                  style: const TextStyle(fontSize: 12))),
                          Container(
                              width: size.width * 0.37,
                              child: Text(": " + item['tgl_presensi'],
                                  style: const TextStyle(fontSize: 12)))
                        ],
                      ),
                      Row(
                        children: <Widget>[
                          Container(
                              width: size.width * 0.21,
                              child: Text("Jam Mulai",
                                  style: const TextStyle(fontSize: 12))),
                          Container(
                              width: size.width * 0.37,
                              child: Text(": " + item['jam_presensi'],
                                  style: const TextStyle(fontSize: 12)))
                        ],
                      ),
                      if (item['jam_presensi_selesai'] != null)
                        Row(
                          children: <Widget>[
                            Container(
                                width: size.width * 0.21,
                                child: Text("Jam Selesai",
                                    style: const TextStyle(fontSize: 12))),
                            Container(
                                width: size.width * 0.37,
                                child: Text(": " + item['jam_presensi_selesai'],
                                    style: const TextStyle(fontSize: 12)))
                          ],
                        ),
                      if (item['jam_presensi_selesai'] != null)
                        Row(
                          children: <Widget>[
                            Container(
                                width: size.width * 0.21,
                                child: Text("Total Jam",
                                    style: const TextStyle(fontSize: 12))),
                            Container(
                                width: size.width * 0.37,
                                child: Text(": " + item['total_jam'],
                                    style: const TextStyle(fontSize: 12)))
                          ],
                        ),
                      if (item['jam_presensi_selesai'] == null)
                        Row(
                          children: <Widget>[
                            Container(
                                width: size.width * 0.21,
                                child: Text("Jam Selesai",
                                    style: const TextStyle(fontSize: 12))),
                            Container(
                                width: size.width * 0.37,
                                child: Text(": Belum Presensi",
                                    style: const TextStyle(fontSize: 12)))
                          ],
                        ),
                      SizedBox(
                        height: 8,
                      ),
                      Container(
                        width: 90.0,
                        height: 35.0,
                        margin: EdgeInsets.only(left: 140),
                        decoration: BoxDecoration(
                          color: (item['status_aproval'] == "1")
                              ? softblue
                              : (item['status_aproval'] == "2")
                                  ? softred
                                  : softorange,
                          borderRadius: BorderRadius.circular(20.0),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          (item['status_aproval'] == "1")
                              ? 'Diterima'
                              : (item['status_aproval'] == "2")
                                  ? 'Ditolak'
                                  : 'Menunggu',
                          style: TextStyle(
                            color: (item['status_aproval'] == "1")
                                ? Colors.blue
                                : (item['status_aproval'] == "2")
                                    ? Colors.redAccent
                                    : Colors.deepOrange,
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16)
          ],
        ),
      ),
    );
  }
}

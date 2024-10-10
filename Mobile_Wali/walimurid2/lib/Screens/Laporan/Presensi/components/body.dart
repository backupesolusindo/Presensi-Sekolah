import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/Laporan/Presensi/components/background.dart';
import 'package:mobile_presensi_kdtg/components/flat_date_field.dart';
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
    var url = Uri.parse(Core().ApiUrl + "RiwayatAbsen/riwayat_harian");
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
              SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  FlatDateField(
                    width: size.width * 0.37,
                    hintText: "Dari Tanggal",
                    IdCon: txtTanggalMulai,
                  ),
                  FlatDateField(
                    width: size.width * 0.37,
                    hintText: "Sampai Tanggal",
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
                            // padding: EdgeInsets.symmetric(
                            //     vertical: 10, horizontal: 20),
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
                            // padding: EdgeInsets.symmetric(
                            //     vertical: 10, horizontal: 20),
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
        "assets/ilustrasi/laporanpresensi.png",
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
    var waktu = item['waktu'];
    var status_absensi = item['status_absensi'];
    var foto = item['foto'];
    var waktu_pulang = item['waktu_pulang'];
    var waktu_istirahat = item['waktu_istirahat'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10.0),
          boxShadow: [
            BoxShadow(
              color: (item['status_absensi'] == "1")
                  ? Colors.blue.withOpacity(0.4)
                  : (item['status_absensi'] == "2")
                      ? Colors.redAccent.withOpacity(0.2)
                      : Colors.deepOrange.withOpacity(0.4),
              offset: Offset(1.0, 3), //(x,y)
              blurRadius: 5.0,
            ),
          ]),
      child: Padding(
        padding: const EdgeInsets.all(5.0),
        child: ListTile(
          title: Row(
            children: <Widget>[
              Container(
                width: 70,
                height: 130,
                decoration: BoxDecoration(
                    color: kPrimaryColor,
                    borderRadius: BorderRadius.circular(3),
                    image: DecorationImage(
                        fit: BoxFit.cover,
                        image: NetworkImage(Core().Url + foto))),
              ),
              SizedBox(
                width: 10,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                      width: MediaQuery.of(context).size.width - 140,
                      child: Text(
                        waktu,
                        style: TextStyle(fontSize: 14),
                      )),
                  SizedBox(
                    height: 5,
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 90,
                        child: Text("Presensi Datang",
                            style: const TextStyle(fontSize: 12)),
                      ),
                      Container(
                        width: 120,
                        child: Text(
                          ": " + waktu.toString(),
                          style: const TextStyle(fontSize: 13),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Row(
                    children: <Widget>[
                      Container(
                        width: 90,
                        child: Text("Istirahat",
                            maxLines: 1,
                            softWrap: true,
                            overflow: TextOverflow.fade,
                            textAlign: TextAlign.left,
                            style: const TextStyle(
                              fontSize: 12,
                              wordSpacing: 10.0,
                            )),
                      ),
                      Container(
                        width: 120,
                        child: Text(
                          ": " + waktu_istirahat.toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      )
                    ],
                  ),
                  SizedBox(
                    height: 8,
                  ),
                  Row(
                    children: [
                      Container(
                        width: 90,
                        child: Text("Presensi Pulang",
                            style: const TextStyle(fontSize: 12)),
                      ),
                      Container(
                        width: 120,
                        child: Text(
                          ": " + waktu_pulang.toString(),
                          style: const TextStyle(fontSize: 13),
                        ),
                      )
                    ],
                  ),
                  Container(
                    width: 80.0,
                    height: 30.0,
                    margin: EdgeInsets.only(left: 145, top: 10),
                    decoration: BoxDecoration(
                      color: (item['status_absensi'] == "1")
                          ? softblue
                          : (item['status_absensi'] == "2")
                              ? softred
                              : softorange,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      (item['status_absensi'] == "1")
                          ? 'Diterima'
                          : (item['status_absensi'] == "2")
                              ? 'Ditolak'
                              : 'Menunggu',
                      style: TextStyle(
                        color: (item['status_absensi'] == "1")
                            ? Colors.blue
                            : (item['status_absensi'] == "2")
                                ? Colors.redAccent
                                : Colors.deepOrangeAccent,
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}

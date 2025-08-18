import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/Laporan/LuarJam/components/background.dart';
import 'package:mobile_presensi_kdtg/components/flat_date_field.dart';
import 'package:mobile_presensi_kdtg/constants.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class Body extends StatefulWidget {
  const Body({super.key});

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

  Future<void> fetchUser() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var url = Uri.parse("${Core().ApiUrl}RiwayatAbsen/laporan_luarjam");
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
                    margin: const EdgeInsets.only(top: 12, right: 6),
                    width: size.width * 0.15,
                    decoration: BoxDecoration(
                      color: kPrimaryLightColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: TextButton(
                        onPressed: () {
                          fetchUser();
                        },
                        child: const Icon(
                          Icons.filter_alt_rounded,
                          color: kPrimaryColor,
                        )),
                  )
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Container(
                        margin:
                            const EdgeInsets.symmetric(vertical: 0, horizontal: 8),
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
                            child: const Text(
                              "Semua",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin:
                            const EdgeInsets.symmetric(vertical: 0, horizontal: 1),
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
                            child: const Text(
                              "Diterima",
                              style: TextStyle(color: kPrimaryColor),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin:
                            const EdgeInsets.symmetric(vertical: 0, horizontal: 1),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: TextButton(
                            // padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                            // color: warnaPilih == "2" ? softblue : Colors.white,
                            onPressed: () {
                              setState(() {
                                warnaPilih = "2";
                                fetchUser();
                              });
                            },
                            child: const Text(
                              "Ditolak",
                              style: TextStyle(color: kPrimaryColor),
                            ),
                          ),
                        ),
                      ),
                      Container(
                        margin:
                            const EdgeInsets.symmetric(vertical: 0, horizontal: 1),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: TextButton(
                            // padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
                            // color: warnaPilih == "0" ? softblue : Colors.white,
                            onPressed: () {
                              setState(() {
                                warnaPilih = "0";
                                fetchUser();
                              });
                            },
                            child: const Text(
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
      return const Center(
          child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
      ));
    }
    if (users.isEmpty) {
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
    var waktu = item['waktu'];
    var statusAbsensi = item['status_absensi'];
    var foto = item['foto'];
    var jam = item['jam_presensi'];
    var tgl = item['tgl_presensi'];

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
              offset: const Offset(1.0, 3), //(x,y)
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
              const SizedBox(
                width: 10,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(
                      width: MediaQuery.of(context).size.width - 140,
                      child: const Text(
                        "Presensi Di Luar Jam",
                        style: TextStyle(fontSize: 14),
                      )),
                  const SizedBox(
                    height: 5,
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    children: [
                      const SizedBox(
                        width: 90,
                        child:
                            Text("Waktu", style: TextStyle(fontSize: 12)),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(
                          ": $jam",
                          style: const TextStyle(fontSize: 13),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(
                    height: 8,
                  ),
                  Row(
                    children: <Widget>[
                      const SizedBox(
                        width: 90,
                        child: Text("Tanggal",
                            maxLines: 1,
                            softWrap: true,
                            overflow: TextOverflow.fade,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 12,
                              wordSpacing: 10.0,
                            )),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(
                          ": $tgl",
                          style: const TextStyle(fontSize: 12),
                        ),
                      )
                    ],
                  ),
                  Container(
                    width: 80.0,
                    height: 30.0,
                    margin: const EdgeInsets.only(left: 145, top: 10),
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

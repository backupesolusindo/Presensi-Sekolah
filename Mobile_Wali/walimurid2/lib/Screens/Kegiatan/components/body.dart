import 'dart:ui';

import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/absen_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Kegiatan/absen_kegiatan_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Kegiatan/absen_kegiatan_wfh_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Kegiatan/components/background.dart';
import 'package:mobile_presensi_kdtg/Screens/dashboard_screen.dart';
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
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    this.fetchUser();
  }

  fetchUser() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var url = Uri.parse(Core().ApiUrl + "Kegiatan/getKegiatan");
    var response = await http.post(url, body: {
      "uuid": prefs.getString("ID"),
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
      child: getBody(),
    );
  }

  Widget getBody() {
    Size size = MediaQuery.of(context).size;
    if (users.contains(null) || users.length < 0 || isLoading) {
      return Center(
          child: CircularProgressIndicator(
        valueColor: new AlwaysStoppedAnimation<Color>(kPrimaryColor),
      ));
    }
    if (users.length <= 0) {
      return Container(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text("Jadwal Kegiatan Kosong",
              style: const TextStyle(
                  color: kPrimaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          SizedBox(
            height: 32,
          ),
          Image.asset(
            "assets/icons/kegiatan_tidak.png",
            width: size.width * 0.7,
          )
        ],
      ));
    } else {
      return ListView.builder(
          itemCount: users.length,
          itemBuilder: (context, index) {
            return getCard(users[index]);
          });
    }
  }

  Widget getCard(item) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: TextButton(
        onPressed: () {
          _showDialogKegiatan(
            item['idkegiatan'],
            double.parse(item['latitude']),
            double.parse(item['longtitude']),
            double.parse(item['radius']),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
              child: Text(
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
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(item['nama_kegiatan'],
                      style: const TextStyle(
                          color: kPrimaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  SizedBox(
                    height: 4,
                  ),
                  Row(
                    children: <Widget>[
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Jam Mulai",
                            style: const TextStyle(fontSize: 12),
                          ),
                          Text("Jam Selesai",
                              style: const TextStyle(fontSize: 12)),
                          Text("Lokasi", style: const TextStyle(fontSize: 12)),
                          Text("PIC", style: const TextStyle(fontSize: 12)),
                          Text("Unit Pengadaan",
                              style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(": " + item['jam_mulai'],
                              style: const TextStyle(fontSize: 12)),
                          Text(": " + item['jam_selesai'],
                              style: const TextStyle(fontSize: 12)),
                          Text(
                              (item['nama_gedung'] != null)
                                  ? ": " +
                                      item['nama_gedung'] +
                                      ", " +
                                      item['nama_kampus']
                                  : ": " + item['nama_kampus'],
                              style: const TextStyle(fontSize: 12)),
                          Text(": " + item['nama_pegawai'],
                              style: const TextStyle(fontSize: 12)),
                          Text(": " + item['nama_unit'],
                              style: const TextStyle(fontSize: 12)),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
            SizedBox(height: 16)
          ],
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
}

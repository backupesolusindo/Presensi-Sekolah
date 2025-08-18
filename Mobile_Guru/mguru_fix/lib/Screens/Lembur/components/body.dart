import 'dart:ui';

import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/Lembur/absen_lembur_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Lembur/components/background.dart';
import 'package:mobile_presensi_kdtg/constants.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'dart:async';
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
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    fetchUser();
  }

  Future<void> fetchUser() async {
    setState(() {
      isLoading = true;
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var url = Uri.parse("${Core().ApiUrl}Lembur/getLembur");
    var response = await http.post(url, body: {
      "uuid": prefs.getString("ID"),
    });
    print("response");
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
      return const Center(
          child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
      ));
    }
    if (users.isEmpty) {
      return Container(
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Jadwal Lembur Kosong",
              style: TextStyle(
                  color: kPrimaryColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800)),
          const SizedBox(
            height: 32,
          ),
          Image.asset(
            "assets/icons/lembur_tidak.png",
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
          Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (context) => AbsenLemburScreen(
                        idlembur: item['idlembur'],
                      )));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
              child: Text(
                (item['tgl_mulai'] == item['tgl_selesai'])
                    ? "Pelaksanaan : ${formatDate(DateTime.parse(item['tgl_mulai']),
                            [dd, '-', mm, '-', yyyy])}"
                    : "Pelaksanaan : ${formatDate(DateTime.parse(item['tgl_mulai']),
                            [dd, '-', mm, '-', yyyy])} s/d ${formatDate(DateTime.parse(item['tgl_selesai']),
                            [dd, '-', mm, '-', yyyy])}",
                style: const TextStyle(
                    color: kDarkPrimaryColor, fontWeight: FontWeight.w600),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(item['keterangan_lembur'],
                      style: const TextStyle(
                          color: kPrimaryColor,
                          fontSize: 16,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(
                    height: 4,
                  ),
                  Row(
                    children: <Widget>[
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Unit ", style: TextStyle(fontSize: 12)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(": " + item['nama_unit'],
                              style: const TextStyle(fontSize: 12)),
                        ],
                      )
                    ],
                  )
                ],
              ),
            ),
            const SizedBox(height: 16)
          ],
        ),
      ),
    );
  }

  Future<void> _showDialogLembur(String IdLembur) async {
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
                          builder: (context) => AbsenLemburScreen(
                                idlembur: IdLembur,
                              )));
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

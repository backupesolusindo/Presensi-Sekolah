import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/dashboard_screen.dart';
import 'package:mobile_presensi_kdtg/constants.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geolocator/geolocator.dart';

class AktifGPS extends StatefulWidget {
  const AktifGPS({super.key});

  @override
  _AktifGPSState createState() => _AktifGPSState();
}

class _AktifGPSState extends State<AktifGPS> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      color: Colors.white,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            top: 0,
            left: 0,
            child: Image.asset(
              "assets/images/blob_left.png",
              width: size.width * 0.35,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Image.asset(
              "assets/images/blob_right.png",
              width: size.width * 0.35,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "GUNAKAN LOKASI ANDA",
                style: TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.none),
              ),
              const SizedBox(
                height: 20,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  "Aplikasi ini mengumpulkan data lokasi untuk mengaktifkan Presensi Masuk, Presensi Pulang, Istirahat Keluar, Istirahat Masuk, Mulai WFH, Selesai WFH, Presensi Kegiatan, & Presensi Diluar Jam Kerja.",
                  style: TextStyle(
                      color: Colors.black,
                      height: 1.5,
                      fontWeight: FontWeight.normal,
                      fontSize: 11,
                      letterSpacing: 0.7,
                      decoration: TextDecoration.none),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(
                height: 60,
              ),
              Image.asset(
                "assets/ilustrasi/laporankegiatan.png",
                width: size.width * 0.7,
              ),
              const SizedBox(
                height: 60,
              )
            ],
          ),
          Positioned(
              right: 16,
              bottom: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: TextButton(
                  onPressed: () async {
                    bool status = await Geolocator.isLocationServiceEnabled();
                    if (status) {
                      Navigator.pushReplacement(context,
                          MaterialPageRoute(builder: (context) {
                        return const DashboardScreen();
                      }));
                    } else {
                      _showMyDialog();
                    }
                  },
                  child: const Text(
                    "Turn On",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              )),
          Positioned(
              left: 16,
              bottom: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: TextButton(
                  onPressed: () {
                    exit(0);
                  },
                  child: const Text(
                    "Keluar",
                    style: TextStyle(color: Colors.black54),
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _showMyDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AlertDialog(
            title: const Text("GUNAKAN LOKASI ANDA"),
            content: const SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                      "Aplikasi ini mengumpulkan data lokasi saat aplikasi ditutup atau tidak digunakan."),
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
                  Geolocator.checkPermission().then((value) {
                    if (value == LocationPermission.denied ||
                        value == LocationPermission.deniedForever) {
                      Geolocator.requestPermission();
                      Navigator.of(context).pop();
                    } else {
                      Navigator.of(context).pop();
                    }
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

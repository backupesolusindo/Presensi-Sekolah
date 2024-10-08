import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/Login/login_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Welcome/components/background.dart';
import 'package:mobile_presensi_kdtg/components/rounded_button.dart';
import 'package:mobile_presensi_kdtg/constants.dart';
import 'package:flutter_svg/svg.dart';

class Body extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    // This size provide us total height and width of our screen
    return Background(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              "PRESENSI ONLINE",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            Text(
              "Klinik Dokterku Taman Gading",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: size.height * 0.05),
            Container(
              child: Image.asset(
                "assets/images/splash_screen.png",
                width: size.width * 0.6, //ukuran gambar
              ),
            ),
            //     Positioned(
            //       bottom: 100,
            //       left: 100,
            //       child: Image.asset(
            //         "assets/images/splash_screen.png",
            //         width: size.width * 0.6, //ukuran gambar
            //       ),
            //     ),
            SizedBox(height: size.height * 0.05),
          ],
        ),
      ),
    );
  }
}

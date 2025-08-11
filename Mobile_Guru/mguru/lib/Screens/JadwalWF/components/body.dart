import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/JadwalWF/components/background.dart';
import 'package:mobile_presensi_kdtg/Screens/Login/post_login.dart';
import 'package:mobile_presensi_kdtg/components/rounded_button.dart';
import 'package:mobile_presensi_kdtg/components/rounded_date_field.dart';

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  _Body createState() => _Body();
}

class _Body extends State<Body> {
  PostLogin postLogin = PostLogin();
  final txtKeterangan = TextEditingController();
  final txtTanggalMulai = TextEditingController();
  final txtTanggalAkhir = TextEditingController();
  String namaFile = "Tidak ada File Terpilih";

  late String _mySelection;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Background(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RoundedDateField(
              hintText: "Tanggal",
              IdCon: txtTanggalMulai,
            ),
            DropdownButton(
              items: <String>['WFO', 'WFH']
                  .map<DropdownMenuItem<String>>((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value),
                );
              }).toList(),
              onChanged: (newVal) {
                setState(() {
                  _mySelection = newVal as String;
                });
              },
              value: _mySelection,
            ),
            RoundedButton(
              text: "Submit Jadwal",
              press: () {},
            ),
            SizedBox(height: size.height * 0.03),
          ],
        ),
      ),
    );
  }
}

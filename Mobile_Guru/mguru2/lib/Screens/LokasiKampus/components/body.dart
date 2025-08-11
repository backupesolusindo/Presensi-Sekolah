import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/absen_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/LokasiKampus/components/background.dart';
import 'package:mobile_presensi_kdtg/Screens/Login/post_login.dart';
import 'package:mobile_presensi_kdtg/Screens/LokasiKampus/lokasi_kampus_post.dart';
import 'package:mobile_presensi_kdtg/Screens/dashboard_screen.dart';
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

  fetchUser() async {
    setState(() {
      isLoading = true;
    });
    var response = await http.get(Uri.parse("${Core().ApiUrl}Kampus/get_list"));
    print(response.body);
    if (response.statusCode == 200) {
      var items = json.decode(response.body);
      if (items['message']['status'] == 200) {
        items = items['data'];
        setState(() {
          users = items;
          isLoading = false;
        });
      } else {
        Fluttertoast.showToast(
          msg: items['message']['message'],
          toastLength: Toast.LENGTH_SHORT, // Duration of the toast
          gravity: ToastGravity.BOTTOM, // Position of the toast
          timeInSecForIosWeb: 1, // Duration for iOS web
          backgroundColor: Colors.blue.shade500, // Background color
          textColor: Colors.white, // Text color
          fontSize: 16.0, // Font size
        );
      }
    } else {
      users = [];
      isLoading = false;
    }
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Background(
      child: getBody(),
    );
  }

  Widget getBody() {
    if (users.contains(null) || users.length < 0 || isLoading) {
      return const Center(
          child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(kPrimaryColor),
      ));
    }
    return ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          return getCard(users[index]);
        });
  }

  Widget getCard(item) {
    String NamaKampus = item['nama_kampus'];
    String idKampus = item['idkampus'];
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListTile(
          title: Row(
            children: <Widget>[
              Image.asset(
                "assets/images/all_menu.png",
                height: 60,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextButton(
                    onPressed: () async {
                      SharedPreferences prefs =
                          await SharedPreferences.getInstance();
                      prefs.setString("Lokasi", NamaKampus);
                      prefs.setString("idKampus", idKampus);
                      prefs.setDouble(
                          "LokasiLat", double.parse(item['latitude']));
                      prefs.setDouble(
                          "LokasiLng", double.parse(item['longtitude']));
                      prefs.setDouble("Radius", double.parse(item['radius']));
                      LokasiKampusPost.connectToApi(idKampus).then((value) {});
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return const DashboardScreen();
                      }));
                    },
                    child: SizedBox(
                        width: MediaQuery.of(context).size.width - 200,
                        child: Text(
                          NamaKampus,
                          style: const TextStyle(fontSize: 18),
                        )),
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

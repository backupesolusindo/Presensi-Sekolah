import 'dart:io';
import 'dart:ui';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/Profil/upload_post.dart';
import 'package:mobile_presensi_kdtg/Screens/dashboard_screen.dart';
import 'package:mobile_presensi_kdtg/components/rounded_button_small.dart';
import 'package:mobile_presensi_kdtg/constants.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class Foto_Profil extends StatefulWidget {
  @override
  _Foto_ProfilState createState() => _Foto_ProfilState();
}

class _Foto_ProfilState extends State<Foto_Profil> {
  late File _image;
  final picker = ImagePicker();
  late String UUID;
  String NamaPegawai = "Nama Wali";
  String NIP = "-";
  String Foto = "desain/logo.png";
  String Email = "", Unit = "";
  var DataPegawai;

  @override
  void initState() {
    // TODO: implement initState
    // WidgetsBinding.instance.addPostFrameCallback(getPref());
    super.initState();
    getDataDash();
  }

  Future<String> getDataDash() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    UUID = prefs.getString("ID")!;
    var res = await http.get(Uri.parse(Core().ApiUrl + "Dash/get_dash/" + UUID),
        headers: {"Accept": "application/json"});
    var resBody = json.decode(res.body);
    setState(() {
      DataPegawai = resBody['data']["pegawai"];
      NamaPegawai = DataPegawai["nama_pegawai"];
      NIP = DataPegawai["NIP"];
      Email = DataPegawai["email"];
      Unit = DataPegawai["unit"];
      Foto = DataPegawai["foto_profil"];
    });
    print(resBody);
    return "";
  }

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
          Column(children: [
            SizedBox(
              height: size.height * 0.15,
            ),
            Text(
                "Upload Foto Profil Anda yang Baru, Dengan cara klik foto profil Anda, Pilih Foto dan Upload",
                style: TextStyle(
                  fontSize: 18.0,
                  color: kDarkPrimaryColor,
                  fontWeight: FontWeight.bold,
                )),
            SizedBox(
              height: 16,
            ),
            (_image == null)
                ? TextButton(
                    onPressed: () {
                      _show();
                    },
                    child: Padding(
                        padding:
                            EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
                        child: Image.network(Core().Url + Foto,
                            width: size.width * 0.8, height: size.width * 0.8)))
                : TextButton(
                    onPressed: () {
                      _show();
                    },
                    child: Padding(
                        padding:
                            EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
                        child: Image.file(_image,
                            width: size.width * 0.8,
                            height: size.width * 0.8))),
            Padding(
                padding: EdgeInsets.only(left: 4.0, right: 4.0, top: 8.0),
                child: RoundedButtonSmall(
                    text: "UPLOAD FOTO",
                    color: kPrimaryColor,
                    press: () async {
                      if (_image == null) {
                        _showMyDialog("Upload Foto Profil",
                            "Pilih Foto terlebih dahulu dengan cara klik foto profil Anda");
                      } else {
                        SharedPreferences prefs =
                            await SharedPreferences.getInstance();
                        UploadPost.connectToApi(prefs.getString("ID")!, _image)
                            .then((value) {
                          if (value!.status_kode == 200) {
                            Navigator.pushReplacement(context,
                                MaterialPageRoute(builder: (context) {
                              return DashboardScreen();
                            }));
                          } else {
                            _showMyDialog("Upload Foto Profil", value.message);
                          }
                        });
                      }
                    })),
            Padding(
                padding: EdgeInsets.only(left: 4.0, right: 4.0, top: 32.0),
                child: RoundedButtonSmall(
                    text: "Kembali",
                    color: ColorLight,
                    press: () async {
                      Navigator.of(context).pop();
                    }))
          ]),
        ],
      ),
    );
  }

  Future getImage() async {
    final pickedFile = await picker.getImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxHeight: 380,
        maxWidth: 540);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  Future getFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.first;
      setState(() {
        _image = File(file.path!);
      });
      print(file.name);
      print(file.bytes);
      print(file.size);
      print(file.extension);
      print(file.path);
    } else {
      print('No image selected.');
    }
  }

  Future<void> _show() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AlertDialog(
            title: Text("UPLOAD IMAGE"),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text("Pilih File Dari Sumber?"),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('CAMERA'),
                onPressed: () async {
                  getImage();
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('GALLERY'),
                onPressed: () async {
                  getFile();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showMyDialog(String Title, String Keterangan) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AlertDialog(
            title: Text(Title),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(Keterangan),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Keluar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

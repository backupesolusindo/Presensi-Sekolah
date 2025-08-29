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
import 'package:geolocator/geolocator.dart'; // Ensure you have this import
import 'package:mobile_presensi_kdtg/Screens/AktifGPS/aktifgps_screen.dart'; // Adjust the import path as necessary


class Foto_Profil extends StatefulWidget {
  const Foto_Profil({super.key});

  @override
  _Foto_ProfilState createState() => _Foto_ProfilState();
}

class _Foto_ProfilState extends State<Foto_Profil> {
  File? _image; // Make _image nullable
  final picker = ImagePicker();
  late String UUID;
  String Nama = "";
  String NIP = "";
  String Foto = "desain/user.png";
  String Email = "", Unit = "";
  var DataPegawai;

  @override
  void initState() {
    super.initState();
    fetchData(); // Call fetchData instead of getDataDash directly
  }

  Future<void> fetchData() async {
    var prefsData = await getPref();
    UUID = prefsData['UUID'] ?? '';
    NIP = prefsData['NIP'] ?? '-';
    Nama = prefsData['Nama'] ?? '';
    await getDataDash(); // Call getDataDash after fetching preferences
  }

  Future<Map<String, String?>> getPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? UUID = prefs.getString("ID");
    String? NIP = prefs.getString("NIP");
    String? Nama = prefs.getString("Nama");

    if (prefs.getInt("CameraSelect") == null) {
      prefs.setInt("CameraSelect", 1);
    }

    bool status = await Geolocator.isLocationServiceEnabled();
    if (!status) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) {
        return const AktifGPS();
      }));
    }

    return {
      'UUID': UUID,
      'NIP': NIP,
      'Nama': Nama,
    };
  }

  Future<void> getDataDash() async {
    try {
      var res = await http.get(
        Uri.parse("${Core().ApiUrl}Dash/get_dash/$UUID"),
        headers: {"Accept": "application/json"},
      );

      if (res.statusCode == 200) {
        var resBody = json.decode(res.body);
        setState(() {
          DataPegawai = resBody['data']["pegawai"];
          // You can assign other fields from DataPegawai if needed
          Email = DataPegawai["email"];
          Unit = DataPegawai["unit"];
        //   Foto = DataPegawai["foto_profil"] ?? Foto; // Default to existing Foto
        // });
        // Validasi dan cleaning untuk foto_profil
          String? fotoFromAPI = DataPegawai["foto_profil"];
          if (fotoFromAPI != null && fotoFromAPI.isNotEmpty) {
            // Jika foto dari API mengandung path yang salah, perbaiki
            if (fotoFromAPI.contains("Login/logo.png")) {
              Foto = "desain/user.png"; // Gunakan default
            } else {
              Foto = fotoFromAPI;
            }
          } else {
            Foto = "desain/user.png"; // Default jika kosong
          }
        });
      } else {
        print("Error fetching data: ${res.statusCode}");
      }
    } catch (e) {
      print("Exception occurred: $e");
    }
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
            const Text(
                "Upload Foto Profil Anda yang Baru, Dengan cara klik foto profil Anda, Pilih Foto dan Upload",
                style: TextStyle(
                  fontSize: 18.0,
                  color: kDarkPrimaryColor,
                  fontWeight: FontWeight.bold,
                )),
            const SizedBox(height: 16),
            TextButton(
              onPressed: _show,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: _image == null
                    ? Image.network(
                        Core().Url + Foto,
                        width: size.width * 0.8,
                        height: size.width * 0.8,
                      )
                    : Image.file(
                        _image!,
                        width: size.width * 0.8,
                        height: size.width * 0.8,
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 8.0),
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
                    UploadPost.connectToApi(prefs.getString("ID")!, _image!)
                        .then((value) {
                      if (value!.status_kode == 200) {
                        Navigator.pushReplacement(context,
                            MaterialPageRoute(builder: (context) {
                          return const DashboardScreen();
                        }));
                      } else {
                        _showMyDialog("Upload Foto Profil", value.message);
                      }
                    });
                  }
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 32.0),
              child: RoundedButtonSmall(
                text: "Kembali",
                color: ColorLight,
                press: () {
                  Navigator.of(context).pop();
                },
              ),
            )
          ]),
        ],
      ),
    );
  }

  Future<void> getImage() async {
    final pickedFile = await picker.pickImage(
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

  Future<void> getFile() async {
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
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AlertDialog(
            title: const Text("UPLOAD IMAGE"),
            content: const SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text("Pilih File Dari Sumber?"),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('CAMERA'),
                onPressed: () async {
                  await getImage();
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('GALLERY'),
                onPressed: () async {
                  await getFile();
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showMyDialog(String title, String description) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(description),
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
            ],
          ),
        );
      },
    );
  }
}

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/Laporan/Perizinan/Laporan_Perizinan_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Perizinan/components/background.dart';
import 'package:mobile_presensi_kdtg/Screens/Login/post_login.dart';
import 'package:mobile_presensi_kdtg/Screens/Perizinan/izin_post.dart';
import 'package:mobile_presensi_kdtg/components/rounded_button.dart';
import 'package:mobile_presensi_kdtg/components/rounded_date_field.dart';
import 'package:mobile_presensi_kdtg/components/rounded_input_field.dart';
import 'package:file_picker/file_picker.dart';
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
  PostLogin postLogin = PostLogin();
  final txtKeterangan = TextEditingController();
  final txtTanggalMulai = TextEditingController();
  final txtTanggalAkhir = TextEditingController();
  String namaFile = "Tidak ada File Terpilih";

  String? _mySelection;
  String? valueChoose;

  File? _file;

  var url = Uri.parse("${Core().ApiUrl}Izin/get_jenis");
  List data = []; //edited line
  Future<String> getJenisData() async {
    print("getJenis");
    var res = await http.get(url, headers: {"Accept": "application/json"});
    var resBody = json.decode(res.body);
    setState(() {
      data = resBody['response'];
    });
    print(resBody);
    return "";
  }

  Future getFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles();

    if (result != null) {
      PlatformFile file = result.files.first;
      setState(() {
        namaFile = file.name.toString();
        _file = File(file.path!);
      });
      print(file.name);
      print(file.bytes);
      print(file.size);
      print(file.extension);
      print(file.path);
    } else {
      // User canceled the picker
      namaFile = "Belum Memilih File";
    }
  }

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getJenisData();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Background(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RoundedInputField(
              hintText: "Keterangan Cuti",
              IdCon: txtKeterangan,
              icon: Icons.text_fields,
              onChanged: (String value) {},
            ),
            RoundedDateField(
              hintText: "Tanggal Mulai Cuti",
              IdCon: txtTanggalMulai,
            ),
            RoundedDateField(
              hintText: "Tanggal Akhir Cuti",
              IdCon: txtTanggalAkhir,
            ),

            //dropdown
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 36, vertical: 8),
              padding: const EdgeInsets.only(left: 18, right: 18),
              decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey, width: 1),
                  borderRadius: BorderRadius.circular(45)),
              child: DropdownButton(
                hint: const Text("Pilih Jenis Cuti : "),
                dropdownColor: Colors.white,
                icon: const Icon(Icons.arrow_drop_down),
                iconSize: 24,
                isExpanded: true,
                underline: const SizedBox(),
                style: const TextStyle(color: Colors.black, fontSize: 16),
                items: data.map((item) {
                  return DropdownMenuItem(
                    value: item['idjenis_perizinan'].toString(),
                    child: Text(item['jenis_izin']),
                  );
                }).toList(),
                onChanged: (newVal) {
                  setState(() {
                    _mySelection = newVal as String;
                  });
                },
                value: _mySelection,
              ),
            ),
            const SizedBox(height: 24),
            Text(namaFile),
            ElevatedButton(onPressed: getFile, child: const Text("Upload File")),
            const SizedBox(
              height: 24,
            ),
            RoundedButton(
              text: "KIRIM",
              press: () async {
                SharedPreferences prefs = await SharedPreferences.getInstance();
                IzinPost.connectToApi(
                        prefs.getString("ID")!,
                        txtTanggalAkhir.text,
                        txtTanggalMulai.text,
                        txtKeterangan.text,
                        _mySelection!,
                        _file!)
                    .then((value) {
                  if (value!.status_kode == 200) {
                    Navigator.of(context).pop();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) {
                          return const LaporanCutiScreen();
                        },
                      ),
                    );
                  }
                });
              },
            ),
            SizedBox(height: size.height * 0.03),
          ],
        ),
      ),
    );
  }
}

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'package:async/async.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AbsenPost {
  int status_kode;
  String message;

  AbsenPost({this.status_kode = 0, this.message = ""});

  factory AbsenPost.createPostAbsen(Map<String, dynamic> object) {
    return AbsenPost(
        status_kode: object['message']['status'],
        message: object['message']['message']);
  }

  static Future<AbsenPost?> connectToApi(
      String id,
      String lat,
      String long,
      String jenis_absen,
      String jenis_tempat,
      String idJadwal,
      String JamMasuk,
      File imageFile) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var stream =
        new http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    var length = await imageFile.length();
    var url = Uri.parse(Core().ApiUrl + "Absen/insert_absen");

    var request = new http.MultipartRequest("POST", url);
    var multipartFile = new http.MultipartFile("image", stream, length,
        filename: basename(imageFile.path));
    request.fields['id'] = id;
    request.fields['lat'] = lat;
    request.fields['long'] = long;
    request.fields['idjadwal'] = idJadwal;
    request.fields['jam_masuk'] = JamMasuk;
    request.fields['jenis_absen'] = jenis_absen;
    request.fields['jenis_tempat'] = jenis_tempat;
    request.fields['idkampus'] = prefs.getString("idKampus")!;
    request.files.add(multipartFile);

    http.Response response =
        await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) {
      print(response.body);
      var jsonObject = json.decode(response.body);
      return AbsenPost.createPostAbsen(jsonObject);
    } else {
      return null;
    }
  }
}

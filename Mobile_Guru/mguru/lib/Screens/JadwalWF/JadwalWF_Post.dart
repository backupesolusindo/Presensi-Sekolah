import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'package:http/http.dart' as http;

class JadwalWFPost {
  int status_kode;
  String message;

  JadwalWFPost({this.status_kode = 0, this.message = ""});

  factory JadwalWFPost.createJadwalWFPost(Map<String, dynamic> object) {
    return JadwalWFPost(
      status_kode: object['message']['status'],
      message: object['message']['message'],
    );
  }

  static Future<JadwalWFPost?> connectToApi(
      String Tanggal, String UUID, String kode_jenis) async {
    var url = Uri.parse(Core().ApiUrl + "JadwalWF/insert_JadwalWF");
    var apiResult = await http.post(url, body: {
      "tanggal": Tanggal,
      "uuid": UUID,
      "kode_jenis": kode_jenis,
    });
    if (apiResult.statusCode == 200) {
      print(apiResult.body);
      var jsonObject = json.decode(apiResult.body);
      return JadwalWFPost.createJadwalWFPost(jsonObject);
    } else {
      return null;
    }
  }
}

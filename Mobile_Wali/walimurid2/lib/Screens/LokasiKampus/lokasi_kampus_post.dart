import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'package:async/async.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LokasiKampusPost {
  int status_kode;
  String message;

  LokasiKampusPost({required this.status_kode, required this.message});

  factory LokasiKampusPost.createPostAbsen(Map<String, dynamic> object) {
    return LokasiKampusPost(
        status_kode: object['message']['status'],
        message: object['message']['message']);
  }

  static Future<LokasiKampusPost?> connectToApi(String idkampus) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var url = Uri.parse(Core().ApiUrl + "Pegawai/set_lokasi");

    var request = new http.MultipartRequest("POST", url);
    request.fields['uuid'] = prefs.getString("ID")!;
    request.fields['idkampus'] = idkampus;

    http.Response response =
        await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) {
      print(response.body);
      var jsonObject = json.decode(response.body);
      return LokasiKampusPost.createPostAbsen(jsonObject);
    } else {
      return null;
    }
  }
}

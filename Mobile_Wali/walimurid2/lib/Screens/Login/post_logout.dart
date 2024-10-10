import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'package:http/http.dart' as http;

class PostLogout {
  int status_kode;
  String message;

  PostLogout({
    required this.status_kode,
    required this.message,
  });

  factory PostLogout.createPostLogout(Map<String, dynamic> object) {
    return PostLogout(
      status_kode: object['message']['status'],
      message: object['message']['message'],
      // status_kode: 200,
      // message: object['data']['first_name'],
      // NIP: object['data']["first_name"],
      // Pegawai: object['data']["first_name"],
      // UUID: object['data']["first_name"],
    );
  }

  static Future<PostLogout?> connectToApi(String uuid) async {
    var url = Uri.parse(Core().ApiUrl + "Login/aksi_logout");
    var apiResult = await http.post(url, body: {
      "uuid": uuid,
    });
    // var url = Uri.parse("https://reqres.in/api/users/2");
    // var apiResult = await http.get(url);
    print(apiResult.body);
    if (apiResult.statusCode == 200) {
      var jsonObject = json.decode(apiResult.body);
      return PostLogout.createPostLogout(jsonObject);
    } else {
      return null;
    }
  }
}

import 'dart:convert';

import 'package:mobile_presensi_kdtg/core.dart';
import 'package:http/http.dart' as http;

class PostReset {
  int status_kode;
  String message;

  PostReset({required this.status_kode, required this.message});

  factory PostReset.createPostLogin(Map<String, dynamic> object) {
    return PostReset(
      status_kode: object['message']['status'],
      message: object['message']['message'],
      // status_kode: 200,
      // message: object['data']['first_name'],
      // NIP: object['data']["first_name"],
      // Pegawai: object['data']["first_name"],
      // UUID: object['data']["first_name"],
    );
  }

  static Future<PostReset?> connectToApi(String UUID, String password) async {
    var url = Uri.parse("${Core().ApiUrl}Login/resetPassword");
    var apiResult = await http.post(url, body: {
      "UUID": UUID,
      "password": password,
    });
    if (apiResult.statusCode == 200) {
      print(apiResult.body);
      var jsonObject = json.decode(apiResult.body);
      return PostReset.createPostLogin(jsonObject);
    } else {
      return null;
    }
  }
}

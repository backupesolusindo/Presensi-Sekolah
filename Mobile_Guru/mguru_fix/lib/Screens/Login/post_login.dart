import 'dart:convert';

import 'package:mobile_presensi_kdtg/core.dart';
import 'package:http/http.dart' as http;

class PostLogin {
  int status_kode;
  String status_spesial;
  String message;
  String Pegawai;
  String NIP;
  String UUID;
  String IDKampus, NamaKampus;
  String LokasiLat, LokasiLng, Radius;

  PostLogin(
      {this.status_kode = 0,
      this.message = "",
      this.NIP = "",
      this.Pegawai = "",
      this.UUID = "",
      this.status_spesial = "",
      this.LokasiLat = "",
      this.LokasiLng = "",
      this.Radius = "",
      this.IDKampus = "",
      this.NamaKampus = ""});

  factory PostLogin.createPostLogin(Map<String, dynamic> object) {
    return PostLogin(
      status_kode: object['message']['status'],
      message: object['message']['message'],
      IDKampus: object['message']['kampus']['idkampus'],
      NamaKampus: object['message']['kampus']['nama_kampus'],
      LokasiLat: object['message']['kampus']['latitude'],
      LokasiLng: object['message']['kampus']['longtitude'],
      Radius: object['message']['kampus']['radius'],
      NIP: object['response']["nip"],
      Pegawai: object['response']["nama"],
      UUID: object['response']["uuid"],
      status_spesial: object['response']["spesial"].toString(),
      // status_kode: 200,
      // message: object['data']['first_name'],
      // NIP: object['data']["first_name"],
      // Pegawai: object['data']["first_name"],
      // UUID: object['data']["first_name"],
    );
  }

  static Future<PostLogin?> connectToApi(
      String username, String password, String token) async {
    var url = Uri.parse("${Core().ApiUrl}Login/aksi_login");
    var apiResult = await http.post(url, body: {
      "nip": username,
      "password": password,
      "token": token,
    });
    // var url = Uri.parse("https://reqres.in/api/users/2");
    // var apiResult = await http.get(url);
    print(apiResult.body);
    if (apiResult.statusCode == 200) {
      var jsonObject = json.decode(apiResult.body);
      return PostLogin.createPostLogin(jsonObject);
    } else {
      return null;
    }
  }
}

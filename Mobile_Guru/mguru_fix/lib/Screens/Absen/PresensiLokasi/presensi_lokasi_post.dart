import 'dart:convert';
import 'dart:io';

import 'package:mobile_presensi_kdtg/core.dart';
import 'package:async/async.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

class PresensiLokasiPost {
  int status_kode;
  String message;
  // String Pegawai, NIP;

  PresensiLokasiPost({this.status_kode = 0, this.message = ""});

  factory PresensiLokasiPost.createPostPresensiLokasi(
      Map<String, dynamic> object) {
    return PresensiLokasiPost(
        status_kode: object['message']['status'],
        message: object['message']['message']);
  }

  static Future<PresensiLokasiPost?> connectToApi(
      String id, String lat, String long, File imageFile) async {
    var stream =
        http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    var length = await imageFile.length();
    var url = Uri.parse("${Core().ApiUrl}Absen/insert_absen_lokasi");

    var request = http.MultipartRequest("POST", url);
    var multipartFile = http.MultipartFile("image", stream, length,
        filename: basename(imageFile.path));
    request.fields['id'] = id;
    request.fields['lat'] = lat;
    request.fields['long'] = long;
    request.files.add(multipartFile);

    http.Response response =
        await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) {
      print(response.body);
      var jsonObject = json.decode(response.body);
      return PresensiLokasiPost.createPostPresensiLokasi(jsonObject);
    } else {
      return null;
    }
  }
}

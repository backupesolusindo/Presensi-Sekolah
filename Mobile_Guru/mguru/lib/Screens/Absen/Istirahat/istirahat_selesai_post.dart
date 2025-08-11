import 'dart:convert';
import 'dart:io';

import 'package:mobile_presensi_kdtg/core.dart';
import 'package:async/async.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

class AbsenSelesaiIstirahatPost {
  int status_kode;
  String message;
  // String Pegawai, NIP;

  // ignore: non_constant_identifier_names
  AbsenSelesaiIstirahatPost({this.status_kode = 0, this.message = ""});

  factory AbsenSelesaiIstirahatPost.createPostAbsen(
      Map<String, dynamic> object) {
    return AbsenSelesaiIstirahatPost(
        status_kode: object['message']['status'],
        message: object['message']['message']);
  }

  static Future<AbsenSelesaiIstirahatPost?> connectToApi(String id,
      String idabsen, String lat, String long, File imageFile) async {
    var stream =
        http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    var length = await imageFile.length();
    var url = Uri.parse("${Core().ApiUrl}Absen/insert_istirahat_selesai");

    var request = http.MultipartRequest("POST", url);
    var multipartFile = http.MultipartFile("image", stream, length,
        filename: basename(imageFile.path));
    request.fields['id'] = id;
    request.fields['idabsensi'] = idabsen;
    request.fields['lat'] = lat;
    request.fields['long'] = long;
    request.files.add(multipartFile);

    http.Response response =
        await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) {
      print(response.body);
      var jsonObject = json.decode(response.body);
      return AbsenSelesaiIstirahatPost.createPostAbsen(jsonObject);
    } else {
      return null;
    }
  }
}

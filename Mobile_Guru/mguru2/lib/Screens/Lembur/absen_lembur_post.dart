import 'dart:convert';
import 'dart:io';

import 'package:mobile_presensi_kdtg/core.dart';
import 'package:async/async.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

class AbsenLemburPost {
  int status_kode;
  String message;

  AbsenLemburPost({required this.status_kode, required this.message});

  factory AbsenLemburPost.createPostAbsen(Map<String, dynamic> object) {
    return AbsenLemburPost(
        status_kode: object['message']['status'],
        message: object['message']['message']);
  }

  static Future<AbsenLemburPost?> connectToApi(String id, String idlembur,
      String lat, String long, String lokasi, File imageFile) async {
    var stream =
        http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    var length = await imageFile.length();
    var url = Uri.parse("${Core().ApiUrl}Lembur/absen_lembur");

    var request = http.MultipartRequest("POST", url);
    var multipartFile = http.MultipartFile("image", stream, length,
        filename: basename(imageFile.path));
    request.fields['id'] = id;
    request.fields['idlembur'] = idlembur;
    request.fields['lat'] = lat;
    request.fields['long'] = long;
    request.fields['status_lokasi'] = lokasi;
    request.files.add(multipartFile);

    http.Response response =
        await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) {
      print(response.body);
      var jsonObject = json.decode(response.body);
      return AbsenLemburPost.createPostAbsen(jsonObject);
    } else {
      return null;
    }
  }
}

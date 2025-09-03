import 'dart:convert';
import 'dart:io';

import 'package:mobile_presensi_kdtg/core.dart';
import 'package:async/async.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AbsenSelesaiPost {
  int status_kode;
  String message;

  AbsenSelesaiPost({this.status_kode = 0, this.message = ""});

  factory AbsenSelesaiPost.createPostAbsen(Map<String, dynamic> object) {
    return AbsenSelesaiPost(
        status_kode: object['message']['status'],
        message: object['message']['message']);
  }

  // Original method with photo upload (kept for compatibility)
  static Future<AbsenSelesaiPost?> connectToApi(String id, String idabsen,
      String lat, String long, File imageFile) async {
    var stream =
        http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    var length = await imageFile.length();
    var url = Uri.parse("${Core().ApiUrl}Absen/insert_absen_selesai");

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
      return AbsenSelesaiPost.createPostAbsen(jsonObject);
    } else {
      return null;
    }
  }

  // New method for attendance checkout without photo
  static Future<AbsenSelesaiPost?> connectToApiNoPhoto(
      String id, String idabsen, String lat, String long) async {
    
    var url = Uri.parse("${Core().ApiUrl}Absen/insert_absen_selesai");

    try {
      // Send as form data to match PHP expectations
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'id': id,
          'idabsensi': idabsen,
          'lat': lat,
          'long': long,
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        var jsonObject = json.decode(response.body);
        return AbsenSelesaiPost.createPostAbsen(jsonObject);
      } else {
        print('Error: ${response.statusCode}');
        print('Error Body: ${response.body}');
        return AbsenSelesaiPost(status_kode: 0, message: "Gagal melakukan absensi pulang (${response.statusCode})");
      }
    } catch (e) {
      print('Exception: $e');
      return AbsenSelesaiPost(status_kode: 0, message: "Terjadi kesalahan koneksi: $e");
    }
  }
}
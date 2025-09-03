import 'dart:convert';
import 'dart:io';

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

  // Original method with photo upload (kept for compatibility)
  static Future<AbsenPost?> connectToApi(
      String id,
      String lat,
      String long,
      String jenisAbsen,
      String jenisTempat,
      String idJadwal,
      String JamMasuk,
      File imageFile) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    var stream =
        http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    var length = await imageFile.length();
    var url = Uri.parse("${Core().ApiUrl}Absen/insert_absen");

    var request = http.MultipartRequest("POST", url);
    var multipartFile = http.MultipartFile("image", stream, length,
        filename: basename(imageFile.path));
    request.fields['id'] = id;
    request.fields['lat'] = lat;
    request.fields['long'] = long;
    request.fields['idjadwal'] = idJadwal;
    request.fields['jam_masuk'] = JamMasuk;
    request.fields['jenis_absen'] = jenisAbsen;
    request.fields['jenis_tempat'] = jenisTempat;
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

  // Fixed method for attendance without photo - using same endpoint as PHP
  static Future<AbsenPost?> connectToApiNoPhoto(
      String id,
      String lat,
      String long,
      String jenisAbsen,
      String jenisTempat,
      String idJadwal,
      String JamMasuk) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Use the same endpoint as the original method
    var url = Uri.parse("${Core().ApiUrl}Absen/insert_absen");

    try {
      // Send as form data, not JSON, to match PHP expectations
      var response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
        },
        body: {
          'id': id,
          'lat': lat,
          'long': long,
          'idjadwal': idJadwal,
          'jam_masuk': JamMasuk,
          'jenis_absen': jenisAbsen,
          'jenis_tempat': jenisTempat,
          'idkampus': prefs.getString("idKampus") ?? '',
        },
      );

      print('Response Status: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        var jsonObject = json.decode(response.body);
        return AbsenPost.createPostAbsen(jsonObject);
      } else {
        print('Error: ${response.statusCode}');
        print('Error Body: ${response.body}');
        return AbsenPost(status_kode: 0, message: "Gagal melakukan absensi (${response.statusCode})");
      }
    } catch (e) {
      print('Exception: $e');
      return AbsenPost(status_kode: 0, message: "Terjadi kesalahan koneksi: $e");
    }
  }
}
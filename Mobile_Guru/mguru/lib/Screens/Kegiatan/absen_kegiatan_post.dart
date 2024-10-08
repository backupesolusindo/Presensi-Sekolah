import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'package:async/async.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

class AbsenKegiatanPost {
  int status_kode;
  String message;

  AbsenKegiatanPost({this.status_kode = 0, this.message = ""});

  factory AbsenKegiatanPost.createPostAbsen(Map<String, dynamic> object) {
    return AbsenKegiatanPost(
        status_kode: object['message']['status'],
        message: object['message']['message']);
  }

  static Future<AbsenKegiatanPost?> connectToApi(String id, String idkegiatan,
      String lat, String long, String lokasi, File imageFile) async {
    var stream =
        new http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    var length = await imageFile.length();
    var url = Uri.parse(Core().ApiUrl + "Kegiatan/absen_kegiatan");

    var request = new http.MultipartRequest("POST", url);
    var multipartFile = new http.MultipartFile("image", stream, length,
        filename: basename(imageFile.path));
    request.fields['id'] = id;
    request.fields['idkegiatan'] = idkegiatan;
    request.fields['lat'] = lat;
    request.fields['long'] = long;
    request.fields['status_lokasi'] = lokasi;
    request.files.add(multipartFile);

    http.Response response =
        await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) {
      print(response.body);
      var jsonObject = json.decode(response.body);
      return AbsenKegiatanPost.createPostAbsen(jsonObject);
    } else {
      return null;
    }
  }
}

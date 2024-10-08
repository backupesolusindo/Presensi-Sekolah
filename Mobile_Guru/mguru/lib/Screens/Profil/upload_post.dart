import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'package:async/async.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

class UploadPost {
  int status_kode;
  String message;

  UploadPost({required this.status_kode, required this.message});

  factory UploadPost.createPostAbsen(Map<String, dynamic> object) {
    return UploadPost(
        status_kode: object['message']['status'],
        message: object['message']['message']);
  }

  static Future<UploadPost?> connectToApi(String uuid, File imageFile) async {
    var stream =
        new http.ByteStream(DelegatingStream.typed(imageFile.openRead()));
    var length = await imageFile.length();
    var url = Uri.parse(Core().ApiUrl + "Pegawai/update_profil");

    var request = new http.MultipartRequest("POST", url);
    var multipartFile = new http.MultipartFile("image", stream, length,
        filename: basename(imageFile.path));
    request.fields['uuid'] = uuid;
    request.files.add(multipartFile);

    http.Response response =
        await http.Response.fromStream(await request.send());
    if (response.statusCode == 200) {
      print(response.body);
      var jsonObject = json.decode(response.body);
      return UploadPost.createPostAbsen(jsonObject);
    } else {
      return null;
    }
  }
}

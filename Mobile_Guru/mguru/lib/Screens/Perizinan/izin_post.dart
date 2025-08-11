import 'dart:convert';
import 'dart:io';

import 'package:mobile_presensi_kdtg/core.dart';
import 'package:async/async.dart';
import 'package:path/path.dart';
import 'package:http/http.dart' as http;

class IzinPost {
  int status_kode;
  String message;

  IzinPost({required this.status_kode, required this.message});

  factory IzinPost.createPostAbsen(Map<String, dynamic> object) {
    return IzinPost(
        status_kode: object['message']['status'],
        message: object['message']['message']);
  }

  static Future<IzinPost?> connectToApi(
      String id,
      String tanggalMulai,
      String tanggalAkhir,
      String alasan,
      String jenisPerizinan,
      File filecuti) async {
    var url = Uri.parse("${Core().ApiUrl}Izin/insert_izin");
    var request = http.MultipartRequest("POST", url);

    var stream =
        http.ByteStream(DelegatingStream.typed(filecuti.openRead()));
    var length = await filecuti.length();
    var multipartFile = http.MultipartFile("image", stream, length,
        filename: basename(filecuti.path));
    request.files.add(multipartFile);
  
    request.fields['id'] = id;
    request.fields['tanggal_mulai'] = tanggalMulai;
    request.fields['tanggal_akhir'] = tanggalAkhir;
    request.fields['alasan'] = alasan;
    request.fields['jenis_perizinan'] = jenisPerizinan;

    http.Response response =
        await http.Response.fromStream(await request.send());
    print("res izin");
    print(response.body);
    if (response.statusCode == 200) {
      var jsonObject = json.decode(response.body);
      return IzinPost.createPostAbsen(jsonObject);
    } else {
      return null;
    }
  }
}

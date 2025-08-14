import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:presensiSiswa/models/rfid_recod.dart';

class RfidService {
  static const String baseUrl =
      "https://presensi-smp1.esolusindo.com/api/apimobile/apipresensi/cek_absen";

  static Future<List<RfidRecord>> getAbsenGerbang({String? date, String? search}) async {
    final uri = Uri.parse(baseUrl).replace(queryParameters: {
      if (date != null) 'date': date,
      if (search != null) 'search': search,
    });

    final res = await http.get(uri);
    if (res.statusCode == 200) {
      final data = json.decode(res.body);
      if (data['error'] == false && data['data'] != null) {
        return (data['data'] as List)
            .map((e) => RfidRecord.fromJson(e))
            .toList();
      } else {
        return [];
      }
    } else {
      throw Exception("Gagal mengambil data: ${res.statusCode}");
    }
  }
}

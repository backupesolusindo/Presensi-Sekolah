import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:presensiSiswa/models/rfid_recod.dart';

class RfidService {
  // Ganti URL sesuai dengan apakah htaccess aktif atau tidak
  // Kalau htaccess aktif:
  static const String baseUrl = "https://presensi-smp1.esolusindo.com/api/apimobile/apipresensi/cek_absen";
  
  // Kalau htaccess TIDAK aktif, pakai ini:
  // static const String baseUrl = "https://presensi-smp1.esolusindo.com/index.php/api/apimobile/apipresensi/cek_absen";

  static Future<List<RfidRecord>> getAbsenGerbang({String? date, String? search}) async {
    // Tambahkan query parameters kalau ada
    final uri = Uri.parse(baseUrl).replace(queryParameters: {
      if (date != null && date.isNotEmpty) 'date': date,
      if (search != null && search.isNotEmpty) 'search': search,
    });

    try {
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
    } catch (e) {
      throw Exception("Terjadi kesalahan koneksi: $e");
    }
  }
}

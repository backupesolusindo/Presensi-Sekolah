import 'dart:convert';
import 'package:mobile_presensi_kdtg/core.dart';
import 'package:http/http.dart' as http;

class PostLogin {
  int status_kode;
  String message;
  String NIP;
  String Pegawai;
  String UUID;
  String status_spesial;
  String IDKampus, NamaKampus;
  String LokasiLat, LokasiLng, Radius;

  PostLogin({
    this.status_kode = 0,
    this.message = "Terjadi kesalahan.", // Set pesan default yang lebih informatif
    this.NIP = "",
    this.Pegawai = "",
    this.UUID = "",
    this.status_spesial = "",
    this.LokasiLat = "",
    this.LokasiLng = "",
    this.Radius = "",
    this.IDKampus = "",
    this.NamaKampus = "",
  });

  // Factory constructor untuk membuat objek dari respons JSON
  factory PostLogin.fromJson(Map<String, dynamic> json) {
    // Tangani respons sukses
    if (json.containsKey('response') && json.containsKey('message') && json['message']['status'] == 200) {
      final message = json['message'] as Map<String, dynamic>;
      final response = json['response'] as Map<String, dynamic>;
      final kampus = message['kampus'] as Map<String, dynamic>;

      return PostLogin(
        status_kode: message['status'] ?? 0,
        message: message['message'] ?? 'Login berhasil.',
        IDKampus: kampus['idkampus']?.toString() ?? '',
        NamaKampus: kampus['nama_kampus'] ?? '',
        LokasiLat: kampus['latitude']?.toString() ?? '',
        LokasiLng: kampus['longtitude']?.toString() ?? '',
        Radius: kampus['radius']?.toString() ?? '',
        NIP: response['nip'] ?? '',
        Pegawai: response['nama'] ?? '',
        UUID: response['uuid'] ?? '',
        status_spesial: response['spesial']?.toString() ?? '',
      );
    } 
    // Tangani respons gagal
    else {
      return PostLogin(
        status_kode: json['status_kode'] ?? 500,
        message: json['message'] ?? 'Login gagal. Silakan coba lagi.',
      );
    }
  }

  static Future<PostLogin> connectToApi(
      String username, String password, String token) async {
    try {
      var url = Uri.parse("${Core().ApiUrl}Login/aksi_login");
      var apiResult = await http.post(url, body: {
        "nip": username,
        "password": password,
        "token": token,
      });

      print("Response Body: ${apiResult.body}");

      var jsonObject = json.decode(apiResult.body);
      
      // Menggunakan factory constructor yang baru untuk memproses JSON
      return PostLogin.fromJson(jsonObject);

    } catch (e) {
      // Tangani kesalahan jaringan atau parsing
      print("Kesalahan saat koneksi ke API: $e");
      return PostLogin(
        status_kode: 500,
        message: 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.',
      );
    }
  }
}
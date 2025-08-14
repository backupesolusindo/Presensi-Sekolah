class RfidRecord {
  final String nama;
  final String kelas;
  final String nis;
  final String tanggal;
  final String? jamMasuk;   // dari 'waktu'
  final String? jamPulang;  // dari 'waktu_pulang'
  final String statusMasuk;
  final String statusPulang;

  RfidRecord({
    required this.nama,
    required this.kelas,
    required this.nis,
    required this.tanggal,
    this.jamMasuk,
    this.jamPulang,
    required this.statusMasuk,
    required this.statusPulang,
  });

  factory RfidRecord.fromJson(Map<String, dynamic> json) {
    return RfidRecord(
      nama: json['nama'] ?? '',
      kelas: json['kelas'] ?? '',
      nis: json['nis'] ?? '',
      tanggal: json['tanggal'] ?? '',
      jamMasuk: json['waktu'], // ambil masuk dari field 'waktu'
      jamPulang: json['waktu_pulang'], // ambil pulang dari field 'waktu_pulang'
      statusMasuk: json['status_masuk'] ?? '',
      statusPulang: json['status_pulang'] ?? '',
    );
  }
}

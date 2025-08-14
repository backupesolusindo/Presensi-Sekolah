class RfidRecord {
  final String nis;
  final String nama;
  final String kelas;
  final String tanggal;
  final String? jamMasuk;
  final String statusMasuk;
  final String? jamPulang;
  final String statusPulang;

  RfidRecord({
    required this.nis,
    required this.nama,
    required this.kelas,
    required this.tanggal,
    this.jamMasuk,
    required this.statusMasuk,
    this.jamPulang,
    required this.statusPulang,
  });

  factory RfidRecord.fromJson(Map<String, dynamic> json) {
    return RfidRecord(
      nis: json['nis'] ?? '',
      nama: json['nama'] ?? '',
      kelas: json['kelas'] ?? '',
      tanggal: json['tanggal'] ?? '',
      jamMasuk: json['jam_masuk'],
      statusMasuk: json['status_masuk'] ?? '',
      jamPulang: json['jam_pulang'],
      statusPulang: json['status_pulang'] ?? '',
    );
  }
}

import 'dart:ui';

class Recognition {
  final String name;
  final Rect location;
  final List<double> embeddings;
  final double distance;
  double confidence;
  final String nis; // Menambahkan NIS
  final String kelas;
  final String noHpOrtu; // Menambahkan No HP Orang Tua (ubah ke final)

  // Konstruktor yang menerima semua properti
  Recognition(this.name, this.location, this.embeddings, this.distance, this.confidence, this.nis, this.kelas, this.noHpOrtu);
}

import 'dart:ui';

class Recognition {
  final String name;
  final Rect location;
  final List<double> embeddings;
  final double distance;
  double confidence;
  final String nis; // Menambahkan NIS
  final String kelas; // Menambahkan Kelas

  Recognition(this.name, this.location, this.embeddings, this.distance, this.confidence, this.nis, this.kelas);

}

class Student {
  final String name;
  final String dob; // Tambahkan field sesuai dengan data dari API

  Student({required this.name, required this.dob});

  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      name: json['nama'],
      dob: json['tanggal_lahir'], // Sesuaikan dengan nama field dari API
    );
  }
}

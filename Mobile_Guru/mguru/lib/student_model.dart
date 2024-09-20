class Student {
  final String id;
  final String name;
  final String dob;

  Student({
    required this.id,
    required this.name,
    required this.dob,
  });

  // Factory constructor untuk membuat instance Student dari JSON
  factory Student.fromJson(Map<String, dynamic> json) {
    return Student(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      dob: json['dob'] ?? '',
    );
  }

  // Method untuk mengubah instance Student menjadi JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'dob': dob,
    };
  }
}

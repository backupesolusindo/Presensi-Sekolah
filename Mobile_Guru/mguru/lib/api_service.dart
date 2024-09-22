import 'dart:convert';
import 'package:http/http.dart' as http;
import 'student_model.dart'; // Import the student model

// Replace this URL with your actual API endpoint
const String apiUrl = 'https://presensi-smp1.esolusindo.com/ApiSiswa/Siswa/Sync';

// Fetch the list of students from the API based on the subject
Future<List<Student>> fetchStudents(String subjectId) async {
  try {
    // Assuming the API URL needs a query parameter to filter by subject
    final response = await http.get(Uri.parse('$apiUrl?subjectId=$subjectId'));

    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Student.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load students');
    }
  } catch (e) {
    throw Exception('Failed to load students: $e');
  }
}

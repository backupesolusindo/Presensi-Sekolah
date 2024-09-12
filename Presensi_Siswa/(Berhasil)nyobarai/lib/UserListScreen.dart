import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'DB/DatabaseHelper.dart';

class UserListScreen extends StatefulWidget {
  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> {
  late Future<List<Map<String, dynamic>>> _users;

  @override
  void initState() {
    super.initState();
    _users = _fetchUsers();
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    final dbHelper = DatabaseHelper.instance;
    return await dbHelper.queryAllRows();
  }

  Future<void> _uploadData() async {
    final dbHelper = DatabaseHelper.instance;
    final users = await dbHelper.queryAllRows();

    for (var user in users) {
      final response = await http.post(
        Uri.parse('http://192.168.1.6/face_recognition_api/upload.php'), // Ganti dengan URL API Anda
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: jsonEncode(<String, dynamic>{
          'name': user[DatabaseHelper.columnName],
          'nis': user[DatabaseHelper.columnNIS],
          'kelas': user[DatabaseHelper.columnKelas],
          'embedding': user[DatabaseHelper.columnEmbedding],
        }),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        print('Upload response: ${responseData['message']}');
      } else {
        print('Failed to upload data');
      }
    }
  }

  Future<void> _downloadData() async {
    final response = await http.get(Uri.parse('http://192.168.1.6/face_recognition_api/download.php')); // Ganti dengan URL API Anda

    if (response.statusCode == 200) {
      final List<dynamic> users = jsonDecode(response.body);
      final dbHelper = DatabaseHelper.instance;

      // Menghapus data lama
      await dbHelper.deleteAll();

      // Menyimpan data baru
      for (var user in users) {
        await dbHelper.insert({
          DatabaseHelper.columnName: user['name'],
          DatabaseHelper.columnNIS: user['nis'],
          DatabaseHelper.columnKelas: user['kelas'],
          DatabaseHelper.columnEmbedding: user['embedding'],
        });
      }

      // Refresh data
      setState(() {
        _users = _fetchUsers();
      });

      print('Data downloaded and synchronized successfully');
    } else {
      print('Failed to download data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Daftar User')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _uploadData,
            child: Text('Upload Data'),
          ),
          ElevatedButton(
            onPressed: _downloadData,
            child: Text('Download Data'),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _users,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No users found.'));
                }

                final users = snapshot.data!;

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return ListTile(
                      title: Text(user[DatabaseHelper.columnName]), // Menampilkan nama
                      subtitle: Text(
                        'ID: ${user[DatabaseHelper.columnId]}, NIS: ${user[DatabaseHelper.columnNIS]}, Kelas: ${user[DatabaseHelper.columnKelas]}'
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

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


  Future<void> _syncDatabro() async {
    final dbHelper = DatabaseHelper.instance;
    final users = await dbHelper.queryAllRows();
    List<Map<String, dynamic>> arData = [];

    for (var user in users) {
      arData.add({
        'nama': user[DatabaseHelper.columnName],
        'nis': user[DatabaseHelper.columnNIS],
        'kelas': user[DatabaseHelper.columnKelas],
        'model': user[DatabaseHelper.columnEmbedding],
      });
    }
    String bodyraw = jsonEncode(<String, dynamic>{'data': arData});
    print(bodyraw);

    final response = await http.post(
      Uri.parse(
          'https://presensi-smp1.esolusindo.com/ApiSiswa/Siswa/SyncSiswa'), // Ganti dengan URL API Anda
      headers: <String, String>{
        'Content-Type': 'application/json; charset=UTF-8',
      },
      body: bodyraw,
    );

    if (response.statusCode == 200) {
      print(response.body);
      final responseData = jsonDecode(response.body);
      print('Upload response: ${responseData['message']}');
      if (responseData['message']['status'] == 200) {
        final List<dynamic> users = responseData['data'];
        // Menghapus data lama
        await dbHelper.deleteAll();

        // Menyimpan data baru
        for (var user in users) {
          await dbHelper.insert({
            DatabaseHelper.columnName: user['nama'],
            DatabaseHelper.columnNIS: user['nis'],
            DatabaseHelper.columnKelas: user['kelas'],
            DatabaseHelper.columnEmbedding: user['model'],
          });
        }
      }

      // Refresh data
      setState(() {
        _users = _fetchUsers();
      });
    } else {
      print('Failed to upload data');
    }
  }

  // Future<void> _downloadData() async {
  //   final response = await http.get(Uri.parse(
  //       'https://presensi-smp1.esolusindo.com/ApiSiswa/Siswa/getSiswa')); // Ganti dengan URL API Anda
  //   if (_uploadCompleted) {
  //     if (response.statusCode == 200) {
  //       final List<dynamic> users = jsonDecode(response.body);
  //       final dbHelper = DatabaseHelper.instance;

  //       // Menghapus data lama
  //       await dbHelper.deleteAll();

  //       // Menyimpan data baru
  //       for (var user in users) {
  //         await dbHelper.insert({
  //           DatabaseHelper.columnName: user['name'],
  //           DatabaseHelper.columnNIS: user['nis'],
  //           DatabaseHelper.columnKelas: user['kelas'],
  //           DatabaseHelper.columnEmbedding: user['embedding'],
  //         });
  //       }

  //       // Refresh data
  //       setState(() {
  //         _users = _fetchUsers();
  //       });

  //       print('Data downloaded and synchronized successfully');
  //     }
  //   } else {
  //     print('Failed to download data');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Daftar User')),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _syncDatabro,
            child: Text('Sync Data'),
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
                      title: Text(user[DatabaseHelper.columnName]),
                      subtitle: RichText(
                        text: TextSpan(
                          style: DefaultTextStyle.of(context).style,
                          children: [
                            TextSpan(
                              text:
                                  'ID: ${user[DatabaseHelper.columnId]}, NIS: ${user[DatabaseHelper.columnNIS]}, Kelas: ${user[DatabaseHelper.columnKelas]}\n',
                              style: TextStyle(
                                  fontSize:
                                      16), // Sesuaikan ukuran font sesuai kebutuhan
                            ),
                            TextSpan(
                              text:
                                  'Face: ${user[DatabaseHelper.columnEmbedding]}',
                              style: TextStyle(
                                  fontSize: 8,
                                  color: const Color.fromARGB(255, 38, 0,
                                      255)), // Ukuran font lebih kecil dan warna berbeda
                            ),
                          ],
                        ),
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

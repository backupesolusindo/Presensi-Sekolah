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
  bool _isSyncing = false;
  String _sortCriteria = 'nama';

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
    setState(() {
      _isSyncing = true;
    });

    final dbHelper = DatabaseHelper.instance;
    final users = await dbHelper.queryAllRows();
    List<Map<String, dynamic>> arData = [];

    for (var user in users) {
      arData.add({
        'nama': user[DatabaseHelper.columnName],
        'nis': user[DatabaseHelper.columnNIS],
        'kelas': user[DatabaseHelper.columnKelas],
        'no_hp_ortu':
            user[DatabaseHelper.columnNoHpOrtu], // Tambahkan No HP Orang Tua
        'model': user[DatabaseHelper.columnEmbedding],
      });
    }
    String bodyraw = jsonEncode(<String, dynamic>{'data': arData});
    print(bodyraw);

    try {
      final response = await http.post(
        Uri.parse(
            'https://presensi-smp1.esolusindo.com/Api/ApiSiswa/Siswa/SyncSiswa'),
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
        },
        body: bodyraw,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['message']['status'] == 200 ||
            responseData['message']['status'] == 201) {
          final List<dynamic> users = responseData['data'];
          await dbHelper.deleteAll();

          for (var user in users) {
            await dbHelper.insert({
              DatabaseHelper.columnName: user['nama'],
              DatabaseHelper.columnNIS: user['nis'],
              DatabaseHelper.columnKelas: user['kelas'],
              DatabaseHelper.columnNoHpOrtu:
                  user['no_hp_ortu'], // Menyimpan No HP Orang Tua
              DatabaseHelper.columnEmbedding: user['model'],
            });
          }

          setState(() {
            _users = _fetchUsers();
          });
        }
      } else {
        _showErrorDialog(
            'Gagal mengupload data, status: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Koneksi gagal. Pastikan Anda terhubung ke internet.');
    } finally {
      setState(() {
        _isSyncing = false;
      });
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Kesalahan'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  List<Map<String, dynamic>> _sortUsers(List<Map<String, dynamic>> users) {
    List<Map<String, dynamic>> sortedUsers = List.from(users);
    sortedUsers.sort((a, b) {
      if (_sortCriteria == 'nama') {
        return a[DatabaseHelper.columnName]
            .compareTo(b[DatabaseHelper.columnName]);
      } else if (_sortCriteria == 'kelas') {
        return a[DatabaseHelper.columnKelas]
            .compareTo(b[DatabaseHelper.columnKelas]);
      } else {
        return a[DatabaseHelper.columnNIS]
            .compareTo(b[DatabaseHelper.columnNIS]);
      }
    });
    return sortedUsers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Daftar Murid',
          style:
              TextStyle(color: Colors.white), // Ubah warna teks menjadi putih
        ),
        automaticallyImplyLeading: false,
        shadowColor: Colors.black54,
        actions: [
          _isSyncing
              ? Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        const Color.fromARGB(255, 247, 247, 247)),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: ElevatedButton(
                    onPressed: _syncDatabro,
                    child: Text('Sync Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ),
        ],
        leading: IconButton(
          icon:
              Image.asset('assets/logoSMP.png'), // Mengganti tombol dengan logo
          onPressed: () {
            Navigator.pop(context); // Navigasi kembali ke layar sebelumnya
          },
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text("Urutkan: ",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(width: 10),
              DropdownButton<String>(
                value: _sortCriteria,
                onChanged: (String? newValue) {
                  setState(() {
                    _sortCriteria = newValue!;
                  });
                },
                items: <String>['nama', 'kelas', 'nis']
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text(value[0].toUpperCase() + value.substring(1)),
                    ),
                  );
                }).toList(),
                icon: Icon(Icons.arrow_drop_down),
              ),
            ],
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

                final users = _sortUsers(snapshot.data!);

                return ListView.builder(
                  itemCount: users.length,
                  itemBuilder: (context, index) {
                    final user = users[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 16.0, vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      elevation: 5,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: Colors.blueAccent,
                              child: Text(
                                user[DatabaseHelper.columnName][0]
                                    .toUpperCase(),
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user[DatabaseHelper.columnName],
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  RichText(
                                    text: TextSpan(
                                      style: DefaultTextStyle.of(context).style,
                                      children: [
                                        TextSpan(
                                          text:
                                              'NIS: ${user[DatabaseHelper.columnNIS]}, ',
                                          style:
                                              TextStyle(color: Colors.black54),
                                        ),
                                        TextSpan(
                                          text:
                                              'Kelas: ${user[DatabaseHelper.columnKelas]}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueAccent,
                                          ),
                                        ),
                                        TextSpan(
                                          text:
                                              '\nNo HP Ortu: ${user[DatabaseHelper.columnNoHpOrtu]}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: const Color.fromARGB(
                                                255, 255, 145, 0),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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

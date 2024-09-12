import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Daftar User')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
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
                  'ID: ${user[DatabaseHelper.columnId]}, NIS: ${user[DatabaseHelper.columnNIS]}, Kelas: ${user[DatabaseHelper.columnKelas]}, FaceData: ${user[DatabaseHelper.columnEmbedding]}'
                ),
              );
            },
          );
        },
      ),
    );
  }
}

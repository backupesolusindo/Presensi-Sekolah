import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class StudentPage extends StatefulWidget {
  final String subjectKey;

  StudentPage({required this.subjectKey});

  @override
  _StudentPageState createState() => _StudentPageState();
}

class _StudentPageState extends State<StudentPage> {
  final DatabaseReference _studentsRef = FirebaseDatabase.instance.reference().child('students');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Daftar Murid'),
      ),
      body: StreamBuilder(
        stream: _studentsRef.child(widget.subjectKey).onValue,
        builder: (context, AsyncSnapshot<DatabaseEvent> event) {
          if (event.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (event.hasError) {
            return Center(child: Text('Terjadi kesalahan'));
          }

          // Pastikan data dan snapshot tidak null
          if (event.data?.snapshot.value == null) {
            return Center(child: Text('Tidak ada data murid'));
          }

          // Casting ke Map<dynamic, dynamic> dari Object?
          final data = Map<dynamic, dynamic>.from(event.data!.snapshot.value as Map);

          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {
              final studentKey = data.keys.elementAt(index);
              final studentName = data[studentKey]['name'];

              return ListTile(
                title: Text(studentName),
                onTap: () {
                  // Aksi ketika murid diklik
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Aksi ketika tombol tambah murid ditekan
        },
        child: Icon(Icons.add),
      ),
    );
  }
}

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:dropdown_search/dropdown_search.dart';


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _AbsenScreenState();
}

class _AbsenScreenState extends State<HomePage> {
  List siswaList = [];
  List absenList = [];

  @override
  void initState() {
    super.initState();
    fetchSiswa();
  }

  // Ambil daftar siswa dari API
  Future<void> fetchSiswa() async {
    final res = await http.get(Uri.parse("http://192.168.1.5/nama_project/ApiSiswa"));
    if (res.statusCode == 200) {
      setState(() {
        siswaList = jsonDecode(res.body);
      });
    }
  }

  // Ambil data absen berdasarkan NIS
  Future<void> fetchAbsenByNis(String nis) async {
    final res = await http.get(Uri.parse("http://192.168.1.5/nama_project/ApiAbsen/byNis/$nis"));
    if (res.statusCode == 200) {
      setState(() {
        absenList = jsonDecode(res.body);
      });
    } else {
      setState(() {
        absenList = [];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Data Absensi Siswa")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownSearch<String>(
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(hintText: 'Cari NIS atau Nama'),
                ),
              ),
              items: siswaList.map((s) => "${s['nis']} - ${s['nama']}").toList(),
              onChanged: (val) {
                if (val != null) {
                  String nis = val.split(' - ')[0];
                  fetchAbsenByNis(nis);
                }
              },
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(labelText: "Pilih Siswa"),
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: absenList.isEmpty
                  ? const Center(child: Text("Tidak ada data absen"))
                  : ListView.builder(
                      itemCount: absenList.length,
                      itemBuilder: (context, index) {
                        final absen = absenList[index];
                        return Card(
                          child: ListTile(
                            title: Text("Tanggal: ${absen['tanggal']}"),
                            subtitle: Text(
                              "Masuk: ${absen['waktu_masuk'] ?? '-'} | Pulang: ${absen['waktu_pulang'] ?? '-'}",
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

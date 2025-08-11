import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'home.dart';
import 'bottombar.dart';
import 'profile.dart';

class RiwayatPage extends StatefulWidget {
  const RiwayatPage({super.key});

  @override
  _RiwayatPageState createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  int _currentIndex = 1;
  List<dynamic> riwayatList = [];

  @override
  void initState() {
    super.initState();
    _fetchRiwayat();
  }

  Future<void> _fetchRiwayat() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String>? riwayatJsonList = prefs.getStringList('riwayat_list');

      if (riwayatJsonList?.isNotEmpty ?? false) {
        setState(() {
          riwayatList = riwayatJsonList!
              .map((riwayatJson) => json.decode(riwayatJson))
              .toList();
        });
      } else {
        setState(() {
          riwayatList = [];
        });
      }
    } catch (e) {
      setState(() {
        riwayatList = [];
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });

    if (index == 0) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePage()),
      );
    } else if (index == 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const ProfilePage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Riwayat Presensi"),
        backgroundColor: const Color(0xFF03A9F4),
      ),
      body: riwayatList.isEmpty
          ? const Center(child: Text("Tidak ada riwayat."))
          : ListView.builder(
              itemCount: riwayatList.length,
              itemBuilder: (context, index) {
                final item = riwayatList[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: ListTile(
                    leading: const Icon(Icons.access_time, color: Colors.blueAccent),
                    title: Text(item['tanggal'] ?? "-"),
                    subtitle: Text(item['status'] ?? "-"),
                  ),
                );
              },
            ),
      bottomNavigationBar: CustomBottomBar(
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

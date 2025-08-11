import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/Kegiatan/components/body.dart';

class ListKegiatanScreen extends StatelessWidget {
  const ListKegiatanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Jadwal Kegiatan",
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
      body: const Body(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/Laporan/Kegiatan/components/body.dart';

class LaporanKegiatanScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Laporan Kegiatan",
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
      body: Body(),
    );
  }
}

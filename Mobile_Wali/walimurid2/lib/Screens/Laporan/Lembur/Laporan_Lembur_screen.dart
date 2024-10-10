import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/Laporan/Lembur/components/body.dart';

class LaporanLemburScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Laporan Lembur",
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
      body: Body(),
    );
  }
}

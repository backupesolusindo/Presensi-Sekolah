import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/Laporan/Perizinan/components/body.dart';

class LaporanCutiScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Laporan Cuti",
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
      body: Body(),
    );
  }
}

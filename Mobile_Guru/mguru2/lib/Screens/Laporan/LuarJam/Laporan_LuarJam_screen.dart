import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/Laporan/LuarJam/components/body.dart';

class LaporanLuarJamScreen extends StatelessWidget {
  const LaporanLuarJamScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Laporan Presensi Di Luar Jam Kerja",
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
      body: const Body(),
    );
  }
}

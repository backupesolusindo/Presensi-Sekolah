import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/Laporan/Presensi/components/body.dart';

class LaporanPresensiScreen extends StatelessWidget {
  const LaporanPresensiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Laporan Presensi",
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
      body: const Body(),
    );
  }
}

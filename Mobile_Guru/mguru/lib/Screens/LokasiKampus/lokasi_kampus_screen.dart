import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/LokasiKampus/components/body.dart';

class LokasiKampusScreen extends StatelessWidget {
  const LokasiKampusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Lokasi Kampus",
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
      body: const Body(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/Perizinan/components/body.dart';

class IzinScreen extends StatelessWidget {
  const IzinScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Cuti Pegawai",
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.white, // add custom icons also
          ),
        ),
      ),
      body: const Body(),
    );
  }
}

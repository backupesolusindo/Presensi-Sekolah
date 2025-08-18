import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/JadwalWF/ListJadwalWF/body.dart';

class ListJadwalWF_Screen extends StatefulWidget {
  const ListJadwalWF_Screen({super.key});

  @override
  _ListJadwalWF_ScreenState createState() => _ListJadwalWF_ScreenState();
}

class _ListJadwalWF_ScreenState extends State<ListJadwalWF_Screen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Jadwal WFH dan WFO Pegawai",
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
      ),
      body: const Body(),
    );
  }
}

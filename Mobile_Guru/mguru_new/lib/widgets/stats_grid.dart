import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/constants.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class StatsGrid extends StatefulWidget {
  const StatsGrid({super.key});

  @override
  _StatsGridState createState() => _StatsGridState();
}

class _StatsGridState extends State<StatsGrid> {
  String tepat = "0";
  String toleransi = "0";
  String terlambat = "0";
  String UUID = "";
  int jmlPre = 0, jmlCuti = 0, jmlKegiatan = 0;

  @override
  void initState() {
    // TODO: implement initState
    // WidgetsBinding.instance.addPostFrameCallback(getPref());
    super.initState();
    getDataDash();
    getProfil();
  }

  Future<String> getDataDash() async {
    print("getStatistic");
    SharedPreferences prefs = await SharedPreferences.getInstance();
    UUID = prefs.getString("ID")!;
    var res = await http.get(
        Uri.parse("${Core().ApiUrl}Dash/getStatus/$UUID"),
        headers: {"Accept": "application/json"});
    var resBody = json.decode(res.body);
    setState(() {
      tepat = resBody['tepat'].toString();
      toleransi = resBody['toleransi'].toString();
      terlambat = resBody['terlambat'].toString();
    });
    print(resBody);
    return "";
  }

  Future<String> getProfil() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    UUID = prefs.getString("ID")!;
    var res = await http.get(Uri.parse("${Core().ApiUrl}Dash/get_dash/$UUID"),
        headers: {"Accept": "application/json"});
    var resBody = json.decode(res.body);
    setState(() {
      jmlCuti = resBody['data']['jmlCutiBln'];
      jmlKegiatan = resBody['data']['jmlKegiatanBln'];
      jmlPre = resBody['data']['jmlPresensiBln'];
    });
    print(resBody);
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: <Widget>[
          Flexible(
            child: Row(
              children: <Widget>[
                _buildStatCard('Tepat Waktu', tepat, CSuccess),
                _buildStatCard('Toleransi', toleransi, CWarning),
                _buildStatCard('Terlambat', terlambat, CDanger),
              ],
            ),
          ),
          _CartItem(
              "Jumlah Presensi Bulan Ini",
              "$jmlPre Presensi",
              const Icon(
                Icons.alarm_on,
                size: 40.0,
                color: approval_presensi,
              )),
          _CartItem(
              "Jumlah Kegiatan Bulan Ini",
              "$jmlKegiatan Kegiatan",
              const Icon(
                Icons.directions_walk_outlined,
                size: 40.0,
                color: approval_kegiatan,
              )),
          _CartItem(
              "Jumlah Cuti Bulan Ini",
              "$jmlCuti Cuti",
              const Icon(
                Icons.home_work_rounded,
                size: 40.0,
                color: approval_cuti,
              )),
        ],
      ),
    );
  }

  Expanded _buildStatCard(String title, String count, Color color) {
    return Expanded(
      flex: 1,
      child: Container(
        margin: const EdgeInsets.all(8.0),
        padding: const EdgeInsets.all(10.0),
        height: 100,
        decoration: BoxDecoration(
          color: color.withOpacity(0.8),
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.8),
              blurRadius: 4,
              offset: const Offset(4, 4), // Shadow position
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              count,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Container _CartItem(String Title, String Ket, Icon icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300, // Soft grey shadow with transparency
            spreadRadius: 2, // Controls how much the shadow spreads
            blurRadius: 8, // Higher value for smooth shadow
            offset:
                const Offset(0, 4), // Offset for vertical shadow, adjust as needed
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 21.0,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            icon,
            const SizedBox(width: 24.0),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  Ket,
                  style: const TextStyle(fontSize: 16.0, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4.0),
                Text(
                  Title,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 14.0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

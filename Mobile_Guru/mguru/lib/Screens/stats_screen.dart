import 'package:bubble_tab_indicator/bubble_tab_indicator.dart';
import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/config/palette.dart';
import 'package:mobile_presensi_kdtg/config/styles.dart';
import 'package:mobile_presensi_kdtg/constants.dart';
import 'package:mobile_presensi_kdtg/data/data.dart';
import 'package:mobile_presensi_kdtg/widgets/widgets.dart';

class StatsScreen extends StatefulWidget {
  @override
  _StatsScreenState createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        color: CBackground,
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                "assets/images/WaliRename.png",
                fit: BoxFit.cover,
              ),
            ),
            CustomScrollView(
              physics: ClampingScrollPhysics(),
              slivers: <Widget>[
                _buildHeader(),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  sliver: SliverToBoxAdapter(
                    child: StatsGrid(), // Replace with your actual StatsGrid widget
                  ),
                ),
                // Additional slivers go here
              ],
            ),
          ],
        ),
      ),
    );
  }

  SliverPadding _buildHeader() {
    return SliverPadding(
      padding: const EdgeInsets.only(
        left: 20.0,
        right: 20.0,
        bottom: 20.0,
        top: 60.0,
      ),
      sliver: SliverToBoxAdapter(
        child: Container(
          decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8), // Rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300, // Soft grey shadow with transparency
            spreadRadius: 2, // Controls how much the shadow spreads
            blurRadius: 8, // Higher value for smooth shadow
            offset:
                Offset(0, 4), // Offset for vertical shadow, adjust as needed
          ),
        ],
      ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Statistik Presensi',
              style: TextStyle(
                color: CText,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

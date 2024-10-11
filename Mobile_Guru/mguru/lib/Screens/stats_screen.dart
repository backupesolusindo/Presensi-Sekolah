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
        color: CBackground, // Background color
        child: Stack(
          children: [
            // Center the background image, fitting to the box
            Align(
              alignment: Alignment.center, // Center the image
              child: Image.asset(
                "assets/images/WaliRename.png",
                fit: BoxFit.cover, // Ensures the image fills the space
                width: size.width, // Adjusts to full screen width
                height: size.height, // Adjusts to full screen height
              ),
            ),
            
            // CustomScrollView for scrollable content
            CustomScrollView(
              physics: ClampingScrollPhysics(),
              slivers: <Widget>[
                _buildHeader(), // Build your header
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  sliver: SliverToBoxAdapter(
                    child: StatsGrid(), // Add your StatsGrid here
                  ),
                ),
                // Additional slivers can be added here
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
        top: 40.0,
      ),
      sliver: SliverToBoxAdapter(
        child: Card(
          elevation: 5.0, // Adds shadow for a 3D effect
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0), // Rounded corners
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0), // Inner padding for the card
            child: Text(
              'Statistik Presensi',
              style: const TextStyle(
                color: CText,
                fontSize: 25.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  final Widget child;
  const Background({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      width: double.infinity,
      height: size.height,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Center the image in the middle
          Center(
            child: Image.asset(
              "assets/images/WaliRename.png",
            ),
          ),
          // Black overlay with 0.3 opacity
          Container(
            width: double.infinity,
            height: size.height,
            color: Colors.black.withOpacity(0.3),
          ),
          child,  // Main content on top of the overlay
        ],
      ),
    );
  }
}

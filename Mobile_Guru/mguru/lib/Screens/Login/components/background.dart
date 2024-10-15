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
    return SizedBox(
      width: double.infinity,
      height: size.height,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          // Fullscreen image as background
          Positioned.fill(
            child: Image.asset(
              "assets/images/WaliRename.png",
              fit: BoxFit.cover,
            ),
          ),
          // Black overlay with 0.3 opacity
          Container(
            color: Colors.black.withOpacity(0.3),
          ),
          // Main content on top of the overlay
          child,
        ],
      ),
    );
  }
}

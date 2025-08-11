import 'package:flutter/material.dart';

class Background extends StatelessWidget {
  final Widget child;
  final Widget filter;
  const Background({Key? key, required this.child, required this.filter})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return SizedBox(
      width: double.infinity,
      height: size.height,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Positioned(
            bottom: 0,
            right: 0,
            child: Image.asset(
              "assets/images/main_bottom_right.png",
              width: size.width * 0.25,
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Image.asset(
              "assets/images/main_bottom_left.png",
              width: size.width * 0.25,
            ),
          ),
          Column(
            children: <Widget>[
              filter,
              const SizedBox(
                height: 8,
              ),
              child,
            ],
          )
        ],
      ),
    );
  }
}

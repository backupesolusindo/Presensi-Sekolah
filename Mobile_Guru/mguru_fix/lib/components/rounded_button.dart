import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/constants.dart';

class RoundedButton extends StatelessWidget {
  final String text;
  final Function press;
  final Color color, textColor;
  const RoundedButton({
    super.key,
    required this.text,
    required this.press,
    this.color = kPrimaryColor,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      width: size.width * 0.8,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(29),
        child: TextButton(
          onPressed: press as void Function()?,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
            width: size.width * 0.8,
            alignment: Alignment.center,
            decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.all(Radius.circular(20))),
            child: Text(
              text,
              style: TextStyle(fontSize: 18, color: textColor),
            ),
          ),
        ),
      ),
    );
  }
}

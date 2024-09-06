// import 'package:flutter/material.dart';

// class ClipPainter extends CustomClipper<Path> {
//   @override
//   Path getClip(Size size) {
//     var height = size.height;
//     var width = size.width;
//     var path = Path();

//     path.lineTo(0, height);
//     path.lineTo(width, height);
//     path.lineTo(width, 0);

//     // Top Left corner
//     var secondControlPoint = Offset(0, 0);
//     var secondEndPoint = Offset(width * .2, height * .3);
//     path.quadraticBezierTo(secondControlPoint.dx, secondControlPoint.dy,
//         secondEndPoint.dx, secondEndPoint.dy);

//     // Left Middle
//     var fifthControlPoint = Offset(width * .3, height * .5);
//     var fifthEndPoint = Offset(width * .23, height * .6);
//     path.quadraticBezierTo(fifthControlPoint.dx, fifthControlPoint.dy,
//         fifthEndPoint.dx, fifthEndPoint.dy);

//     // Bottom Left corner
//     var thirdControlPoint = Offset(0, height);
//     var thirdEndPoint = Offset(width, height);
//     path.quadraticBezierTo(thirdControlPoint.dx, thirdControlPoint.dy,
//         thirdEndPoint.dx, thirdEndPoint.dy);

//     path.close();

//     return path;
//   }

//   @override
//   bool shouldReclip(CustomClipper<Path> oldClipper) {
//     // Return true if the clipper needs to reclip based on some condition
//     return false;
//   }
// }

import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/Welcome/components/background.dart';

class Body extends StatefulWidget {
  const Body({super.key});

  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;

    return const Background(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            // FadeTransition(
            //   opacity: _opacityAnimation,
            //   child: Column(
            //     children: [
            //       const Text(
            //         "PRESENSI ONLINE",
            //         style: TextStyle(
            //           fontSize: 24,
            //           fontWeight: FontWeight.bold,
            //           color: Colors.blueAccent,
            //         ),
            //       ),
            //       Text(
            //         "SMP Negeri 3 Jember",
            //         style: TextStyle(
            //           fontWeight: FontWeight.bold,
            //           fontSize: 18,
            //           color: Colors.grey[700],
            //         ),
            //       ),
            //     ],
            //   ),
            // ),
            // SizedBox(height: size.height * 0.05),
            // ScaleTransition(
            //   scale: _scaleAnimation,
            //   child: Container(
            //     child: Image.asset(
            //       // "assets/images/smp1logo.png",
            //       "assets/images/iconguru.png",
            //       width: size.width * 0.6,
            //     ),
            //   ),
            // ),
            //SizedBox(height: size.height * 0.05),
            //FadeTransition(
              //opacity: _opacityAnimation,
              //child: RoundedButton(
                //text: "LOGIN",
                //press: () {
                  //Navigator.push(
                    //context,
                    //MaterialPageRoute(
                      //builder: (context) {
                        //return const presensi();
                      //},
                    //),
                  //);
                //},
              //),
            //),
          ],
        ),
      ),
    );
  }
}

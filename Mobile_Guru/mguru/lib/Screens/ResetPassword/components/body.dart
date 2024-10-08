import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/ResetPassword/components/background.dart';
import 'package:mobile_presensi_kdtg/Screens/ResetPassword/post_reset.dart';
import 'package:mobile_presensi_kdtg/components/rounded_button.dart';
import 'package:mobile_presensi_kdtg/components/rounded_password_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Body extends StatefulWidget {
  @override
  _Body createState() => _Body();
}

class _Body extends State<Body> {
  final txtPassword = TextEditingController();
  final txtrePassword = TextEditingController();
  String pesan = "";

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Background(
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            RoundedPasswordField(
              IdCon: txtPassword,
              hintText: "Password",
            ),
            SizedBox(height: size.height * 0.03),
            RoundedPasswordField(
              IdCon: txtrePassword,
              hintText: "Ketik Ulang Password",
            ),
            SizedBox(height: size.height * 0.03),
            Text(
              pesan,
              style: TextStyle(
                color: Colors.redAccent.withOpacity(0.8),
              ),
            ),
            SizedBox(height: size.height * 0.03),
            RoundedButton(
              text: "Reset Password",
              press: () async {
                if (txtPassword.text == txtrePassword.text) {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  PostReset.connectToApi(
                          prefs.getString("ID")!, txtPassword.text)
                      .then((value) {
                    setState(() {
                      pesan = value!.message;
                    });
                    if (value!.status_kode == 200) {
                      Navigator.pop(context);
                    }
                  });
                } else {
                  setState(() {
                    pesan = "Password Anda Tidak Sama";
                  });
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

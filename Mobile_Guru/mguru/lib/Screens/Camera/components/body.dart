import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/Camera/components/background.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_presensi_kdtg/components/rounded_button.dart';

List<CameraDescription> cameras = [];

class Body extends StatefulWidget {
  @override
  _Body createState() => _Body();
}

class _Body extends State<Body> {
  bool isLoading = false;
  String warnaPilih = "";
  late SharedPreferences prefs;

  late CameraController controller;
  late XFile imageFile;
  int selectedCameraIdx = 1;
  late int pilihCamera;
  List Data = [];

  @override
  void initState() {
    // TODO: implement initState

    prepareCamera();
    super.initState();
  }

  prepareCamera() async {
    prefs = await SharedPreferences.getInstance();
    selectedCameraIdx = prefs.getInt("CameraSelect")!;
    cameras = await availableCameras();
    for (var i = 0; i < cameras.length; i++) {
      Data.add(i);
    }
    CameraDescription selectedCamera = cameras[selectedCameraIdx];
    _initCameraController(selectedCamera);
  }

  Future _initCameraController(CameraDescription cameraDescription) async {
    // await controller.dispose();
    // 3
    controller = CameraController(cameraDescription, ResolutionPreset.high);

    // If the controller is updated then update the UI.
    // 4
    controller.addListener(() {
      // 5
      if (mounted) {
        setState(() {});
      }

      if (controller.value.hasError) {
        print('Camera error ${controller.value.errorDescription}');
      }
    });

    // 6
    try {
      await controller.initialize();
    } on CameraException catch (e) {
      // _showCameraException(e);
    }

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(child: getBody());
  }

  Widget getBody() {
    Size size = MediaQuery.of(context).size;
    return Container(
      child: Column(
        children: <Widget>[
          Container(
            margin: EdgeInsets.only(left: 8.0, right: 8.0, top: 8.0),
            height: size.height * 0.6,
            width: size.width * 0.9,
            child:
                (controller == null) ? Container() : CameraPreview(controller),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 36, vertical: 16),
            padding: EdgeInsets.only(left: 18, right: 18),
            decoration: BoxDecoration(
                border: Border.all(color: Colors.grey, width: 1),
                borderRadius: BorderRadius.circular(45)),
            child: DropdownButton(
              hint: Text("Pilih Setting Camera : "),
              dropdownColor: Colors.white,
              icon: Icon(Icons.arrow_drop_down),
              iconSize: 24,
              isExpanded: true,
              underline: SizedBox(),
              style: TextStyle(color: Colors.black, fontSize: 16),
              items: Data.map((item) {
                return new DropdownMenuItem(
                  child:
                      new Text("Setting Camera ke - " + (item + 1).toString()),
                  value: item.toString(),
                );
              }).toList(),
              onChanged: (newVal) {
                setState(() {
                  selectedCameraIdx = int.parse(newVal.toString());
                  print("Pilih Camera :" + selectedCameraIdx.toString());
                  CameraDescription selectedCamera = cameras[selectedCameraIdx];
                  _initCameraController(selectedCamera);
                });
              },
              value: selectedCameraIdx.toString(),
            ),
          ),
          RoundedButton(
            text: "SIMPAN SETTING",
            press: () async {
              prefs.setInt("CameraSelect", selectedCameraIdx);
              Navigator.pop(context);
            },
          )
        ],
      ),
    );
  }

  Future<void> _showMyDialog(String Title, String Keterangan) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AlertDialog(
            title: Text(Title),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(Keterangan),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Oke'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

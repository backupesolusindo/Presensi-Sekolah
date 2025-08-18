import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/absen_post.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/absen_selesai_post.dart';
import 'package:mobile_presensi_kdtg/Screens/dashboard_screen.dart';
import 'package:mobile_presensi_kdtg/components/rounded_button_small.dart';
import 'package:mobile_presensi_kdtg/constants.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:trust_location/trust_location.dart';

List<CameraDescription> cameras = [];

class AbsenSelesaiWFScreen extends StatelessWidget {
  const AbsenSelesaiWFScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: AbsenPage(),
    );
  }
}

class AbsenPage extends StatefulWidget {
  const AbsenPage({super.key});

  @override
  _AbsenPage createState() => _AbsenPage();
}

class _AbsenPage extends State<AbsenPage> {
  final AbsenPost absenPost = AbsenPost();
  late GoogleMapController _controller;
  double la_polije = -8.1594718;
  double lo_polije = 113.720271;
  double Jarak = 0;

  double la = 0;
  double lo = 0;
  int statusLoading = 0;
  String NIP = "", Nama = "", UUID = "";
  String jam = "", jam_pulang = "Belum Presensi Pulang";
  var DataAbsen, DataPegawai, DataAbsenPulang;
  bool _isMockLocation = false;
  bool bacakamera = false;

  late CameraController controller;
  late XFile imageFile;
  late File _image;

  @override
  void initState() {
    super.initState();
    prepareCamera();
    getCurrentLocation();
    getPref();
  }

  Future<void> getPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    UUID = prefs.getString("ID")!;
    NIP = prefs.getString("NIP")!;
    Nama = prefs.getString("Nama")!;
    if (prefs.getDouble("LokasiLat") != null ||
        prefs.getDouble("LokasiLat")! > 0) {
      la_polije = prefs.getDouble("LokasiLat")!;
      lo_polije = prefs.getDouble("LokasiLng")!;
    }
    print("Login Pref :$UUID");
    getDataDash();
  }

  Future<String> getDataDash() async {
    var res = await http.get(Uri.parse("${Core().ApiUrl}Dash/get_dash/$UUID"),
        headers: {"Accept": "application/json"});
    var resBody = json.decode(res.body);
    setState(() {
      DataPegawai = resBody['data']["pegawai"];
    });
    print(resBody);
    return "";
  }

  Future<void> prepareCamera() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    cameras = await availableCameras();
    controller = CameraController(
      cameras[prefs.getInt('CameraSelect')!],
      ResolutionPreset.low,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    controller.initialize().then((_) {
      if (!mounted) {
        _showMyDialog("KAMERA", "Kamera Depan Tidak Terbaca");
        controller = CameraController(
          cameras[1],
          ResolutionPreset.low,
          enableAudio: false,
          imageFormatGroup: ImageFormatGroup.jpeg,
        );
        return;
      } else {
        bacakamera = true;
      }
      setState(() {});
    });
  }

  Future<XFile?> takePicture() async {
    final CameraController cameraController = controller;
    if (!cameraController.value.isInitialized) {
      return null;
    }

    if (cameraController.value.isTakingPicture) {
      // A capture is already pending, do nothing.
      return null;
    }

    try {
      XFile file = await cameraController.takePicture();
      return file;
    } on CameraException catch (e) {
      print("error Camera :");
      print(e);
      getCameraEx();
      return null;
    }
  }

  final picker = ImagePicker();
  Future getCameraEx() async {
    final pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        maxHeight: 380,
        maxWidth: 540);

    setState(() {
      if (pickedFile != null) {
        _image = File(pickedFile.path);
      } else {
        print('No image selected.');
      }
    });
  }

  void onTakePictureButtonPressed() {
    Future<XFile?> takePicture() async {
      final CameraController cameraController = controller;
      if (!cameraController.value.isInitialized) {
        return null;
      }

      if (cameraController.value.isTakingPicture) {
        // A capture is already pending, do nothing.
        return null;
      }

      try {
        XFile file = await cameraController.takePicture();
        return file;
      } on CameraException catch (e) {
        print("error Camera :");
        print(e);
        getCameraEx();
        return null;
      }
    }
  }

  Future<dynamic> getCurrentLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool("sl_wfh_selesai")!) {
      _showPerizinan();
    }
    _isMockLocation = await TrustLocation.isMockLocation;
    print("fake GPS :");
    print(_isMockLocation);

    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }
    final geoposition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    setState(() {
      la = geoposition.latitude;
      lo = geoposition.longitude;
      Jarak = Geolocator.distanceBetween(la, lo, la_polije, lo_polije);
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        body: Stack(children: <Widget>[
      GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(la, lo),
          zoom: 16.0,
        ),
        markers: <Marker>{
            Marker(
              markerId: const MarkerId('marker_1'),
              position: LatLng(la, lo),
              consumeTapEvents: true,
              infoWindow: InfoWindow(
                title: 'Lokasi Anda',
                snippet: "Jarak : ${Jarak.toInt()} M",
              ),
              onTap: () {
                print("Marker tapped");
              },
            ),
          },
        mapType: MapType.hybrid,
        polygons: <Polygon>{
          Polygon(
              polygonId: const PolygonId("Area Polije"),
              points: const <LatLng>[
                LatLng(-8.159848, 113.720521),
                LatLng(-8.161228, 113.723176),
                LatLng(-8.160425, 113.723687),
                LatLng(-8.161215, 113.725171),
                LatLng(-8.154612, 113.725997),
                LatLng(-8.153624, 113.723426),
              ],
              strokeWidth: 2,
              strokeColor: Colors.blue,
              fillColor: Colors.blue.withOpacity(0.1))
        },
        onTap: (location) => print('onTap: $location'),
        onCameraMove: (cameraUpdate) => print('onCameraMove: $cameraUpdate'),
        compassEnabled: true,
        onMapCreated: (controller) {
          _controller = controller;
          Future.delayed(const Duration(seconds: 2)).then(
            (_) {
              controller.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    bearing: 0,
                    target: LatLng(la, lo),
                    tilt: 30.0,
                    zoom: 18,
                  ),
                ),
              );
              controller
                  .getVisibleRegion()
                  .then((bounds) => print("bounds: ${bounds.toString()}"));
            },
          );
        },
      ),
      Positioned(
          bottom: 12,
          width: size.width * 0.85,
          child: Container(
            margin: const EdgeInsets.only(left: 10.0, right: 10.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              color: Colors.white,
              elevation: 10,
              child: Column(
                children: <Widget>[
                  Row(
                    children: [
                      Column(children: [
                        (_image == null)
                            ? Container(
                                margin: const EdgeInsets.only(
                                    left: 8.0, right: 8.0, top: 8.0),
                                height: 59,
                                width: 59,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  image: const DecorationImage(
                                    image: AssetImage(
                                        'assets/images/user_image.png'),
                                  ),
                                ),
                              )
                            : Padding(
                                padding: const EdgeInsets.only(
                                    left: 8.0, right: 8.0, top: 8.0),
                                child:
                                    Image.file(_image, width: 80, height: 120)),
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                          child: TextButton(
                            onPressed: () {
                              if (bacakamera) {
                                _popCamera();
                              } else {
                                getCameraEx();
                              }
                            },
                            child: const Text(
                              "Ambil Foto",
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        )
                      ]),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5, top: 8, right: 0),
                        child: Column(
                          children: <Widget>[
                            const Text("Nama Lengkap"),
                            Text(
                              Nama,
                              style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue),
                            ),
                            const SizedBox(
                              height: 4,
                            ),
                            const Text("NIP"),
                            Text(
                              NIP,
                              style:
                                  const TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                            const Text(
                              "Work From Home ",
                              style: TextStyle(fontSize: 11, color: CSuccess),
                            ),
                            const SizedBox(
                              height: 8,
                            ),
                            if (statusLoading == 1) const CircularProgressIndicator(),
                            if (statusLoading == 0)
                              RoundedButtonSmall(
                                text: "SELESAI WFH",
                                color: kPrimaryColor,
                                press: () async {
                                  setState(() {
                                    statusLoading = 1;
                                  });
                                  _isMockLocation =
                                      await TrustLocation.isMockLocation;
                                  print("fake GPS :");
                                  print(_isMockLocation);

                                  if (_isMockLocation == true) {
                                    _showMyDialogFake();
                                  } else {
                                    SharedPreferences prefs =
                                        await SharedPreferences.getInstance();
                                    AbsenSelesaiPost.connectToApi(
                                            prefs.getString("ID")!,
                                            DataPegawai['idabsen'],
                                            la.toString(),
                                            lo.toString(),
                                            _image)
                                        .then((value) {
                                      if (value!.status_kode == 200) {
                                        Navigator.of(context).pop();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) {
                                              return const DashboardScreen();
                                            },
                                          ),
                                        );
                                      } else {
                                        _showMyDialog(
                                            "Absensi WFH", value.message);
                                      }
                                      setState(() {
                                        statusLoading = 0;
                                      });
                                    });
                                                                    }
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )),
      Positioned(
          bottom: size.height * 0.15,
          right: 8,
          child: SizedBox(
            width: 50,
            child: FloatingActionButton(
              onPressed: () {
                getCurrentLocation();
                _controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      bearing: 0,
                      target: LatLng(la, lo),
                      tilt: 30.0,
                      zoom: 18,
                    ),
                  ),
                );
                _controller
                    .getVisibleRegion()
                    .then((bounds) => print("bounds: ${bounds.toString()}"));
              },
              backgroundColor: kPrimaryColor,
              child: const Icon(Icons.my_location),
            ),
          ))
    ]));
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
                child: const Text('Keluar'),
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

  Future<void> _showMyDialogFake() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AlertDialog(
            title: const Text("FAKE GPS"),
            content: const SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text("HARAP UNINSTALL FAKE GPS ANDA !!!"),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Keluar'),
                onPressed: () {
                  exit(0);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showPerizinan() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AlertDialog(
            title: const Text("PERIZINAN AKSES LOKASI"),
            content: const SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                      "Aplikasi ini mengumpulkan data lokasi untuk mengaktifkan Selesai WFH."),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.setBool("sl_wfh_selesai", false);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _popCamera() async {
    Size size = MediaQuery.of(context).size;
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AlertDialog(
            contentPadding: const EdgeInsets.all(0),
            content: Container(
              // height: size.height * 0.6,
              margin: const EdgeInsets.all(0),
              padding: const EdgeInsets.all(0),
              child: CameraPreview(controller),
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () async {
                  onTakePictureButtonPressed();
                  Navigator.of(context).pop();
                },
                child: Image.asset("assets/icons/camera.png", height: 50),
              ),
              TextButton(
                child: const Text('Kembali', style: TextStyle(color: CDanger)),
                onPressed: () async {
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

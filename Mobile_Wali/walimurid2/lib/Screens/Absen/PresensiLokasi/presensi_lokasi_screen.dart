import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/PresensiLokasi/presensi_lokasi_post.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/absen_post.dart';
import 'package:mobile_presensi_kdtg/Screens/Login/components/body.dart';
import 'package:mobile_presensi_kdtg/Screens/dashboard_screen.dart';
import 'package:mobile_presensi_kdtg/components/rounded_button.dart';
import 'package:mobile_presensi_kdtg/components/rounded_button_small.dart';
import 'package:mobile_presensi_kdtg/components/show_peringatan.dart';
import 'package:mobile_presensi_kdtg/components/text_style.dart';
import 'package:mobile_presensi_kdtg/constants.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trust_location/trust_location.dart';

List<CameraDescription> cameras = [];

class PresensiLokasiScreen extends StatefulWidget {
  @override
  _PresensiLokasiScreenState createState() => _PresensiLokasiScreenState();
}

class _PresensiLokasiScreenState extends State<PresensiLokasiScreen> {
  final AbsenPost absenPost = new AbsenPost();

  late GoogleMapController _controller;
  double la_polije = -8.1594718;
  double lo_polije = 113.720271;
  double Jarak = 0;
  double radius = Core().MaximalJarak;

  double la = 0;
  double lo = 0;

  String Nama = "", NIP = "";
  late SharedPreferences prefs;

  int statusLoading = 0;
  bool bacakamera = false;

  late CameraController controller;
  late XFile imageFile;
  late File _image;

  @override
  void initState() {
    super.initState();
    prepareCamera();
    getCurrentLocation();
  }

  prepareCamera() async {
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
          cameras.first,
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
    if (cameraController == null || !cameraController.value.isInitialized) {
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
    final pickedFile = await picker.getImage(
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
      if (cameraController == null || !cameraController.value.isInitialized) {
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

  getCurrentLocation() async {
    prefs = await SharedPreferences.getInstance();
    if (prefs.getBool("sl_lokasi")!) {
      _showPerizinan();
    }
    Nama = prefs.getString("Nama")!;
    NIP = prefs.getString("NIP")!;
    la_polije = prefs.getDouble("LokasiLat")!;
    lo_polije = prefs.getDouble("LokasiLng")!;
    radius = prefs.getDouble("Radius")!;
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
        myLocationEnabled: true,
        initialCameraPosition: CameraPosition(
          target: new LatLng(la, lo),
          zoom: 16.0,
        ),
        markers: Set<Marker>.of(
          [
            Marker(
              markerId: MarkerId('marker_1'),
              position: LatLng(la, lo),
              consumeTapEvents: true,
              infoWindow: InfoWindow(
                title: 'Lokasi Anda',
                snippet: "Jarak : " + Jarak.toInt().toString() + " M",
              ),
              onTap: () {
                print("Marker tapped");
              },
            ),
          ],
        ),
        mapType: MapType.hybrid,
        polygons: Set<Polygon>.of([
          Polygon(
              polygonId: PolygonId("Area Polije"),
              points: const <LatLng>[
                const LatLng(-8.159848, 113.720521),
                const LatLng(-8.161228, 113.723176),
                const LatLng(-8.160425, 113.723687),
                const LatLng(-8.161215, 113.725171),
                const LatLng(-8.154612, 113.725997),
                const LatLng(-8.153624, 113.723426),
              ],
              strokeWidth: 2,
              strokeColor: Colors.blue,
              fillColor: Colors.blue.withOpacity(0.1))
        ]),
        onTap: (location) => print('onTap: $location'),
        onCameraMove: (cameraUpdate) => print('onCameraMove: $cameraUpdate'),
        compassEnabled: true,
        onMapCreated: (GoogleMapController controller) {
          _controller = controller;
          Future.delayed(Duration(seconds: 2)).then(
            (_) {
              controller.animateCamera(
                CameraUpdate.newCameraPosition(
                  CameraPosition(
                    bearing: 0,
                    target: new LatLng(la, lo),
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
            margin: EdgeInsets.only(left: 10.0, right: 10.0),
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
                                margin: EdgeInsets.only(
                                    left: 8.0, right: 8.0, top: 8.0),
                                height: 59,
                                width: 59,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(50),
                                  image: DecorationImage(
                                    image: AssetImage(
                                        'assets/images/user_image.png'),
                                  ),
                                ),
                              )
                            : Padding(
                                padding: EdgeInsets.only(
                                    left: 8.0, right: 8.0, top: 8.0),
                                child:
                                    Image.file(_image, width: 80, height: 120)),
                        Padding(
                          padding: EdgeInsets.only(left: 4.0, right: 4.0),
                          child: TextButton(
                            onPressed: () {
                              if (bacakamera) {
                                _popCamera();
                              } else {
                                getCameraEx();
                              }
                              ;
                            },
                            child: Text(
                              "Ambil Foto",
                              style: TextStyle(fontSize: 11),
                            ),
                          ),
                        )
                      ]),
                      Padding(
                        padding: EdgeInsets.only(bottom: 5, top: 8, right: 0),
                        child: Column(
                          children: <Widget>[
                            Text("Nama Lengkap"),
                            Text(
                              Nama,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue),
                            ),
                            SizedBox(
                              height: 4,
                            ),
                            Text("NIP"),
                            Text(
                              NIP,
                              style:
                                  TextStyle(fontSize: 12, color: Colors.blue),
                            ),
                            Text(
                              "Jarak Kantor : " +
                                  Jarak.toInt().toString() +
                                  " Meter",
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Jarak.toInt() < radius
                                      ? CSuccess
                                      : CDanger),
                            ),
                            SizedBox(
                              height: 8,
                            ),
                            if (statusLoading == 1) CircularProgressIndicator(),
                            if (statusLoading == 0)
                              RoundedButtonSmall(
                                text: "PRESENSI LOKASI",
                                color: Jarak.toInt() < radius
                                    ? kPrimaryColor
                                    : ColorLight,
                                press: () async {
                                  bool _isMockLocation =
                                      await TrustLocation.isMockLocation;
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  if (prefs.getInt("status_spesial") == 1) {
                                    if (_image == null) {
                                      _showMyDialog("Absensi Lokasi",
                                          "Anda Belum Mengambil Foto. Mohon Ambil Foto Terlebih Dahulu !");
                                      setState(() {
                                        statusLoading = 0;
                                      });
                                    } else {
                                      PresensiLokasiPost.connectToApi(
                                              prefs.getString("ID")!,
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
                                                return DashboardScreen();
                                              },
                                            ),
                                          );
                                        }
                                        setState(() {
                                          statusLoading = 0;
                                        });
                                      });
                                    }
                                  } else {
                                    if (Jarak.toInt() < radius) {
                                      if (_image == null) {
                                        _showMyDialog("Absensi Lokasi",
                                            "Anda Belum Mengambil Foto. Mohon Ambil Foto Terlebih Dahulu !");
                                        setState(() {
                                          statusLoading = 0;
                                        });
                                      } else {
                                        PresensiLokasiPost.connectToApi(
                                                prefs.getString("ID")!,
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
                                                  return DashboardScreen();
                                                },
                                              ),
                                            );
                                          }
                                          setState(() {
                                            statusLoading = 0;
                                          });
                                        });
                                      }
                                    } else {
                                      _showMyDialog("Absensi Lokasi",
                                          "Lokasi Anda Terlalu Jauh");
                                      setState(() {
                                        statusLoading = 0;
                                      });
                                    }
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
          child: Container(
            width: 50,
            child: FloatingActionButton(
              onPressed: () {
                getCurrentLocation();
                _controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      bearing: 0,
                      target: new LatLng(la, lo),
                      tilt: 30.0,
                      zoom: 18,
                    ),
                  ),
                );
                _controller
                    .getVisibleRegion()
                    .then((bounds) => print("bounds: ${bounds.toString()}"));
              },
              child: const Icon(Icons.my_location),
              backgroundColor: kPrimaryColor,
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
                child: Text('Keluar'),
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
            title: Text("FAKE GPS"),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text("HARAP UNINSTALL FAKE GPS ANDA !!!"),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('Keluar'),
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
            title: Text("PERIZINAN AKSES LOKASI"),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(
                      "Aplikasi ini mengumpulkan data lokasi untuk mengaktifkan Presensi Diluar Jam Kerja."),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: Text('OK'),
                onPressed: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.setBool("sl_lokasi", false);
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
            contentPadding: EdgeInsets.all(0),
            content: Container(
              // height: size.height * 0.6,
              margin: EdgeInsets.all(0),
              padding: EdgeInsets.all(0),
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
                child: Text('Kembali', style: TextStyle(color: CDanger)),
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

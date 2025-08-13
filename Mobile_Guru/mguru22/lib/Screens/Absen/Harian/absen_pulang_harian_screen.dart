import 'dart:async';
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

class AbsenPulangHarianScreen extends StatelessWidget {
  const AbsenPulangHarianScreen({super.key});

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
  double radius = Core().MaximalJarak;

  double la = 0;
  double lo = 0;
  int statusLoading = 0;
  String NIP = "", Nama = "", UUID = "";
  String jam = "", jam_pulang = "Belum Presensi Pulang";
  var DataAbsen, DataPegawai, DataAbsenPulang;

  late CameraController controller;
  XFile? imageFile;
  File? _image;

  bool _isMockLocation = false;
  bool bacakamera = false;

  bool ssHeader = false;

  @override
  void initState() {
    super.initState();
    getPref();
    prepareCamera();
    getCurrentLocation();
  }

  getPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    UUID = prefs.getString("ID")!;
    NIP = prefs.getString("NIP")!;
    Nama = prefs.getString("Nama")!;
    if (prefs.getDouble("LokasiLat") != null ||
        prefs.getDouble("LokasiLat")! > 0) {
      la_polije = prefs.getDouble("LokasiLat")!;
      lo_polije = prefs.getDouble("LokasiLng")!;
      radius = prefs.getDouble("Radius")!;
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
    return resBody['data']["pegawai"];
  }

  prepareCamera() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    cameras = await availableCameras();
    controller = CameraController(
      cameras[prefs.getInt("CameraSelect")!],
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

  void onTakePictureButtonPressed() async {
    final CameraController cameraController = controller;
    if (!cameraController.value.isInitialized) {
      _showMyDialog("KAMERA", "Kamera gagal mengambil Foto Anda");
    }

    if (cameraController.value.isTakingPicture) {}

    try {
      XFile file = await cameraController.takePicture();
      if (mounted) {
        setState(() {
          imageFile = file;
          _image = File(file.path);
          if (imageFile != null) {
            _image = File(file.path);
          } else {
            print('No image selected.');
            // _showMyDialog("KAMERA", "Kamera gagal mengambil Foto Anda, Mohon tunggu sistem akan membuka kembali kamera");
          }
        });
        // if (file != null) showInSnackBar('Picture saved to ${file.path}');
      }
    } on CameraException catch (e) {
      print("error Camera :");
      print(e);
      getCameraEx();
    }
  }

  getCurrentLocation() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs.getBool("sl_harian_pulang")!) {
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
      ssHeader = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Scaffold(
        body: Stack(children: <Widget>[
      if (!ssHeader)
        const Center(
          child: CircularProgressIndicator(),
        ),
      if (ssHeader)
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
          mapType: MapType.normal,
          circles: {
            Circle(
                circleId: const CircleId("Area Polije"),
                center: LatLng(la_polije, lo_polije),
                radius: radius,
                strokeWidth: 2,
                strokeColor: Colors.blue,
                fillColor: Colors.blue.withOpacity(0.2))
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
          child: AnimatedOpacity(
        opacity: ssHeader ? 1 : 0,
        duration: const Duration(milliseconds: 500),
        child: AnimatedContainer(
          padding: const EdgeInsets.only(
              left: 20.0, right: 20.0, bottom: 10.0, top: 40.0),
          margin: ssHeader ? const EdgeInsets.only(top: 0) : const EdgeInsets.only(top: 30),
          duration: const Duration(milliseconds: 500),
          curve: Curves.fastEaseInToSlowEaseOut,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: 18),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    width: size.width,
                    decoration: BoxDecoration(
                      color: Colors.white70,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.white70,
                          blurRadius: 4,
                          offset: Offset(2, 4), // Shadow position
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          Nama,
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: CText),
                        ),
                        Text(
                          (NIP == "") ? "-" : NIP,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: CText),
                        )
                      ],
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      )),
      Positioned(
          bottom: 60,
          width: size.width,
          child: AnimatedOpacity(
              opacity: ssHeader ? 1 : 0,
              duration: const Duration(milliseconds: 500),
              child: AnimatedContainer(
                  margin: ssHeader
                      ? const EdgeInsets.only(bottom: 0)
                      : const EdgeInsets.only(bottom: 30),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.fastEaseInToSlowEaseOut,
                  child: Container(
                    margin: const EdgeInsets.only(left: 10.0, right: 10.0),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.white70,
                          blurRadius: 4,
                          offset: Offset(2, 4), // Shadow position
                        ),
                      ],
                    ),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: [
                            Expanded(
                                flex: 1,
                                child: TextButton(
                                    onPressed: () {
                                      if (bacakamera) {
                                        _popCamera();
                                      } else {
                                        getCameraEx();
                                      }
                                    },
                                    child: Container(
                                      height: 100,
                                      width: size.width,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: Colors.black,
                                        borderRadius: BorderRadius.circular(12),
                                        image: DecorationImage(
                                          image: (_image == null)
                                              ? const AssetImage(
                                                  'assets/images/user_image.png')
                                              : Image.file(_image!).image,
                                          fit: BoxFit.fill,
                                        ),
                                      ),
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                            color: Colors.white60,
                                            borderRadius:
                                                BorderRadius.circular(4)),
                                        child: const Text('Ambil Foto',
                                            style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.black)),
                                      ),
                                    ))),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    bottom: 5, top: 8, right: 0),
                                child: Column(
                                  children: <Widget>[
                                    Text(
                                      "Jarak Kantor : ${Jarak.toInt()} Meter",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Jarak.toInt() < radius
                                              ? CSuccess
                                              : CDanger),
                                    ),
                                    Text(
                                      Jarak.toInt() < radius
                                          ? "Anda Dalam Jangkuan"
                                          : "Anda Tidak Dalam Wilayah",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Jarak.toInt() < radius
                                              ? CSuccess
                                              : CDanger),
                                    )
                                  ],
                                ),
                              ),
                            )
                          ],
                        ),
                      ],
                    ),
                  )))),
      Positioned(
          bottom: 8,
          width: size.width,
          child: AnimatedOpacity(
              opacity: ssHeader ? 1 : 0,
              duration: const Duration(milliseconds: 500),
              child: AnimatedContainer(
                margin: ssHeader
                    ? const EdgeInsets.only(bottom: 0)
                    : const EdgeInsets.only(bottom: 30),
                duration: const Duration(milliseconds: 500),
                curve: Curves.fastEaseInToSlowEaseOut,
                // color: kDarkPrimaryColor,
                child: (statusLoading == 1)
                    ? const CircularProgressIndicator()
                    : RoundedButtonSmall(
                        text: "PRESENSI PULANG",
                        width: size.width * 0.9,
                        color: Jarak.toInt() < radius
                            ? kPrimaryColor
                            : Colors.blueGrey,
                        press: () async {
                          setState(() {
                            statusLoading = 1;
                          });
                          SharedPreferences prefs =
                              await SharedPreferences.getInstance();
                          if (prefs.getInt("status_spesial") == 1) {
                            if (_image == null) {
                              _showMyDialog("Absensi Pulang Harian",
                                  "Anda Belum Mengambil Foto. Mohon Ambil Foto Terlebih Dahulu !");
                              setState(() {
                                statusLoading = 0;
                              });
                            } else {
                              AbsenSelesaiPost.connectToApi(
                                      prefs.getString("ID")!,
                                      DataPegawai['idabsen'],
                                      la.toString(),
                                      lo.toString(),
                                      _image!)
                                  .then((value) {
                                if (value!.status_kode == 200) {
                                  Navigator.pushReplacement(context,
                                      MaterialPageRoute(builder: (context) {
                                    return const DashboardScreen();
                                  }));
                                } else {
                                  _showMyDialog(
                                      "Absensi Harian", value.message);
                                }
                                setState(() {
                                  statusLoading = 0;
                                });
                              });
                            }
                          } else {
                            _isMockLocation =
                                await TrustLocation.isMockLocation;
                            print("fake GPS :");
                            print(_isMockLocation);
                            print("Lokasi : $la -- $lo");
                            if (_isMockLocation == true) {
                              _showMyDialogFake();
                              setState(() {
                                statusLoading = 0;
                              });
                            } else {
                              if (Jarak.toInt() < radius) {
                                if (_image == null) {
                                  _showMyDialog("Absensi Pulang Harian",
                                      "Anda Belum Mengambil Foto. Mohon Ambil Foto Terlebih Dahulu !");
                                } else {
                                  AbsenSelesaiPost.connectToApi(
                                          prefs.getString("ID")!,
                                          DataPegawai['idabsen'],
                                          la.toString(),
                                          lo.toString(),
                                          _image!)
                                      .then((value) {
                                    if (value!.status_kode == 200) {
                                      Navigator.pushReplacement(context,
                                          MaterialPageRoute(builder: (context) {
                                        return const DashboardScreen();
                                      }));
                                    } else {
                                      _showMyDialog(
                                          "Absensi Harian", value.message);
                                      setState(() {
                                        statusLoading = 0;
                                      });
                                    }
                                    setState(() {
                                      statusLoading = 0;
                                    });
                                  });
                                }
                              } else {
                                _showMyDialog("Absensi Harian",
                                    "Lokasi Anda Terlalu Jauh");
                                setState(() {
                                  statusLoading = 0;
                                });
                              }
                            }
                          }
                        },
                      ),
              ))),
      Positioned(
          bottom: size.height * 0.19,
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
                      tilt: 45,
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
                      "Aplikasi ini mengumpulkan data lokasi untuk mengaktifkan Presensi Pulang."),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.setBool("sl_harian_pulang", false);
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

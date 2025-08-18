import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/absen_post.dart';
import 'package:mobile_presensi_kdtg/Screens/Kegiatan/absen_kegiatan_post.dart';
import 'package:mobile_presensi_kdtg/Screens/Laporan/Kegiatan/Laporan_Kegiatan_screen.dart';
import 'package:mobile_presensi_kdtg/components/rounded_button_small.dart';
import 'package:mobile_presensi_kdtg/constants.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

List<CameraDescription> cameras = [];

class AbsenKegiatanScreen extends StatefulWidget {
  final String idkegiatan;
  final double latitude, longtitude, jarak_radius;

  const AbsenKegiatanScreen({
    super.key,
    this.idkegiatan = "",
    this.latitude = 0,
    this.longtitude = 0,
    this.jarak_radius = 0,
  });

  @override
  _AbsenKegiatanScreenState createState() => _AbsenKegiatanScreenState();
}

class _AbsenKegiatanScreenState extends State<AbsenKegiatanScreen> {
  final AbsenPost absenPost = AbsenPost();

  late GoogleMapController _controller;
  double la_polije = 0;
  double lo_polije = 0;
  double Jarak = 0;
  double PembatasJarak = 50;
  int StatusAbsenKegiatan = 0;

  double la = 0;
  double lo = 0;

  String Nama = "", NIP = "";
  late SharedPreferences prefs;

  late CameraController controller;
  XFile? imageFile;
  File? _image;

  bool ssHeader = false;
  int statusLoading = 0;

  bool bacakamera = false;
  var StatusKegiatan;

  @override
  void initState() {
    super.initState();
    la_polije = widget.latitude;
    lo_polije = widget.longtitude;
    PembatasJarak = widget.jarak_radius;
    prepareCamera();
    getCurrentLocation();
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

  Future<Future> getCurrentLocation() async {
    prefs = await SharedPreferences.getInstance();
    if (prefs.getBool("sl_kegiatan")!) {
      _showPerizinan();
    }
    Nama = prefs.getString("Nama")!;
    NIP = prefs.getString("NIP")!;
    getDataDash(prefs.getString("ID")!);
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

  Future<String> getDataDash(String UUID) async {
    var res = await http.get(
        Uri.parse("${Core().ApiUrl}Kegiatan/cek_absen_kegiatan/${widget.idkegiatan}/$UUID"),
        headers: {"Accept": "application/json"});
    var resBody = json.decode(res.body);
    setState(() {
      StatusKegiatan = resBody['message'];
      StatusAbsenKegiatan = resBody['message']['status'];
      statusLoading = 0;
    });
    print(StatusAbsenKegiatan);
    return "";
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
                radius: PembatasJarak,
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
                                      "Jarak Lokasi Kegiatan : ${Jarak.toInt()} Meter",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Jarak.toInt() < PembatasJarak
                                              ? CSuccess
                                              : CDanger),
                                    ),
                                    Text(
                                      Jarak.toInt() < PembatasJarak
                                          ? "Anda Dalam Jangkuan"
                                          : "Anda Tidak Dalam Wilayah",
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Jarak.toInt() < PembatasJarak
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
                        text: StatusAbsenKegiatan == 200
                            ? "SUDAH PRESENSI KEGIATAN"
                            : "PRESENSI KEGIATAN ",
                        width: size.width * 0.9,
                        color: Jarak.toInt() < PembatasJarak
                            ? kPrimaryColor
                            : Colors.blueGrey,
                        press: () async {
                          setState(() {
                            statusLoading = 1;
                          });
                          if (StatusAbsenKegiatan == 200) {
                            _showMyDialog("Absensi Kegiatan",
                                "Anda Sudah Presensi Kegiatan Untuk Hari Ini");
                          } else {
                            if (Jarak.toInt() < PembatasJarak) {
                              if (_image == null) {
                                _showMyDialog("Absensi Kegiatan",
                                    "Anda Belum Mengambil Foto. Mohon Ambil Foto Terlebih Dahulu !");
                              } else {
                                SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                AbsenKegiatanPost.connectToApi(
                                        prefs.getString("ID")!,
                                        widget.idkegiatan,
                                        la.toString(),
                                        lo.toString(),
                                        "1",
                                        _image!)
                                    .then((value) {
                                  if (value!.status_kode == 200) {
                                    Navigator.of(context).pop();
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) {
                                          return const LaporanKegiatanScreen();
                                        },
                                      ),
                                    );
                                  } else {
                                    _showMyDialog(
                                        "Absensi Kegiatan", value.message);
                                  }
                                });
                              }
                            } else {
                              _showMyDialog("Absensi Kegiatan",
                                  "Lokasi Anda Terlalu Jauh");
                            }
                          }
                          setState(() {
                            statusLoading = 0;
                          });
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
                      "Aplikasi ini mengumpulkan data lokasi untuk mengaktifkan Presensi Kegiatan."),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.setBool("sl_kegiatan", false);
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

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/absen_post.dart';
import 'package:mobile_presensi_kdtg/Screens/Login/components/body.dart';
import 'package:mobile_presensi_kdtg/components/rounded_button.dart';
import 'package:mobile_presensi_kdtg/components/rounded_button_small.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_presensi_kdtg/components/text_style.dart';
import 'package:mobile_presensi_kdtg/components/or_divider.dart';

class AbsenScreen extends StatelessWidget {
  const AbsenScreen({super.key});

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
  double la_polije = -8.1594718;
  double lo_polije = 113.720271;
  double Jarak = 0;

  double la = 0;
  double lo = 0;

  @override
  void initState() {
    super.initState();
    // la = 1;
    getCurrentLocation();
  }

  late File _image;
  final picker = ImagePicker();
  Future getImage() async {
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

  getCurrentLocation() async {
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
              infoWindow: const InfoWindow(
                title: 'PlatformMarker',
                snippet: "Hi I'm a Platform Marker",
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
          bottom: 10,
          width: size.width * 0.85,
          child: Container(
            margin: const EdgeInsets.only(left: 10.0, right: 10.0, bottom: 0.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              color: Colors.white,
              // elevation: 10,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Row(
                    children: [
                      (_image == null)
                          ? Container(
                              margin: const EdgeInsets.only(
                                  left: 10.0, right: 10.0, top: 10.0),
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
                                  left: 10.0, right: 10.0, top: 10.0),
                              child:
                                  Image.file(_image, width: 70, height: 100)),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 5, top: 10, right: 0),
                        child: Column(
                          children: <Widget>[
                            const Text(
                              'Elsa Manora Ramadania',
                              style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            const Text(
                              '082128767898',
                              style:
                                  TextStyle(fontSize: 15, color: Colors.blue),
                            ),
                            const SizedBox(
                              height: 5,
                            ),
                            const Text("Jarak Anda Menuju Kantor : "),
                            const SizedBox(
                              height: 5,
                            ),
                            Text("${Jarak.toInt()} Meter",
                                style: keterangan),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Positioned(
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                        ElevatedButton(
                          onPressed: getImage,
                          child: const Text("Ambil Foto"),
                        ),
                        RoundedButtonSmall(
                          text: "Upload",
                          press: () {},
                        ),
                      ])),
                ],
              ),
            ),
          )),
    ]));
  }
}

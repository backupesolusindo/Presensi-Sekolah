import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/absen_post.dart';
import 'package:mobile_presensi_kdtg/Screens/dashboard_screen.dart';
import 'package:mobile_presensi_kdtg/components/rounded_button_small.dart';
import 'package:mobile_presensi_kdtg/constants.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_presensi_kdtg/services/location_services.dart';

List<CameraDescription> cameras = [];

class AbsenHarianScreen extends StatefulWidget {
  const AbsenHarianScreen({super.key});

  @override
  _AbsenHarianScreenState createState() => _AbsenHarianScreenState();
}

class _AbsenHarianScreenState extends State<AbsenHarianScreen> {
  final AbsenPost absenPost = AbsenPost();

  late GoogleMapController _controller;
  double la_polije = -8.1594718;
  double lo_polije = 113.720271;
  double Jarak = 0;
  double radius = Core().MaximalJarak;
  double la = 0;
  double lo = 0;
  bool _isMockLocation = false;
  int statusLoading = 0;
  late String Nama = "", NIP = "", JamMasuk = "", idJadwal = "";
  late SharedPreferences prefs;
  String coba = "asd";
  bool ssHeader = false;

  List DataJadwal = List.empty();

  @override
  void initState() {
    super.initState();
    getDataPegawai();
    getCurrentLocation();
  }

  Future<void> getDataPegawai() async {
    prefs = await SharedPreferences.getInstance();
    String UUID = prefs.getString("ID")!;
    var res = await http.get(
        Uri.parse("${Core().ApiUrl}Dash/set_jadwal/$UUID"),
        headers: {"Accept": "application/json"});
    var resBody = json.decode(res.body);
    setState(() {
      DataJadwal = resBody['data']["jadwal"];
      JamMasuk = DataJadwal[0]['jam_masuk'].toString();
      idJadwal = DataJadwal[0]['idjadwal_masuk'].toString();
    });
    print(resBody);
  }

  Future<dynamic> getCurrentLocation() async {
    prefs = await SharedPreferences.getInstance();
    if (prefs.getBool("sl_harian_masuk")!) {
      _showPerizinan();
    }
    _isMockLocation = await LocationService.isMockLocation;
    print("fake GPS :");
    print(_isMockLocation);
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
      // Jarak = 10;
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
          myLocationEnabled: true,
          initialCameraPosition: CameraPosition(
            target: LatLng(la, lo),
            zoom: 10.0,
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
          onMapCreated: (GoogleMapController controller) {
            _controller = controller;
            Future.delayed(const Duration(seconds: 2)).then(
              (_) {
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      bearing: 0,
                      target: LatLng(la, lo),
                      tilt: 45,
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
          bottom: 80,
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
                    margin: const EdgeInsets.only(left: 20.0, right: 20.0),
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
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: <Widget>[
                          Text(
                            Jarak.toInt() < radius
                                ? "Anda Dalam Jangkuan"
                                : "Anda Tidak Dalam Wilayah",
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Jarak.toInt() < radius
                                    ? CSuccess
                                    : CDanger),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 8),
                            child: DropdownButton(
                              hint: const Text("Jadwal Kerja : ",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black)),
                              dropdownColor: Colors.white,
                              icon: const Icon(Icons.arrow_drop_down),
                              iconSize: 24,
                              isExpanded: true,
                              style: const TextStyle(
                                  color: Colors.black, fontSize: 12),
                              items: DataJadwal.map((item) {
                                return DropdownMenuItem(
                                  value: item['idjadwal_masuk']
                                      .toString(),
                                  child: Text(item['nama']),
                                );
                              }).toList(),
                              onChanged: (newVal) {
                                setState(() {
                                  idJadwal = newVal as String;
                                  for (var i = 0;
                                      i < DataJadwal.length;
                                      i++) {
                                    if (DataJadwal[i]
                                            ['idjadwal_masuk'] ==
                                        idJadwal) {
                                      JamMasuk =
                                          DataJadwal[i]['jam_masuk'];
                                    }
                                  }
                                  print("Jam $JamMasuk");
                                });
                              },
                              value: idJadwal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )))),
      Positioned(
          bottom: 20,
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
                    ? const Center(child: CircularProgressIndicator())
                    : RoundedButtonSmall(
                        text: "PRESENSI MASUK",
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
                            // Special status - direct attendance without photo
                            AbsenPost.connectToApiNoPhoto(
                                    prefs.getString("ID")!,
                                    la.toString(),
                                    lo.toString(),
                                    "1",
                                    "1",
                                    idJadwal,
                                    JamMasuk)
                                .then((value) {
                              if (value!.status_kode == 200) {
                                _showMyDialogSuccess("Presensi Berhasil", "Anda sudah berhasil melakukan presensi masuk.");
                              } else {
                                _showMyDialog(
                                    "Absensi Harian", value.message);
                              }
                              setState(() {
                                statusLoading = 0;
                              });
                            });
                          } else {
                            _isMockLocation =
                                await LocationService.isMockLocation;
                            print("fake GPS :");
                            print(_isMockLocation);
                            if (_isMockLocation == true) {
                              _showMyDialogFake();
                              setState(() {
                                statusLoading = 0;
                              });
                            } else {
                              if (Jarak.toInt() < radius) {
                                // Normal attendance without photo requirement
                                AbsenPost.connectToApiNoPhoto(
                                        prefs.getString("ID")!,
                                        la.toString(),
                                        lo.toString(),
                                        "1",
                                        "1",
                                        idJadwal,
                                        JamMasuk)
                                    .then((value) {
                                  if (value!.status_kode == 200) {
                                    _showMyDialogSuccess("Presensi Berhasil", "Anda sudah berhasil melakukan presensi masuk.");
                                  } else {
                                    _showMyDialog(
                                        "Absensi Harian", value.message);
                                  }
                                  setState(() {
                                    statusLoading = 0;
                                  });
                                });
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
          bottom: size.height * 0.24,
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
                child: const Text('Oke'),
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
                  // exit(0);
                },
              ),
            ],
          ),
        );
      },
    );
  }
  
  // FUNGSI BARU UNTUK DIALOG SUKSES
  Future<void> _showMyDialogSuccess(String title, String message) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: AlertDialog(
            title: Text(title),
            content: SingleChildScrollView(
              child: ListBody(
                children: <Widget>[
                  Text(message),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('Oke'),
                onPressed: () {
                  // Tutup dialog terlebih dahulu
                  Navigator.of(context).pop();
                  // Kemudian navigasi ke Dashboard
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (context) {
                    return const DashboardScreen();
                  }));
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
                      "Aplikasi ini mengumpulkan data lokasi untuk mengaktifkan Presensi Masuk."),
                ],
              ),
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () async {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.setBool("sl_harian_masuk", false);
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
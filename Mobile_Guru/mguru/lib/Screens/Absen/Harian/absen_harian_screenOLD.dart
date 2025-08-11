import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
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
import 'package:http/http.dart' as http;

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
  late String Nama = "", NIP = "", JamMasuk, idJadwal;
  late SharedPreferences prefs;

  List DataJadwal = [];
  // _AbsenHarianScreenState(){
  //   // getDataPegawai();
  // }

  @override
  void initState() {
    super.initState();

    getCurrentLocation();
    getDataPegawai();
  }

  getDataPegawai() async {
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

  File? _image;
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
    prefs = await SharedPreferences.getInstance();
    if (prefs.getBool("sl_harian_masuk")!) {
      _showPerizinan();
    }
    _isMockLocation = await TrustLocation.isMockLocation;
    print("fake GPS :");
    print(_isMockLocation);
    Nama = prefs.getString("Nama")!;
    NIP = prefs.getString("NIP")!;
    if (prefs.getDouble("LokasiLat") != null ||
        prefs.getDouble("LokasiLat")! > 0) {
      la_polije = prefs.getDouble("LokasiLat")!;
      lo_polije = prefs.getDouble("LokasiLng")!;
      radius = prefs.getDouble("Radius")!;
    }

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
        circles: {
          Circle(
              circleId: const CircleId("Area Polije"),
              center: LatLng(la_polije, lo_polije),
              radius: radius,
              strokeWidth: 2,
              strokeColor: Colors.blue,
              fillColor: Colors.blue.withOpacity(0.2))
        },
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
        onMapCreated: (GoogleMapController controller) {
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
                                child: Image.file(_image!,
                                    width: 80, height: 140)),
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0, right: 4.0),
                          child: TextButton(
                            onPressed: getImage,
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
                            Text(
                              Jarak.toInt() < radius
                                  ? "Anda Dalam Jangkuan"
                                  : "Anda Tidak Dalam Wilayah",
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Jarak.toInt() < radius
                                      ? CSuccess
                                      : CDanger),
                            ),
                            Container(
                              width: size.width * 0.4,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: DropdownButton(
                                hint: const Text("Jadwal Kerja : "),
                                dropdownColor: Colors.white,
                                icon: const Icon(Icons.arrow_drop_down),
                                iconSize: 24,
                                isExpanded: true,
                                style: const TextStyle(
                                    color: Colors.black, fontSize: 12),
                                items: DataJadwal.map((item) {
                                  return DropdownMenuItem(
                                    value: item['idjadwal_masuk'].toString(),
                                    child: Text(item['nama']),
                                  );
                                }).toList(),
                                onChanged: (newVal) {
                                  setState(() {
                                    idJadwal = newVal as String;
                                    for (var i = 0;
                                        i < DataJadwal.length;
                                        i++) {
                                      if (DataJadwal[i]['idjadwal_masuk'] ==
                                          idJadwal) {
                                        JamMasuk = DataJadwal[i]['jam_masuk'];
                                      }
                                    }
                                    print("Jam $JamMasuk");
                                  });
                                },
                                value: idJadwal,
                              ),
                            ),
                            if (statusLoading == 1) const CircularProgressIndicator(),
                            if (statusLoading == 0)
                              RoundedButtonSmall(
                                text: "PRESENSI MASUK",
                                color: Jarak.toInt() < radius
                                    ? kPrimaryColor
                                    : ColorLight,
                                press: () async {
                                  setState(() {
                                    statusLoading = 1;
                                  });
                                  SharedPreferences prefs =
                                      await SharedPreferences.getInstance();
                                  if (prefs.getInt("status_spesial") == 1) {
                                    if (_image == null) {
                                      _showMyDialog("Absensi Harian",
                                          "Anda Belum Mengambil Foto. Mohon Ambil Foto Terlebih Dahulu !");
                                    } else {
                                      AbsenPost.connectToApi(
                                              prefs.getString("ID")!,
                                              la.toString(),
                                              lo.toString(),
                                              "1",
                                              "1",
                                              idJadwal,
                                              JamMasuk,
                                              _image!)
                                          .then((value) {
                                        if (value!.status_kode == 200) {
                                          Navigator.pushReplacement(context,
                                              MaterialPageRoute(
                                                  builder: (context) {
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
                                    if (_isMockLocation == true) {
                                      _showMyDialogFake();
                                      setState(() {
                                        statusLoading = 0;
                                      });
                                    } else {
                                      if (Jarak.toInt() < radius) {
                                        if (_image == null) {
                                          _showMyDialog("Absensi Harian",
                                              "Anda Belum Mengambil Foto. Mohon Ambil Foto Terlebih Dahulu !");
                                          setState(() {
                                            statusLoading = 0;
                                          });
                                        } else {
                                          AbsenPost.connectToApi(
                                                  prefs.getString("ID")!,
                                                  la.toString(),
                                                  lo.toString(),
                                                  "1",
                                                  "1",
                                                  idJadwal,
                                                  JamMasuk,
                                                  _image!)
                                              .then((value) {
                                            if (value!.status_kode == 200) {
                                              Navigator.pushReplacement(context,
                                                  MaterialPageRoute(
                                                      builder: (context) {
                                                return const DashboardScreen();
                                              }));
                                            } else {
                                              _showMyDialog("Absensi Harian",
                                                  value.message);
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
          bottom: size.height * 0.17,
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
                  // exit(0);
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

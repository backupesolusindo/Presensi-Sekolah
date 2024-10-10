import 'dart:async';
import 'dart:convert';
import 'dart:ui';

import 'package:date_format/date_format.dart';
import 'package:flutter/material.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/Harian/absen_harian_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/Harian/absen_pulang_harian_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/Istirahat/absen_istirahat_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/Istirahat/absen_selesai_istirahat_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/PresensiLokasi/presensi_lokasi_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/WorkFrom/absen_selesai_wf_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/WorkFrom/absen_wf_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Absen/absen_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/JadwalWF/list_jadwalwf_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Kegiatan/ListKegiatan_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Laporan/Kegiatan/Laporan_Kegiatan_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Laporan/Lembur/Laporan_Lembur_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Laporan/LuarJam/Laporan_LuarJam_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Laporan/Perizinan/Laporan_Perizinan_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Laporan/Presensi/Laporan_Presensi_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Lembur/ListLembur_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/LokasiKampus/lokasi_kampus_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Perizinan/izin_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Profil/profil_user.dart';
import 'package:mobile_presensi_kdtg/Screens/ResetPassword/reset_password.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'package:mobile_presensi_kdtg/components/or_divider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'Camera/Camera_screen.dart';

class SemuaMenu extends StatefulWidget {
  @override
  _SemuaMenu createState() => _SemuaMenu();
}

class _SemuaMenu extends State<SemuaMenu> {
  String NIP = "", Nama = "", UUID = "";
  String jam = "", jam_pulang = "Belum Presensi Pulang";
  var DataAbsen,
      DataPegawai,
      DataAbsenPulang,
      DataIstirahat,
      DataSelesaiIstirahat,
      DataDinasLuar;
  int StatusDinasLuar = 1;
  int JenisAbsen = 0;
  double width_menu = 90;
  int status_lintashari = 0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getPref();
    Timer.periodic(Duration(seconds: 1), (Timer t) => _getTime());
  }

  _getTime() {
    setState(() {
      jam = formatDate(DateTime.now(), [hh, ':', nn, ':', ss]);
    });
  }

  getPref() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    UUID = prefs.getString("ID")!;
    NIP = prefs.getString("NIP")!;
    Nama = prefs.getString("Nama")!;
    print("Login Pref :" + UUID);
    getDataDash();
  }

  Future<String> getDataDash() async {
    print("getJenis");
    var res = await http.get(Uri.parse(Core().ApiUrl + "Dash/get_dash/" + UUID),
        headers: {"Accept": "application/json"});
    var resBody = json.decode(res.body);
    print(resBody);
    setState(() {
      DataPegawai = resBody['data']["pegawai"];
      DataAbsen = resBody['data']["absen"];
      DataAbsenPulang = resBody['data']["absensi_pulang"];
      DataIstirahat = resBody['data']["istirahat"];
      DataSelesaiIstirahat = resBody['data']["selesai_istirahat"];
      DataDinasLuar = resBody['data']["dinasluar"];
      StatusDinasLuar = int.parse(DataDinasLuar['status']);
      if (DataAbsen != null) {
        JenisAbsen = int.parse(DataAbsen["jenis_absen"]);
      }
      print("Jenis Absens : " + JenisAbsen.toString());
      print("Dinas Luar : " + StatusDinasLuar.toString());
      if (DataAbsenPulang != null) {
        jam_pulang = formatDate(
            DateTime.parse(DataAbsenPulang['waktu']), [hh, ':', nn, ':', ss]);
      }
      if (resBody['data']["jabatan"]["lintas_hari"] != null) {
        status_lintashari =
            int.parse(resBody['data']["jabatan"]["lintas_hari"]);
      }
    });
    return "";
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Semua Menu",
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
          ),
        ),
        leading: GestureDetector(
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.white, // add custom icons also
          ),
        ),
      ),
      body: CustomScrollView(
        physics: ClampingScrollPhysics(),
        slivers: <Widget>[
          _presensi(screenHeight),
          _perijinan(screenHeight),
          _Laporan(screenHeight),
          _profileUser(screenHeight),
        ],
      ),
    );
  }

  // Menu Presensi
  SliverToBoxAdapter _presensi(double screenHeight) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.only(left: 15.0, top: 15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Menu Presensi',
              style: const TextStyle(
                fontSize: 15.0,
                color: Colors.lightBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10.0),
            Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
              Container(
                  width: width_menu,
                  child: TextButton(
                      onPressed: () {
                        if (JenisAbsen == 0 || JenisAbsen == 1) {
                          if (StatusDinasLuar == 1) {
                            if (DataAbsen == null) {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return AbsenHarianScreen();
                              }));
                            } else {
                              if (DataAbsenPulang == null) {
                                _showMyDialog("Presensi Harian",
                                    "Anda belum melakukan Presensi Pulang Harian. Silakan Presensi Pulang Harian terlebih dahulu !",
                                    MaterialPageRoute(builder: (context) {
                                  return AbsenPulangHarianScreen();
                                }));
                              } else {
                                if (status_lintashari == 1) {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return AbsenHarianScreen();
                                  }));
                                } else {
                                  _showNotif("Presensi Harian",
                                      "Anda Sudah Melakukan Presensi Hari ini");
                                }
                              }
                            }
                          } else {
                            _showNotif("Presensi Harian",
                                "Anda Dilarang Melakukan Presensi Karena Sedang Dinas Luar");
                          }
                        }
                      },
                      // minWidth: 0,
                      child: Column(
                        children: <Widget>[
                          Image.asset(
                            ((JenisAbsen == 0 || JenisAbsen == 1) &&
                                    StatusDinasLuar == 1)
                                ? "assets/icons/presensi_datang_warna.png"
                                : "assets/icons/presensi_datang_monokrom.png",
                            height: screenHeight * 0.07,
                          ),
                          SizedBox(height: screenHeight * 0.003),
                          Text(
                            "Presensi\nMasuk",
                            style: const TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ))),
              Container(
                  width: width_menu,
                  child: TextButton(
                      onPressed: () {
                        if (JenisAbsen == 0 || JenisAbsen == 1) {
                          if (StatusDinasLuar == 1) {
                            if (DataAbsen == null) {
                              _showMyDialog("Presensi Harian",
                                  "Anda belum melakukan Presensi Harian. Silakan Presensi Harian terlebih dahulu !",
                                  MaterialPageRoute(builder: (context) {
                                return AbsenHarianScreen();
                              }));
                            } else {
                              if (DataAbsenPulang == null) {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return AbsenPulangHarianScreen();
                                }));
                              } else {
                                _showMyDialog("Presensi Harian",
                                    "Apakah Anda Memperbarui Pulang Sebelumnya ?",
                                    MaterialPageRoute(builder: (context) {
                                  return AbsenPulangHarianScreen();
                                }));
                              }
                            }
                          } else {
                            _showNotif("Presensi Harian",
                                "Anda Dilarang Melakukan Presensi Karena Sedang Dinas Luar");
                          }
                        }
                      },
                      // minWidth: 0,
                      child: Column(
                        children: <Widget>[
                          Image.asset(
                            ((JenisAbsen == 0 || JenisAbsen == 1) &&
                                    StatusDinasLuar == 1)
                                ? "assets/icons/presensi_pulang_warna.png"
                                : "assets/icons/presensi_pulang_monokrom.png",
                            height: screenHeight * 0.07,
                          ),
                          SizedBox(height: screenHeight * 0.003),
                          Text(
                            "Presensi\nPulang",
                            style: const TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ))),
            //   Container(
            //       width: width_menu,
            //       child: TextButton(
            //           onPressed: () {
            //             if (DataIstirahat == null) {
            //               Navigator.push(context,
            //                   MaterialPageRoute(builder: (context) {
            //                 return AbsenIstirahatScreen();
            //               }));
            //             } else {
            //               _showMyDialog("Presensi Istirahat",
            //                   "Anda belum melakukan Presensi Selesai Istirahat. Silakan Presensi Selesai Istirahat terlebih dahulu !",
            //                   MaterialPageRoute(builder: (context) {
            //                 return AbsenSelesaiIstirahatScreen();
            //               }));
            //             }
            //           },
            //           // minWidth: 0,
            //           child: Column(
            //             children: <Widget>[
            //               Image.asset(
            //                 "assets/icons/istirahat_keluar_warna.png",
            //                 height: screenHeight * 0.07,
            //               ),
            //               SizedBox(height: screenHeight * 0.003),
            //               Text(
            //                 "Istirahat Keluar",
            //                 style: const TextStyle(
            //                   fontSize: 11.0,
            //                   fontWeight: FontWeight.w500,
            //                 ),
            //                 textAlign: TextAlign.center,
            //               )
            //             ],
            //           ))),
            //   Container(
            //       width: width_menu,
            //       child: TextButton(
            //           onPressed: () {
            //             if (DataIstirahat == null) {
            //               _showMyDialog("Presensi Istirahat",
            //                   "Anda belum melakukan Presensi Istirahat. Silakan Presensi Istirahat terlebih dahulu !",
            //                   MaterialPageRoute(builder: (context) {
            //                 return AbsenIstirahatScreen();
            //               }));
            //             } else {
            //               Navigator.push(context,
            //                   MaterialPageRoute(builder: (context) {
            //                 return AbsenSelesaiIstirahatScreen();
            //               }));
            //             }
            //           },
            //           // minWidth: 0,
            //           child: Column(
            //             children: <Widget>[
            //               Image.asset(
            //                 "assets/icons/istirahat_masuk_warna.png",
            //                 height: screenHeight * 0.07,
            //               ),
            //               SizedBox(height: screenHeight * 0.003),
            //               Text(
            //                 "Istirahat Masuk",
            //                 style: const TextStyle(
            //                   fontSize: 11.0,
            //                   fontWeight: FontWeight.w500,
            //                 ),
            //                 textAlign: TextAlign.center,
            //               )
            //             ],
            //           ))),
            // ]),
            // SizedBox(height: 15.0),
            // Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
            //   Container(
            //       width: width_menu,
            //       child: TextButton(
            //           onPressed: () {
            //             if (JenisAbsen == 0 || JenisAbsen == 4) {
            //               if (StatusDinasLuar == 1) {
            //                 if (DataAbsen == null) {
            //                   Navigator.push(context,
            //                       MaterialPageRoute(builder: (context) {
            //                     return AbsenWFScreen();
            //                   }));
            //                 } else {
            //                   if (DataAbsenPulang == null) {
            //                     _showMyDialog("Presensi WFH",
            //                         "Anda belum melakukan Presensi Selesai WFH. Silakan Presensi Selesai WFH terlebih dahulu !",
            //                         MaterialPageRoute(builder: (context) {
            //                       return AbsenSelesaiWFScreen();
            //                     }));
            //                   } else {
            //                     _showNotif("Presensi WFH",
            //                         "Anda Sudah Melakukan Presensi WFH");
            //                   }
            //                 }
            //               } else {
            //                 _showNotif("Presensi WFH",
            //                     "Anda Dilarang Melakukan Presensi Karena Sedang Dinas Luar");
            //               }
            //             }
            //           },
            //           // minWidth: 0,
            //           child: Column(
            //             children: <Widget>[
            //               Image.asset(
            //                 ((JenisAbsen == 0 || JenisAbsen == 4) &&
            //                         StatusDinasLuar == 1)
            //                     ? "assets/icons/mulai_wfh_warna.png"
            //                     : "assets/icons/mulai_wfh_monokrom.png",
            //                 height: screenHeight * 0.07,
            //               ),
            //               SizedBox(height: screenHeight * 0.003),
            //               Text(
            //                 "Mulai WFH",
            //                 style: const TextStyle(
            //                   fontSize: 11.0,
            //                   fontWeight: FontWeight.w500,
            //                 ),
            //                 textAlign: TextAlign.center,
            //               )
            //             ],
            //           ))),
            //   Container(
            //       width: width_menu,
            //       child: TextButton(
            //           onPressed: () {
            //             if (JenisAbsen == 0 || JenisAbsen == 4) {
            //               if (StatusDinasLuar == 1) {
            //                 if (DataAbsen == null) {
            //                   _showMyDialog("Presensi WFH",
            //                       "Anda belum melakukan Presensi WFH. Silakan Presensi WFH terlebih dahulu !",
            //                       MaterialPageRoute(builder: (context) {
            //                     return AbsenWFScreen();
            //                   }));
            //                 } else {
            //                   if (DataAbsenPulang == null) {
            //                     Navigator.push(context,
            //                         MaterialPageRoute(builder: (context) {
            //                       return AbsenSelesaiWFScreen();
            //                     }));
            //                   } else {
            //                     _showMyDialog("Presensi WFH",
            //                         "Apakah Anda Memperbarui Pulang Sebelumnya ?",
            //                         MaterialPageRoute(builder: (context) {
            //                       return AbsenSelesaiWFScreen();
            //                     }));
            //                   }
            //                 }
            //               } else {
            //                 _showNotif("Presensi WFH",
            //                     "Anda Dilarang Melakukan Presensi Karena Sedang Dinas Luar");
            //               }
            //             }
            //           },
            //           // minWidth: 0,
            //           child: Column(
            //             children: <Widget>[
            //               Image.asset(
            //                 ((JenisAbsen == 0 || JenisAbsen == 4) &&
            //                         StatusDinasLuar == 1)
            //                     ? "assets/icons/selesai_wfh_warna.png"
            //                     : "assets/icons/selesai_wfh_monokrom.png",
            //                 height: screenHeight * 0.07,
            //               ),
            //               SizedBox(height: screenHeight * 0.003),
            //               Text(
            //                 "Selesai WFH",
            //                 style: const TextStyle(
            //                   fontSize: 11.0,
            //                   fontWeight: FontWeight.w500,
            //                 ),
            //                 textAlign: TextAlign.center,
            //               )
            //             ],
            //           ))),
            //   Container(
            //       width: width_menu,
            //       child: TextButton(
            //           onPressed: () {
            //             Navigator.push(context,
            //                 MaterialPageRoute(builder: (context) {
            //               return ListKegiatanScreen();
            //             }));
            //           },
            //           // minWidth: 0,
            //           child: Column(
            //             children: <Widget>[
            //               Image.asset(
            //                 "assets/icons/kegiatan.png",
            //                 height: screenHeight * 0.07,
            //               ),
            //               SizedBox(height: screenHeight * 0.003),
            //               Text(
            //                 "Presensi Kegiatan",
            //                 style: const TextStyle(
            //                   fontSize: 11.0,
            //                   fontWeight: FontWeight.w500,
            //                 ),
            //                 textAlign: TextAlign.center,
            //               )
            //             ],
            //           ))),
            //   Container(
            //       width: width_menu,
            //       child: TextButton(
            //           onPressed: () {
            //             if (StatusDinasLuar == 1) {
            //               Navigator.push(context,
            //                   MaterialPageRoute(builder: (context) {
            //                 return ListLemburScreen();
            //               }));
            //             } else {
            //               _showNotif("Presensi WFH",
            //                   "Anda Dilarang Melakukan Presensi Karena Sedang Dinas Luar");
            //             }
            //           },
            //           // minWidth: 0,
            //           child: Column(
            //             children: <Widget>[
            //               Image.asset(
            //                 (StatusDinasLuar == 1)
            //                     ? "assets/icons/lembur_warna.png"
            //                     : "assets/icons/lembur_monokrom.png",
            //                 height: screenHeight * 0.07,
            //               ),
            //               SizedBox(height: screenHeight * 0.003),
            //               Text(
            //                 "Presensi Lembur",
            //                 style: const TextStyle(
            //                   fontSize: 11.0,
            //                   fontWeight: FontWeight.w500,
            //                 ),
            //                 textAlign: TextAlign.center,
            //               )
            //             ],
            //           ))),
              // Container(
              //     width: width_menu,
              //     child: TextButton(onPressed: (){
              //       Navigator.push(context,MaterialPageRoute(builder: (context) {return PresensiLokasiScreen();}));
              //     },
              //         // minWidth: 0,
              //         child: Column(
              //           children: <Widget>[
              //             Image.asset(
              //               "assets/icons/kerja_luar.png",
              //               height: screenHeight * 0.06,
              //             ),
              //             SizedBox(height: screenHeight * 0.003),
              //             Text(
              //               "Presensi Di Luar Jam Kerja",
              //               style: const TextStyle(
              //                 fontSize: 10.0,
              //                 fontWeight: FontWeight.w500,
              //               ),
              //               textAlign: TextAlign.center,
              //             )
              //           ],
              //         )
              //     )),
            ]),
            SizedBox(height: 15.0),
          ],
        ),
      ),
    );
  }

  // Menu perijinan
  SliverToBoxAdapter _perijinan(double screenHeight) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.only(left: 15.0, top: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            OrDivider(),
            Text(
              'Menu Cuti',
              style: const TextStyle(
                fontSize: 15.0,
                color: Colors.lightBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10.0),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Container(
                      width: width_menu,
                      child: TextButton(
                          onPressed: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return IzinScreen();
                            }));
                          },
                          // minWidth: 0,
                          child: Column(
                            children: <Widget>[
                              Image.asset(
                                "assets/icons/cuti_pegawai.png",
                                height: screenHeight * 0.07,
                              ),
                              SizedBox(height: screenHeight * 0.003),
                              Text(
                                "Cuti Pegawai",
                                style: const TextStyle(
                                  fontSize: 11.0,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              )
                            ],
                          ))),
                ]),
          ],
        ),
      ),
    );
  }

  // Menu Laporan
  SliverToBoxAdapter _Laporan(double screenHeight) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.only(left: 15.0, top: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            OrDivider(),
            Text(
              'Menu Laporan',
              style: const TextStyle(
                fontSize: 15.0,
                color: Colors.lightBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10.0),
            Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
              Container(
                  width: width_menu,
                  child: TextButton(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return LaporanCutiScreen();
                        }));
                      },
                      // minWidth: 0,
                      child: Column(
                        children: <Widget>[
                          Image.asset(
                            "assets/icons/laporan_perijinan.png",
                            height: screenHeight * 0.07,
                          ),
                          SizedBox(height: screenHeight * 0.003),
                          Text(
                            "Laporan\nCuti",
                            style: const TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ))),
              Container(
                  width: width_menu,
                  child: TextButton(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return LaporanPresensiScreen();
                        }));
                      },
                      // minWidth: 0,
                      child: Column(
                        children: <Widget>[
                          Image.asset(
                            "assets/icons/laporan_presensi.png",
                            height: screenHeight * 0.07,
                          ),
                          SizedBox(height: screenHeight * 0.003),
                          Text(
                            "Laporan\nPresensi",
                            style: const TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ))),
              // Container(
              //     width: width_menu,
              //     child: TextButton(
              //         onPressed: () {
              //           Navigator.push(context,
              //               MaterialPageRoute(builder: (context) {
              //             return LaporanKegiatanScreen();
              //           }));
              //         },
              //         // minWidth: 0,
              //         child: Column(
              //           children: <Widget>[
              //             Image.asset(
              //               "assets/icons/laporan_kegiatan.png",
              //               height: screenHeight * 0.07,
              //             ),
              //             SizedBox(height: screenHeight * 0.003),
              //             Text(
              //               "Laporan\nKegiatan",
              //               style: const TextStyle(
              //                 fontSize: 11.0,
              //                 fontWeight: FontWeight.w500,
              //               ),
              //               textAlign: TextAlign.center,
              //             )
              //           ],
              //         ))),
              // Container(
              //     width: width_menu,
              //     child: TextButton(
              //         onPressed: () {
              //           Navigator.push(context,
              //               MaterialPageRoute(builder: (context) {
              //             return LaporanLemburScreen();
              //           }));
              //         },
              //         // minWidth: 0,
              //         child: Column(
              //           children: <Widget>[
              //             Image.asset(
              //               "assets/icons/kerja_luar.png",
              //               height: screenHeight * 0.07,
              //             ),
              //             SizedBox(height: screenHeight * 0.003),
              //             Text(
              //               "Laporan\nLembur",
              //               style: const TextStyle(
              //                 fontSize: 11.0,
              //                 fontWeight: FontWeight.w500,
              //               ),
              //               textAlign: TextAlign.center,
              //             )
              //           ],
              //         ))),
            ]),
            const SizedBox(height: 10.0),
          ],
        ),
      ),
    );
  }

// Menu profil user
SliverToBoxAdapter _profileUser(double screenHeight) {
  return SliverToBoxAdapter(
    child: Container(
      padding: const EdgeInsets.only(left: 15.0, top: 25.0, bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          OrDivider(),
          Text(
            'Menu Profil User',
            style: const TextStyle(
              fontSize: 15.0,
              color: Colors.lightBlue,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Mengatur posisi ikon agar lebih rapi
            children: <Widget>[
              Expanded(
                child: Container(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) {
                        return LokasiKampusScreen();
                      }));
                    },
                    child: Column(
                      children: <Widget>[
                        Image.asset(
                          "assets/icons/lokasi_kampus.png",
                          height: screenHeight * 0.07,
                        ),
                        SizedBox(height: screenHeight * 0.003),
                        Text(
                          "Lokasi\nGedung",
                          style: const TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) {
                        return ProfilUser();
                      }));
                    },
                    child: Column(
                      children: <Widget>[
                        Image.asset(
                          "assets/icons/profil_user.png",
                          height: screenHeight * 0.07,
                        ),
                        SizedBox(height: screenHeight * 0.003),
                        Text(
                          "Profil\nUser",
                          style: const TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) {
                        return ResetPasswordScreen();
                      }));
                    },
                    child: Column(
                      children: <Widget>[
                        Image.asset(
                          "assets/icons/reset_password.png",
                          height: screenHeight * 0.07,
                        ),
                        SizedBox(height: screenHeight * 0.003),
                        Text(
                          "Reset\nPassword",
                          style: const TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) {
                        return CameraScreen();
                      }));
                    },
                    child: Column(
                      children: <Widget>[
                        Image.asset(
                          "assets/icons/atur-kamera.png",
                          height: screenHeight * 0.07,
                        ),
                        SizedBox(height: screenHeight * 0.003),
                        Text(
                          "Setting\nCamera",
                          style: const TextStyle(
                            fontSize: 11.0,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}


  Future<void> _showMyDialog(
      String Title, String Keterangan, MaterialPageRoute link) async {
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
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.push(context, link);
                },
              )
            ],
          ),
        );
      },
    );
  }

  Future<void> _showNotif(String Title, String Keterangan) async {
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
}

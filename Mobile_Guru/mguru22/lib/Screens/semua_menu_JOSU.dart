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
import 'package:mobile_presensi_kdtg/Screens/JadwalWF/list_jadwalwf_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Kegiatan/ListKegiatan_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Laporan/Kegiatan/Laporan_Kegiatan_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Laporan/LuarJam/Laporan_LuarJam_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Laporan/Perizinan/Laporan_Perizinan_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Laporan/Presensi/Laporan_Presensi_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/LokasiKampus/lokasi_kampus_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Perizinan/izin_screen.dart';
import 'package:mobile_presensi_kdtg/Screens/Profil/profil_user.dart';
import 'package:mobile_presensi_kdtg/Screens/ResetPassword/reset_password.dart';
import 'package:mobile_presensi_kdtg/core.dart';
import 'package:mobile_presensi_kdtg/components/or_divider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class SemuaMenu extends StatefulWidget {
  const SemuaMenu({super.key});

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

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getPref();
    Timer.periodic(const Duration(seconds: 1), (Timer t) => _getTime());
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
    print("Login Pref :$UUID");
    getDataDash();
  }

  Future<String> getDataDash() async {
    print("getJenis");
    var res = await http.get(Uri.parse("${Core().ApiUrl}Dash/get_dash/$UUID"),
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
      print("Jenis Absens : $JenisAbsen");
      print("Dinas Luar : $StatusDinasLuar");
      if (DataAbsenPulang != null) {
        jam_pulang = formatDate(
            DateTime.parse(DataAbsenPulang['waktu']), [hh, ':', nn, ':', ss]);
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
          child: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Colors.white, // add custom icons also
          ),
        ),
      ),
      body: CustomScrollView(
        physics: const ClampingScrollPhysics(),
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
            const Text(
              'Menu Presensi',
              style: TextStyle(
                fontSize: 15.0,
                color: Colors.lightBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10.0),
            Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
              SizedBox(
                  width: width_menu,
                  child: TextButton(
                      onPressed: () {
                        if (JenisAbsen == 0 || JenisAbsen == 1) {
                          if (StatusDinasLuar == 1) {
                            if (DataAbsen == null) {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return const AbsenHarianScreen();
                              }));
                            } else {
                              if (DataAbsenPulang == null) {
                                _showMyDialog("Presensi Harian",
                                    "Anda belum melakukan Presensi Pulang Harian. Silakan Presensi Pulang Harian terlebih dahulu !",
                                    MaterialPageRoute(builder: (context) {
                                  return const AbsenPulangHarianScreen();
                                }));
                              } else {
                                _showNotif("Presensi Harian",
                                    "Anda Sudah Melakukan Presensi Hari ini");
                              }
                            }
                          } else {
                            _showNotif("Presensi Harian",
                                "Anda Dilarang Melakukan Presensi Karena Sedang Dinas Luar");
                          }
                        }
                      },
                      // // minWidth: 0,
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
                          const Text(
                            "Presensi\nMasuk",
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ))),
              SizedBox(
                  width: width_menu,
                  child: TextButton(
                      onPressed: () {
                        if (JenisAbsen == 0 || JenisAbsen == 1) {
                          if (StatusDinasLuar == 1) {
                            if (DataAbsen == null) {
                              _showMyDialog("Presensi Harian",
                                  "Anda belum melakukan Presensi Harian. Silakan Presensi Harian terlebih dahulu !",
                                  MaterialPageRoute(builder: (context) {
                                return const AbsenHarianScreen();
                              }));
                            } else {
                              if (DataAbsenPulang == null) {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return const AbsenPulangHarianScreen();
                                }));
                              } else {
                                _showMyDialog("Presensi Harian",
                                    "Apakah Anda Memperbarui Pulang Sebelumnya ?",
                                    MaterialPageRoute(builder: (context) {
                                  return const AbsenPulangHarianScreen();
                                }));
                              }
                            }
                          } else {
                            _showNotif("Presensi Harian",
                                "Anda Dilarang Melakukan Presensi Karena Sedang Dinas Luar");
                          }
                        }
                      },
                      // // minWidth: 0,
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
                          const Text(
                            "Presensi\nPulang",
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ))),
              SizedBox(
                  width: width_menu,
                  child: TextButton(
                      onPressed: () {
                        if (DataIstirahat == null) {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return const AbsenIstirahatScreen();
                          }));
                        } else {
                          _showMyDialog("Presensi Istirahat",
                              "Anda belum melakukan Presensi Selesai Istirahat. Silakan Presensi Selesai Istirahat terlebih dahulu !",
                              MaterialPageRoute(builder: (context) {
                            return const AbsenSelesaiIstirahatScreen();
                          }));
                        }
                      },
                      // // minWidth: 0,
                      child: Column(
                        children: <Widget>[
                          Image.asset(
                            "assets/icons/istirahat_keluar_warna.png",
                            height: screenHeight * 0.07,
                          ),
                          SizedBox(height: screenHeight * 0.003),
                          const Text(
                            "Istirahat Keluar",
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ))),
              SizedBox(
                  width: width_menu,
                  child: TextButton(
                      onPressed: () {
                        if (DataIstirahat == null) {
                          _showMyDialog("Presensi Istirahat",
                              "Anda belum melakukan Presensi Istirahat. Silakan Presensi Istirahat terlebih dahulu !",
                              MaterialPageRoute(builder: (context) {
                            return const AbsenIstirahatScreen();
                          }));
                        } else {
                          Navigator.push(context,
                              MaterialPageRoute(builder: (context) {
                            return const AbsenSelesaiIstirahatScreen();
                          }));
                        }
                      },
                      // // minWidth: 0,
                      child: Column(
                        children: <Widget>[
                          Image.asset(
                            "assets/icons/istirahat_masuk_warna.png",
                            height: screenHeight * 0.07,
                          ),
                          SizedBox(height: screenHeight * 0.003),
                          const Text(
                            "Istirahat Masuk",
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ))),
            ]),
            const SizedBox(height: 15.0),
            Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
              SizedBox(
                  width: width_menu,
                  child: TextButton(
                      onPressed: () {
                        if (JenisAbsen == 0 || JenisAbsen == 4) {
                          if (StatusDinasLuar == 1) {
                            if (DataAbsen == null) {
                              Navigator.push(context,
                                  MaterialPageRoute(builder: (context) {
                                return const AbsenWFScreen();
                              }));
                            } else {
                              if (DataAbsenPulang == null) {
                                _showMyDialog("Presensi WFH",
                                    "Anda belum melakukan Presensi Selesai WFH. Silakan Presensi Selesai WFH terlebih dahulu !",
                                    MaterialPageRoute(builder: (context) {
                                  return const AbsenSelesaiWFScreen();
                                }));
                              } else {
                                _showNotif("Presensi WFH",
                                    "Anda Sudah Melakukan Presensi WFH");
                              }
                            }
                          } else {
                            _showNotif("Presensi WFH",
                                "Anda Dilarang Melakukan Presensi Karena Sedang Dinas Luar");
                          }
                        }
                      },
                      // // minWidth: 0,
                      child: Column(
                        children: <Widget>[
                          Image.asset(
                            ((JenisAbsen == 0 || JenisAbsen == 4) &&
                                    StatusDinasLuar == 1)
                                ? "assets/icons/mulai_wfh_warna.png"
                                : "assets/icons/mulai_wfh_monokrom.png",
                            height: screenHeight * 0.07,
                          ),
                          SizedBox(height: screenHeight * 0.003),
                          const Text(
                            "Mulai WFH",
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ))),
              SizedBox(
                  width: width_menu,
                  child: TextButton(
                      onPressed: () {
                        if (JenisAbsen == 0 || JenisAbsen == 4) {
                          if (StatusDinasLuar == 1) {
                            if (DataAbsen == null) {
                              _showMyDialog("Presensi WFH",
                                  "Anda belum melakukan Presensi WFH. Silakan Presensi WFH terlebih dahulu !",
                                  MaterialPageRoute(builder: (context) {
                                return const AbsenWFScreen();
                              }));
                            } else {
                              if (DataAbsenPulang == null) {
                                Navigator.push(context,
                                    MaterialPageRoute(builder: (context) {
                                  return const AbsenSelesaiWFScreen();
                                }));
                              } else {
                                _showMyDialog("Presensi WFH",
                                    "Apakah Anda Memperbarui Pulang Sebelumnya ?",
                                    MaterialPageRoute(builder: (context) {
                                  return const AbsenSelesaiWFScreen();
                                }));
                              }
                            }
                          } else {
                            _showNotif("Presensi WFH",
                                "Anda Dilarang Melakukan Presensi Karena Sedang Dinas Luar");
                          }
                        }
                      },
                      // // minWidth: 0,
                      child: Column(
                        children: <Widget>[
                          Image.asset(
                            ((JenisAbsen == 0 ||
                                        JenisAbsen == 4 ||
                                        (DataPegawai["jab_struktur"] ==
                                                "Dosen" &&
                                            DataAbsen != null)) &&
                                    StatusDinasLuar == 1)
                                ? "assets/icons/selesai_wfh_warna.png"
                                : "assets/icons/selesai_wfh_monokrom.png",
                            height: screenHeight * 0.07,
                          ),
                          SizedBox(height: screenHeight * 0.003),
                          const Text(
                            "Selesai WFH",
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ))),
              SizedBox(
                  width: width_menu,
                  child: TextButton(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return const ListKegiatanScreen();
                        }));
                      },
                      // // minWidth: 0,
                      child: Column(
                        children: <Widget>[
                          Image.asset(
                            "assets/icons/kegiatan.png",
                            height: screenHeight * 0.07,
                          ),
                          SizedBox(height: screenHeight * 0.003),
                          const Text(
                            "Presensi Kegiatan",
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ))),
              SizedBox(
                  width: width_menu,
                  child: TextButton(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return const PresensiLokasiScreen();
                        }));
                      },
                      // // minWidth: 0,
                      child: Column(
                        children: <Widget>[
                          Image.asset(
                            "assets/icons/kerja_luar.png",
                            height: screenHeight * 0.06,
                          ),
                          SizedBox(height: screenHeight * 0.003),
                          const Text(
                            "Presensi Di Luar Jam Kerja",
                            style: TextStyle(
                              fontSize: 10.0,
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

  // Menu perijinan
  SliverToBoxAdapter _perijinan(double screenHeight) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.only(left: 15.0, top: 25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const OrDivider(),
            const Text(
              'Menu Cuti',
              style: TextStyle(
                fontSize: 15.0,
                color: Colors.lightBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10.0),
            Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  SizedBox(
                      width: width_menu,
                      child: TextButton(
                          onPressed: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return const IzinScreen();
                            }));
                          },
                          // // minWidth: 0,
                          child: Column(
                            children: <Widget>[
                              Image.asset(
                                "assets/icons/cuti_pegawai.png",
                                height: screenHeight * 0.07,
                              ),
                              SizedBox(height: screenHeight * 0.003),
                              const Text(
                                "Cuti Pegawai",
                                style: TextStyle(
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
            const OrDivider(),
            const Text(
              'Menu Laporan',
              style: TextStyle(
                fontSize: 15.0,
                color: Colors.lightBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10.0),
            Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
              SizedBox(
                  width: width_menu,
                  child: TextButton(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return const LaporanCutiScreen();
                        }));
                      },
                      // // minWidth: 0,
                      child: Column(
                        children: <Widget>[
                          Image.asset(
                            "assets/icons/laporan_perijinan.png",
                            height: screenHeight * 0.07,
                          ),
                          SizedBox(height: screenHeight * 0.003),
                          const Text(
                            "Laporan\nCuti",
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ))),
              SizedBox(
                  width: width_menu,
                  child: TextButton(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return const LaporanPresensiScreen();
                        }));
                      },
                      // // minWidth: 0,
                      child: Column(
                        children: <Widget>[
                          Image.asset(
                            "assets/icons/laporan_presensi.png",
                            height: screenHeight * 0.07,
                          ),
                          SizedBox(height: screenHeight * 0.003),
                          const Text(
                            "Laporan\nPresensi",
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ))),
              SizedBox(
                  width: width_menu,
                  child: TextButton(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return const LaporanKegiatanScreen();
                        }));
                      },
                      // // minWidth: 0,
                      child: Column(
                        children: <Widget>[
                          Image.asset(
                            "assets/icons/laporan_kegiatan.png",
                            height: screenHeight * 0.07,
                          ),
                          SizedBox(height: screenHeight * 0.003),
                          const Text(
                            "Laporan\nKegiatan",
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ))),
              SizedBox(
                  width: width_menu,
                  child: TextButton(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return const LaporanLuarJamScreen();
                        }));
                      },
                      // // minWidth: 0,
                      child: Column(
                        children: <Widget>[
                          Image.asset(
                            "assets/icons/kerja_luar.png",
                            height: screenHeight * 0.055,
                          ),
                          SizedBox(height: screenHeight * 0.003),
                          const Text(
                            "Laporan\nLuar Jam Kerja",
                            style: TextStyle(
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

  // Menu profil user
  SliverToBoxAdapter _profileUser(double screenHeight) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.only(left: 15.0, top: 25.0, bottom: 25),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const OrDivider(),
            const Text(
              'Menu Profil User',
              style: TextStyle(
                fontSize: 15.0,
                color: Colors.lightBlue,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10.0),
            Row(mainAxisAlignment: MainAxisAlignment.start, children: <Widget>[
              SizedBox(
                  width: width_menu,
                  child: TextButton(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return const LokasiKampusScreen();
                        }));
                      },
                      // // minWidth: 0,
                      child: Column(
                        children: <Widget>[
                          Image.asset(
                            "assets/icons/lokasi_kampus.png",
                            height: screenHeight * 0.07,
                          ),
                          SizedBox(height: screenHeight * 0.003),
                          const Text(
                            "Lokasi\nKampus",
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ))),
              SizedBox(
                  width: width_menu,
                  child: TextButton(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return const ListJadwalWF_Screen();
                        }));
                      },
                      // // minWidth: 0,
                      child: Column(
                        children: <Widget>[
                          Image.asset(
                            "assets/icons/jadwal_kerja.png",
                            height: screenHeight * 0.07,
                          ),
                          SizedBox(height: screenHeight * 0.003),
                          const Text(
                            "Jadwal\nKerja",
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ))),
              SizedBox(
                  width: width_menu,
                  child: TextButton(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return const ProfilUser();
                        }));
                      },
                      // // minWidth: 0,
                      child: Column(
                        children: <Widget>[
                          Image.asset(
                            "assets/icons/profil_user.png",
                            height: screenHeight * 0.07,
                          ),
                          SizedBox(height: screenHeight * 0.003),
                          const Text(
                            "Profil\nUser",
                            style: TextStyle(
                              fontSize: 11.0,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          )
                        ],
                      ))),
              SizedBox(
                  width: width_menu,
                  child: TextButton(
                      onPressed: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return const ResetPasswordScreen();
                        }));
                      },
                      // minWidth: 0,
                      child: Column(
                        children: <Widget>[
                          Image.asset(
                            "assets/icons/reset_password.png",
                            height: screenHeight * 0.07,
                          ),
                          SizedBox(height: screenHeight * 0.003),
                          const Text(
                            "Reset\nPassword",
                            style: TextStyle(
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
                child: const Text('Keluar'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: const Text('OK'),
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
}

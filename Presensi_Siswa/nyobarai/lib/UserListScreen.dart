import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'DB/DatabaseHelper.dart';

class UserListScreen extends StatefulWidget {
  const UserListScreen({super.key});

  @override
  _UserListScreenState createState() => _UserListScreenState();
}

class _UserListScreenState extends State<UserListScreen> with TickerProviderStateMixin {
  late Future<List<Map<String, dynamic>>> _users = Future.value([]);
  Map<String, String> kelasMap = {};
  bool _isSyncing = false;
  String _sortCriteria = 'nama';
  late AnimationController _listAnimationController;
  late AnimationController _syncAnimationController;
  late Animation<double> _syncRotation;

  @override
  void initState() {
    super.initState();
    _listAnimationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _syncAnimationController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _syncRotation = Tween<double>(begin: 0, end: 1).animate(_syncAnimationController);
    _fetchKelasAndUsers();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    _syncAnimationController.dispose();
    super.dispose();
  }

  Future<void> _fetchKelasAndUsers() async {
    kelasMap = await _fetchKelasData();
    _users = _fetchUsers();
    setState(() {});
    _listAnimationController.forward();
  }

  Future<Map<String, String>> _fetchKelasData() async {
    var url = Uri.parse('https://presensi-smp1.esolusindo.com/Api/ApiKelas/ApiKelas/get_kelas/');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var jsonData = json.decode(response.body);
      if (jsonData['status'] == true) {
        Map<String, String> kelasMap = {};
        for (var kelas in jsonData['data']) {
          kelasMap[kelas['id_kelas']] = kelas['nama_kelas'];
        }
        return kelasMap;
      }
    }
    return {};
  }

  Future<List<Map<String, dynamic>>> _fetchUsers() async {
    final dbHelper = DatabaseHelper.instance;
    return await dbHelper.queryAllRows();
  }

  Future<void> _syncDatabro() async {
    setState(() {
      _isSyncing = true;
    });
    _syncAnimationController.repeat();

    final dbHelper = DatabaseHelper.instance;
    final users = await dbHelper.queryAllRows();
    List<Map<String, dynamic>> arData = [];

    for (var user in users) {
      arData.add({
        'nama': user[DatabaseHelper.columnName],
        'nis': user[DatabaseHelper.columnNIS],
        'id_kelas': user[DatabaseHelper.columnKelas],
        'no_hp_ortu': user[DatabaseHelper.columnNoHpOrtu],
        'model': user[DatabaseHelper.columnEmbedding],
      });
    }
    String bodyraw = jsonEncode(<String, dynamic>{'data': arData});

    try {
      final response = await http.post(
        Uri.parse('https://presensi-smp1.esolusindo.com/Api/ApiSiswa/Siswa/SyncSiswa'),
        headers: <String, String>{'Content-Type': 'application/json; charset=UTF-8'},
        body: bodyraw,
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['message']['status'] == 200 || responseData['message']['status'] == 201) {
          final List<dynamic> users = responseData['data'];
          await dbHelper.deleteAll();

          for (var user in users) {
            await dbHelper.insert({
              DatabaseHelper.columnName: user['nama'],
              DatabaseHelper.columnNIS: user['nis'],
              DatabaseHelper.columnKelas: user['id_kelas'],
              DatabaseHelper.columnNoHpOrtu: user['no_hp_ortu'],
              DatabaseHelper.columnEmbedding: user['model'],
            });
          }

          setState(() {
            _users = _fetchUsers();
          });
          _showSuccessMessage('Data berhasil disinkronkan!');
        }
      } else {
        _showErrorDialog('Gagal mengupload data, status: ${response.statusCode}');
      }
    } catch (e) {
      _showErrorDialog('Koneksi gagal. Pastikan Anda terhubung ke internet.');
    } finally {
      setState(() {
        _isSyncing = false;
      });
      _syncAnimationController.stop();
      _syncAnimationController.reset();
    }
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: const Color(0xFF059669),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFF8FAFC)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.error_outline, color: Color(0xFFDC2626), size: 48),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Kesalahan',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF6B7280),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('OK', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _sortUsers(List<Map<String, dynamic>> users) {
    List<Map<String, dynamic>> sortedUsers = List.from(users);
    sortedUsers.sort((a, b) {
      if (_sortCriteria == 'nama') {
        return a[DatabaseHelper.columnName].compareTo(b[DatabaseHelper.columnName]);
      } else if (_sortCriteria == 'kelas') {
        return a[DatabaseHelper.columnKelas].compareTo(b[DatabaseHelper.columnKelas]);
      } else {
        return a[DatabaseHelper.columnNIS].compareTo(b[DatabaseHelper.columnNIS]);
      }
    });
    return sortedUsers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 20),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(25)),
          ),
          child: AppBar(
            title: const Text(
              'Daftar Murid',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            centerTitle: true,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: Image.asset('assets/logoSMP.png'),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            toolbarHeight: kToolbarHeight + 20,
            actions: [
              Container(
                margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                decoration: BoxDecoration(
                  gradient: _isSyncing 
                    ? null 
                    : const LinearGradient(colors: [Colors.white, Color(0xFFF1F5F9)]),
                  color: _isSyncing ? Colors.white.withOpacity(0.2) : null,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: _isSyncing ? null : [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _isSyncing
                  ? Padding(
                      padding: const EdgeInsets.all(12),
                      child: AnimatedBuilder(
                        animation: _syncRotation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _syncRotation.value * 2 * 3.14159,
                            child: const Icon(
                              Icons.sync,
                              color: Colors.white,
                              size: 24,
                            ),
                          );
                        },
                      ),
                    )
                  : TextButton.icon(
                      onPressed: _syncDatabro,
                      icon: const Icon(Icons.sync, color: Color(0xFF3B82F6), size: 20),
                      label: const Text(
                        'Sync',
                        style: TextStyle(
                          color: Color(0xFF3B82F6),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
              ),
            ],
          ),
        ),
      ),
      body: Column(
        children: [
          // Sort Section
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.sort, color: Color(0xFF3B82F6)),
                const SizedBox(width: 12),
                const Text(
                  "Urutkan:",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _sortCriteria,
                        dropdownColor: Colors.white,
                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                        onChanged: (String? newValue) {
                          setState(() {
                            _sortCriteria = newValue!;
                          });
                        },
                        items: <String>['nama', 'kelas', 'nis']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value[0].toUpperCase() + value.substring(1),
                              style: const TextStyle(
                                color: Color(0xFF1F2937),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // User List
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _users,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF3B82F6)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Memuat data murid...',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (snapshot.hasError) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline, size: 64, color: Color(0xFFDC2626)),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${snapshot.error}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.school_outlined, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          const Text(
                            'Belum ada murid terdaftar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Lakukan sinkronisasi untuk memuat data',
                            style: TextStyle(
                              fontSize: 14,
                              color: Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final users = _sortUsers(snapshot.data!);

                return AnimatedBuilder(
                  animation: _listAnimationController,
                  builder: (context, child) {
                    return ListView.builder(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        String namaKelas = kelasMap[user[DatabaseHelper.columnKelas]] ?? 'Kelas tidak ditemukan';
                        
                        // Staggered animation
                        final animationDelay = index * 0.1;
                        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _listAnimationController,
                            curve: Interval(
                              animationDelay.clamp(0.0, 1.0),
                              (animationDelay + 0.3).clamp(0.0, 1.0),
                              curve: Curves.easeOutBack,
                            ),
                          ),
                        );

                        return SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.3, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: FadeTransition(
                            opacity: animation,
                            child: Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [Colors.white, Color(0xFFFBFBFB)],
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Row(
                                  children: [
                                    // Avatar
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                                        ),
                                        borderRadius: BorderRadius.circular(18),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0xFF3B82F6).withOpacity(0.3),
                                            blurRadius: 12,
                                            offset: const Offset(0, 6),
                                          ),
                                        ],
                                      ),
                                      child: Center(
                                        child: Text(
                                          user[DatabaseHelper.columnName][0].toUpperCase(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 24,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    
                                    // User Info
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            user[DatabaseHelper.columnName],
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF1F2937),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [Color(0xFF10B981), Color(0xFF34D399)],
                                              ),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              namaKelas,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Icon(Icons.badge, size: 16, color: Color(0xFF6B7280)),
                                              const SizedBox(width: 4),
                                              Text(
                                                'NIS: ${user[DatabaseHelper.columnNIS]}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Color(0xFF6B7280),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.phone, size: 16, color: Color(0xFFD97706)),
                                              const SizedBox(width: 4),
                                              Text(
                                                '${user[DatabaseHelper.columnNoHpOrtu]}',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                  color: Color(0xFFD97706),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
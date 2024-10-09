import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'login_page.dart'; // Pastikan untuk mengimpor LoginPage

class AccountPage extends StatefulWidget {
  final String namaWali; // Menyimpan nama wali
  final String no_hp; // Menyimpan nomor telepon wali

  // Konstruktor yang menerima parameter
  AccountPage({required this.namaWali, required this.no_hp});

  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String? password;
  bool _obscurePassword = true;
  final String apiUrl = 'https://presensi-smp1.esolusindo.com/Api/ApiWali/WaliAPI'; // URL API

  @override
  void initState() {
    super.initState();
    _loadData(); // Memuat data saat halaman dibuka
  }

  // Fungsi untuk mengambil data dari API
  Future<void> _loadData() async {
    final response = await http.get(Uri.parse('$apiUrl/getData')); // API untuk mengambil data user

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      setState(() {
        // Menetapkan nama wali dan nomor hp dari parameter
        password = data['password'];
      });
    } else {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data!')),
      );
    }
  }

  // Fungsi untuk mengupdate data melalui API
  Future<void> _saveData(String nama, String noHp, String password) async {
    final response = await http.put(
      Uri.parse('$apiUrl/edit'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'namaWali': nama,
        'no_hp': noHp,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Perubahan disimpan!')),
      );
      _loadData(); // Memuat ulang data setelah update
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menyimpan perubahan!')),
      );
    }
  }

  void _saveChanges(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Konfirmasi Perubahan', style: GoogleFonts.poppins()),
          content: Text('Apakah Anda yakin ingin menyimpan perubahan?', style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text('Batal', style: GoogleFonts.poppins(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                // Simpan perubahan melalui API
                _saveData(widget.namaWali, widget.no_hp, password!);
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text('Simpan', style: GoogleFonts.poppins(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }

void _showEditDialog(BuildContext context) {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController nameController = TextEditingController(text: widget.namaWali);
  final TextEditingController no_hpController = TextEditingController(text: widget.no_hp);
  final TextEditingController passwordController = TextEditingController(text: password ?? ''); // Ini sudah benar

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('Edit Informasi Akun', style: GoogleFonts.poppins(fontSize: 20)),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTextField('Nama', nameController, (value) {}),
                SizedBox(height: 16),
                // _buildTextField('Nomor HP', no_hpController, (value) {}),
                // SizedBox(height: 16),
                _buildTextField('Password', passwordController, (value) {
                  password = value; // Menyimpan password terbaru di state
                },
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword; // Toggle visibility
                    });
                  },
                )),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Tutup dialog
            },
            child: Text('Batal', style: GoogleFonts.poppins(color: Colors.red)),
          ),
          TextButton(
            onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Simpan data yang telah diedit
                _saveData(nameController.text, no_hpController.text, passwordController.text); // Pastikan untuk menggunakan passwordController
                _saveChanges(context); // Panggil fungsi simpan
                Navigator.of(context).pop(); // Tutup dialog
              }
            },
            child: Text('Simpan', style: GoogleFonts.poppins(color: Colors.blueAccent)),
          ),
        ],
      );
    },
  );
}

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Konfirmasi Logout', style: GoogleFonts.poppins()),
          content: Text('Apakah Anda ingin logout?', style: GoogleFonts.poppins()),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Tutup dialog
              },
              child: Text('Tidak', style: GoogleFonts.poppins(color: Colors.red)),
            ),
            TextButton(
              onPressed: () {
                _logout(context); // Panggil fungsi logout
              },
              child: Text('Ya', style: GoogleFonts.poppins(color: Colors.blueAccent)),
            ),
          ],
        );
      },
    );
  }

  void _logout(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginPage()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Akun Saya', style: GoogleFonts.poppins(fontSize: 20)),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _showLogoutDialog(context); // Tampilkan dialog konfirmasi logout
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Menampilkan informasi akun
              Text('Informasi Akun', style: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              _buildInfoTile('Nama', widget.namaWali),
              _buildInfoTile('Nomor HP', widget.no_hp),
              SizedBox(height: 24),

              // Tombol untuk edit informasi akun
              Center(
                child: ElevatedButton(
                  onPressed: () => _showEditDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text('Edit Akun', style: GoogleFonts.poppins(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String title, String value) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: GoogleFonts.poppins(fontSize: 16)),
          Text(value, style: GoogleFonts.poppins(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller,
      Function(String) onChanged,
      {bool obscureText = false, TextInputType keyboardType = TextInputType.text, Widget? suffixIcon}) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.blueAccent),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blueAccent),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.blue),
        ),
        filled: true,
        fillColor: Colors.grey[200],
        suffixIcon: suffixIcon,
      ),
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Silakan masukkan $label Anda';
        }
        return null;
      },
      onChanged: onChanged,
    );
  }
}

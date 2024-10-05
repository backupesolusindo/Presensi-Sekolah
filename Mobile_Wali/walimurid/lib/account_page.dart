import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AccountPage extends StatefulWidget {
  @override
  _AccountPageState createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String _name = 'Nama Anda'; // Default name for display
  String _email = 'email@anda.com'; // Default email for display
  String _password = ''; // Password is not shown for security reasons
  bool _obscurePassword = true;

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
                // Simpan perubahan di sini, misalnya ke database
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Perubahan disimpan!')),
                );
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
    final TextEditingController nameController = TextEditingController(text: _name);
    final TextEditingController emailController = TextEditingController(text: _email);
    final TextEditingController passwordController = TextEditingController(text: _password);

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
                  _buildTextField('Nama', nameController, (value) => _name = value),
                  SizedBox(height: 16),
                  _buildTextField('Email', emailController, (value) => _email = value,
                      keyboardType: TextInputType.emailAddress),
                  SizedBox(height: 16),
                  _buildTextField('Password', passwordController, (value) => _password = value,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Akun Saya', style: GoogleFonts.poppins(fontSize: 20)),
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
              _buildInfoTile('Nama', _name),
              _buildInfoTile('Email', _email),
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

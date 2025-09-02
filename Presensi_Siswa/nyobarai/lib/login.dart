import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:lottie/lottie.dart';
import 'HomeScreen.dart';
import 'package:google_fonts/google_fonts.dart';

class PostLogin {
  int status_kode;
  String status_spesial;
  String message;
  String Pegawai;
  String NIP;
  String UUID;
  String IDKampus, NamaKampus;
  String LokasiLat, LokasiLng, Radius;

  PostLogin({
    this.status_kode = 0,
    this.message = "",
    this.NIP = "",
    this.Pegawai = "",
    this.UUID = "",
    this.status_spesial = "",
    this.LokasiLat = "",
    this.LokasiLng = "",
    this.Radius = "",
    this.IDKampus = "",
    this.NamaKampus = "",
  });

  factory PostLogin.createPostLogin(Map<String, dynamic> object) {
    return PostLogin(
      status_kode: object['message']['status'],
      message: object['message']['message'],
      IDKampus: object['message']['kampus']['idkampus'],
      NamaKampus: object['message']['kampus']['nama_kampus'],
      LokasiLat: object['message']['kampus']['latitude'],
      LokasiLng: object['message']['kampus']['longtitude'],
      Radius: object['message']['kampus']['radius'],
      NIP: object['response']["nip"],
      Pegawai: object['response']["nama"],
      UUID: object['response']["uuid"],
      status_spesial: object['response']["spesial"].toString(),
    );
  }

  static Future<PostLogin?> connectToApi(
      String username, String password, String token) async {
    var url =
        Uri.parse("https://presensi-smp1.esolusindo.com/Api/Login/aksi_login");
    var apiResult = await http.post(url, body: {
      "nip": username,
      "password": password,
      "token": token,
    });

    print('Response status: ${apiResult.statusCode}');
    print('Response body: ${apiResult.body}');

    if (apiResult.statusCode == 200) {
      var jsonObject = json.decode(apiResult.body);
      return PostLogin.createPostLogin(jsonObject);
    } else {
      return null;
    }
  }
}

class PostLogout {
  int status_kode;
  String message;

  PostLogout({
    required this.status_kode,
    required this.message,
  });

  factory PostLogout.createPostLogout(Map<String, dynamic> object) {
    return PostLogout(
      status_kode: object['message']['status'],
      message: object['message']['message'],
    );
  }

  static Future<PostLogout?> connectToApi(String uuid) async {
    var url =
        Uri.parse("https://presensi-smp1.esolusindo.com/Api/Login/aksi_logout");
    var apiResult = await http.post(url, body: {
      "uuid": uuid,
    });

    print('Response status: ${apiResult.statusCode}');
    print('Response body: ${apiResult.body}');

    if (apiResult.statusCode == 200) {
      var jsonObject = json.decode(apiResult.body);
      return PostLogout.createPostLogout(jsonObject);
    } else {
      return null;
    }
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _login() async {
    setState(() {
      _isLoading = true;
    });

    String username = _usernameController.text;
    String password = _passwordController.text;
    String token = _tokenController.text;

    _showLoadingDialog();

    PostLogin? loginResult =
        await PostLogin.connectToApi(username, password, token);
    if (loginResult != null && loginResult.status_kode == 200) {
      await _attemptLogout(loginResult.UUID);
      Navigator.pop(context); // Close the loading dialog
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else {
      Navigator.pop(context); // Close the loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login gagal, silakan coba lagi.')),
      );
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _attemptLogout(String uuid) async {
    bool logoutSuccess = false;
    while (!logoutSuccess) {
      PostLogout? logoutResult = await PostLogout.connectToApi(uuid);
      if (logoutResult != null && logoutResult.status_kode == 200) {
        logoutSuccess = true;
      } else {
        print('Logout gagal, mencoba lagi...');
      }
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset('assets/loading.json', width: 150, height: 150),
                const SizedBox(height: 20),
                const Text("Loading..."),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    const SizedBox(height: 60.0),
                    _buildLogo(),
                    const SizedBox(height: 40.0),
                    _buildTitle(),
                    const SizedBox(height: 20.0),
                    _buildTextField(
                      controller: _usernameController,
                      labelText: 'NIP',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 20.0),
                    _buildTextField(
                      controller: _passwordController,
                      labelText: 'Password',
                      icon: Icons.lock,
                      isPassword: true,
                    ),
                    const SizedBox(height: 30.0),
                    _isLoading ? _buildLoadingIndicator() : _buildLoginButton(),
                    const SizedBox(height: 20),
                    const SizedBox(height: 20.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return ScaleTransition(
      scale: _animation,
      child: Image.asset(
        'assets/logoSMP.png',
        height: 120,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'LOGIN ADMIN SMPN 3 JEMBER',
      style: GoogleFonts.poppins(
        textStyle: const TextStyle(
          fontSize: 26.0,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(icon, color: Colors.black54),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                  color: Colors.black54,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.8),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: _login,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        backgroundColor: Colors.blue[600],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.0),
        ),
      ),
      child: Text(
        'Login',
        style: GoogleFonts.poppins(
          textStyle: const TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }
}

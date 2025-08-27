import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '/Utilities/BaseUrl.dart';
import 'home.dart';
import 'signup.dart';
import 'services/pusher_service.dart';
import 'services/background_pusher_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController no_hpController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isPasswordVisible = false;
  bool _isCheckingLoginStatus = true;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.bounceOut);
    _controller.forward();
    
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? namaWali = prefs.getString('nama_wali');
      String? noHp = prefs.getString('no_hp');
      bool isLoggedIn = prefs.getBool('is_logged_in') ?? false;
      
      if (namaWali != null && noHp != null && isLoggedIn && noHp.isNotEmpty) {
        print("User already logged in, phone: $noHp");
        
        // Initialize services
        await _initializeAllServices(noHp);
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        return;
      }
    } catch (e) {
      print("Error checking login status: $e");
    }
    
    setState(() {
      _isCheckingLoginStatus = false;
    });
  }

  Future<void> _initializeAllServices(String userPhone) async {
    try {
      // 1. Initialize foreground Pusher Service
      try {
        if (PusherService().isConnected) {
          await PusherService().updateUserPhone(userPhone);
        } else {
          await PusherService().initialize(
            userPhone: userPhone,
            onNotificationTap: _handleNotificationTap,
          );
        }
        print("Foreground Pusher Service initialized for phone: $userPhone");
      } catch (pusherError) {
        print("Foreground Pusher failed: $pusherError");
      }
      
      // 2. Initialize background service
      try {
        await BackgroundPusherService.startService();
        await BackgroundPusherService.updateUserPhone(userPhone);
        print("Background Pusher Service started for phone: $userPhone");
      } catch (bgError) {
        print("Background service failed: $bgError");
      }
      
      _showSuccessSnackbar('Layanan notifikasi aktif untuk nomor $userPhone');
      
    } catch (e) {
      print("Error initializing services: $e");
      _showSuccessSnackbar('Login berhasil! (Beberapa layanan mungkin tidak aktif)');
    }
  }

  void _handleNotificationTap(Map<String, dynamic> data) {
    print("Notification tapped in login: $data");
    
    String type = data['type'] ?? '';
    String redirect = data['redirect'] ?? 'dashboard';
    
    switch (type) {
      case 'absensi_masuk':
      case 'absensi_pulang':
      case 'parent_notification':
      case 'background_masuk':
      case 'background_pulang':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
      default:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
        );
        break;
    }
  }

  Future<void> login() async {
    final String noHp = no_hpController.text.trim();
    final String password = passwordController.text.trim();

    if (noHp.isEmpty || password.isEmpty) {
      _showErrorSnackbar('Nomor telepon dan password tidak boleh kosong');
      return;
    }

    final url = Uri.parse('$UrlApi/WaliAPI/login');
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        url,
        body: {
          'no_hp': noHp,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['status'] == 'success') {
          // Simpan data ke SharedPreferences
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('nama_wali', data['nama_wali']);
          await prefs.setString('no_hp', data['no_hp']);
          await prefs.setString('password', password);
          await prefs.setBool('is_logged_in', true);

          print("Login successful for phone: ${data['no_hp']}");

          // Initialize services setelah login berhasil
          await _initializeAllServices(data['no_hp']);

          // Navigate ke homepage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        } else {
          _showErrorSnackbar(data['message'] ?? 'Nomor telepon atau password salah');
        }
      } else {
        _showErrorSnackbar('Gagal menghubungi server. Coba lagi nanti.');
      }
    } catch (e) {
      print("Login error: $e");
      _showErrorSnackbar('Terjadi kesalahan. Cek koneksi internet Anda.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorSnackbar(String message) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(10),
      duration: const Duration(seconds: 4),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  void _showSuccessSnackbar(String message) {
    final snackBar = SnackBar(
      content: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: Colors.white),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(10),
      duration: const Duration(seconds: 3),
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  @override
  void dispose() {
    _controller.dispose();
    no_hpController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingLoginStatus) {
      return _buildCheckingLoginScreen();
    }

    return _buildLoginScreen();
  }

  Widget _buildCheckingLoginScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/walibg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blueAccent),
              ),
              SizedBox(height: 20),
              Text(
                'Mengecek status login...',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Mengaktifkan layanan notifikasi...',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginScreen() {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/walibg.png'),
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
                      controller: no_hpController,
                      labelText: 'Nomor Telepon',
                      icon: Icons.phone,
                      hintText: 'Contoh: 08123456789',
                    ),
                    const SizedBox(height: 20.0),
                    _buildTextField(
                      controller: passwordController,
                      labelText: 'Password',
                      icon: Icons.lock,
                      isPassword: true,
                    ),
                    const SizedBox(height: 30.0),
                    _isLoading ? _buildLoadingIndicator() : _buildLoginButton(),
                    const SizedBox(height: 20),
                    _buildSignupButton(),
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
        'assets/logosmpn3.png',
        height: 120,
      ),
    );
  }

  Widget _buildTitle() {
    return Text(
      'LOGIN WALI SMPN 3 JEMBER',
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
    String? hintText,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword && !_isPasswordVisible,
      keyboardType: icon == Icons.phone ? TextInputType.phone : TextInputType.text,
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),
        filled: true,
        fillColor: Colors.white.withOpacity(0.9),
      ),
    );
  }

  Widget _buildLoginButton() {
    return ElevatedButton(
      onPressed: login,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 24.0),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        elevation: 3,
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

  Widget _buildSignupButton() {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const SignupPage()),
        );
      },
      child: Text(
        'Belum punya akun? Daftar di sini',
        style: GoogleFonts.raleway(
          textStyle: const TextStyle(
            color: Colors.blueAccent,
            fontSize: 16.0,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: Colors.blueAccent.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: const Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
            SizedBox(width: 12),
            Text(
              'Sedang login...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
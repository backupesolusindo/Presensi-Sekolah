import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'RecognitionScreen.dart';
import 'UserListScreen.dart';
import 'RFIDScreen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _isPressed = false;
  late AnimationController _logoController;
  late Animation<double> _logoAnimation;
  late AnimationController _buttonController;
  late List<Animation<Offset>> _buttonAnimations;

  @override
  void initState() {
    super.initState();
    
    // Logo animation
    _logoController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _logoAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _logoController,
      curve: Curves.elasticOut,
    ));

    // Button animations
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _buttonAnimations = [
      Tween<Offset>(
        begin: const Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _buttonController,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      )),
      Tween<Offset>(
        begin: const Offset(1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _buttonController,
        curve: const Interval(0.2, 0.8, curve: Curves.elasticOut),
      )),
      Tween<Offset>(
        begin: const Offset(-1.0, 0.0),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _buttonController,
        curve: const Interval(0.4, 1.0, curve: Curves.elasticOut),
      )),
    ];

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 500), () {
      _buttonController.forward();
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A), // Blue-900
              Color(0xFF3B82F6), // Blue-500
              Color(0xFF60A5FA), // Blue-400
              Color(0xFFDBEAFE), // Blue-100
            ],
            stops: [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: _isLoading
                ? Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 25,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Lottie.asset('assets/loading.json', width: 150, height: 150),
                        const SizedBox(height: 20),
                        const Text(
                          'Memuat...',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E3A8A),
                          ),
                        ),
                      ],
                    ),
                  )
                : SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 40),
                          
                          // Animated Logo Section
                          AnimatedBuilder(
                            animation: _logoAnimation,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _logoAnimation.value,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        blurRadius: 30,
                                        offset: const Offset(0, 15),
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    "assets/logoSMP.png",
                                    width: screenWidth * 0.4,
                                    height: screenWidth * 0.4,
                                  ),
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 30),

                          // Animated Title
                          AnimatedBuilder(
                            animation: _logoAnimation,
                            builder: (context, child) {
                              return Opacity(
                                opacity: _logoAnimation.value,
                                child: Column(
                                  children: [
                                    const Text(
                                      "Presensi Wajah",
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                        shadows: [
                                          Shadow(
                                            blurRadius: 10,
                                            color: Colors.black26,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: Colors.white.withOpacity(0.3)),
                                      ),
                                      child: const Text(
                                        "SMPN 3 Jember",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          
                          const SizedBox(height: 60),

                          // Animated Buttons dengan gradasi biru yang berbeda
                          ...List.generate(3, (index) {
                            final buttons = [
                              {
                                'title': 'Presensi Wajah',
                                'icon': Icons.camera_alt_rounded,
                                'gradient': [const Color(0xFF1E40AF), const Color(0xFF3B82F6)], // Blue-800 to Blue-500
                                'action': () => _navigateWithLoading(context, const RecognitionScreen()),
                              },
                              {
                                'title': 'Murid Terdaftar',
                                'icon': Icons.list_alt_rounded,
                                'gradient': [const Color(0xFF1E3A8A), const Color(0xFF2563EB)], // Blue-900 to Blue-600
                                'action': () => _navigateWithLoading(context, const UserListScreen()),
                              },
                              {
                                'title': 'Presensi RFID',
                                'icon': Icons.wifi_rounded,
                                'gradient': [const Color(0xFF1D4ED8), const Color(0xFF60A5FA)], // Blue-700 to Blue-400
                                'action': () => _navigateWithLoading(context, const RFIDScreen()),
                              },
                            ];

                            return SlideTransition(
                              position: _buttonAnimations[index],
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 20),
                                child: _buildEnhancedButton(
                                  buttons[index]['title'] as String,
                                  buttons[index]['icon'] as IconData,
                                  buttons[index]['gradient'] as List<Color>,
                                  buttons[index]['action'] as VoidCallback,
                                ),
                              ),
                            );
                          }),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedButton(
      String title, IconData icon, List<Color> gradientColors, VoidCallback onPressed) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        onPressed();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.identity()
          ..scale(_isPressed ? 0.95 : 1.0)
          ..rotateZ(_isPressed ? -0.01 : 0.0),
        child: Container(
          width: double.infinity,
          height: 75,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.2), // Border putih transparan
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: gradientColors[0].withOpacity(0.4),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.1),
                blurRadius: 5,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: onPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 18),
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        shadows: [
                          Shadow(
                            blurRadius: 5,
                            color: Colors.black26,
                            offset: Offset(0, 1),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateWithLoading(BuildContext context, Widget page) async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.push(context, MaterialPageRoute(builder: (_) => page));
    }
  }
}
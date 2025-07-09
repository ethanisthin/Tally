import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _slideInController;
  late AnimationController _slideOutController;

  late Animation<double> _logoSlideInAnimation;
  late Animation<double> _textSlideInAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _textOpacityAnimation;
  late Animation<double> _screenSlideOutAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controllers
    _slideInController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _slideOutController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    // Logo slide in from bottom
    _logoSlideInAnimation = Tween<double>(
      begin: 200.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _slideInController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    ));

    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideInController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
    ));

    // Text slide in from bottom (slightly delayed)
    _textSlideInAnimation = Tween<double>(
      begin: 100.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _slideInController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOutBack),
    ));

    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _slideInController,
      curve: const Interval(0.3, 0.9, curve: Curves.easeIn),
    ));

    // Screen slide out animation (everything goes up)
    // final screenHeight = MediaQuery.of(context).size.height;
    _screenSlideOutAnimation = Tween<double>(
      begin: 0.0,
      end: 1000,
    ).animate(CurvedAnimation(
      parent: _slideOutController,
      curve: Curves.easeInBack,
    ));

    _startAnimations();
  }

  void _startAnimations() async {
    // Start slide in animation (logo and text slide up from bottom)
    await _slideInController.forward();

    // Wait for 1.5 seconds to show the complete splash
    await Future.delayed(const Duration(milliseconds: 1500));

    // Start slide out animation and navigation simultaneously
    _slideOutController.forward();

    // Start navigation after slide out has started (small delay for smoothness)
    Future.delayed(const Duration(milliseconds: 200), () {
      _navigateToNextScreen();
    });
  }

  void _navigateToNextScreen() {
    User? currentUser = FirebaseAuth.instance.currentUser;

    if (mounted) {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) {
            return currentUser != null
                ? const HomeScreen()
                : const LoginScreen();
          },
          transitionDuration: const Duration(milliseconds: 600),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _slideInController.dispose();
    _slideOutController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      body: AnimatedBuilder(
        animation: Listenable.merge([_slideInController, _slideOutController]),
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, -_screenSlideOutAnimation.value),
            child: Stack(
              children: [
                // Main content
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo (slide up from bottom)
                      Transform.translate(
                        offset: Offset(0, _logoSlideInAnimation.value),
                        child: Opacity(
                          opacity: _logoOpacityAnimation.value,
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFFFFF),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFFFFFFF).withOpacity(0.3),
                                  blurRadius: 20,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                            child: ClipOval(
                              clipBehavior: Clip.none,
                              child: Image.asset(
                                'assets/images/temp-logo.png',
                                width: 200,
                                height: 200,
                                fit: BoxFit.fill,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // App name (slide up from bottom)
                      Transform.translate(
                        offset: Offset(0, _textSlideInAnimation.value),
                        child: Opacity(
                          opacity: _textOpacityAnimation.value,
                          child: const Text(
                            'Tally',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontFamily: 'Poppins',
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Subtitle at the bottom of the screen
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 40,
                  child: Transform.translate(
                    offset: Offset(0, _textSlideInAnimation.value),
                    child: Opacity(
                      opacity: _textOpacityAnimation.value * 0.7,
                      child: const Text(
                        'Track expenses with ease',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w300,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

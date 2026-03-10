import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_care/main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // 🔥 Paksa fullscreen (Android & iOS)
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

    Timer(const Duration(milliseconds: 5000), () {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const RootAuthGate()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // ===============================
          // BACKGROUND FULL SCREEN
          // ===============================
          const _ModernSplashBackground(),

          // ===============================
          // ORNAMEN S1 — PALING ATAS (TIMPA NOTCH)
          // ===============================
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/splash/S1.png',
              width: width,
              fit: BoxFit.fitWidth,
            ),
          ),

          // ===============================
          // ORNAMEN S3 — GANTUNGAN KIRI (dari S1)
          // ===============================
          Positioned(
            left: width * 0.03,
            top: 80,
            child: Image.asset(
              'assets/splash/S3.png',
              height: height * 0.22,
              fit: BoxFit.contain,
            ),
          ),

          // ===============================
          // ORNAMEN S3 — GANTUNGAN KANAN (MIRROR dari S1)
          // ===============================
          Positioned(
            right: width * 0.03,
            top: 80,
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(3.14159),
              child: Image.asset(
                'assets/splash/S3.png',
                height: height * 0.22,
                fit: BoxFit.contain,
              ),
            ),
          ),

          // ===============================
          // ORNAMEN S4 — FRAME ISLAMIC ARCH (DI TENGAH)
          // ===============================
          Center(
            child: Image.asset(
              'assets/splash/S4.png',
              height: height * 0.55,
              fit: BoxFit.contain,
            ),
          ),

          // ===============================
          // ORNAMEN S2 — PALING BAWAH
          // ===============================
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Image.asset(
              'assets/splash/S2.png',
              width: width,
              fit: BoxFit.fitWidth,
            ),
          ),

          // ===============================
          // KONTEN TENGAH (AMAN NOTCH) - GESER KE BAWAH
          // ===============================
          SafeArea(
            child: Column(
              children: [
                SizedBox(height: height * 0.05),
                
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 60),
                        
                        // ✅ SPOTLIGHT EFFECT + LOGO
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            // ✅ SPOTLIGHT BULAT PUTIH
                            Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.4), // Terang di tengah
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0.1),
                                    Colors.transparent, // Fade out
                                  ],
                                  stops: const [0.0, 0.4, 0.7, 1.0],
                                ),
                              ),
                            ),
                            
                            // ✅ LOGO DI ATAS SPOTLIGHT
                            Image.asset(
                              'assets/images/home_nobg.png',
                              height: 120,
                              width: 120,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          'PRIMA HomeCare',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Melayani dengan sepenuh hati',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(.9),
                          ),
                        ),

                        const SizedBox(height: 40),

                        const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// =====================================
/// BACKGROUND GRADIENT
/// =====================================
class _ModernSplashBackground extends StatelessWidget {
  const _ModernSplashBackground();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF00D4FF),
            Color(0xFF0BC5EA),
            Color(0xFF06B6D4),
            Color(0xFF0EA5E9),
            Color(0xFF38BDF8),
            Color(0xFFBAE6FD),
          ],
        ),
      ),
    );
  }
}
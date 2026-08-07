import 'dart:async';
import 'package:flutter/material.dart';
import 'package:home_care/screen/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;

  final List<Map<String, String>> _pages = [
    {
      'image': 'assets/splash/ob1.webp',
      'title': 'Selamat Datang di\nPRIMA HomeCare',
      'subtitle': 'Melayani dengan sepenuh hati di rumah Anda',
    },
    {
      'image': 'assets/splash/ob2.webp',
      'title': 'Perawatan\nTerbaik',
      'subtitle':
          'Tenaga medis profesional dan berpengalaman siap membantu Anda',
    },
    {
      'image': 'assets/splash/ob3.webp',
      'title': 'Layanan\nTerpercaya',
      'subtitle': 'Keamanan dan kenyamanan Anda adalah prioritas utama kami',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_currentPage < _pages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOut,
        );
      } else {
        _pageController.jumpToPage(0);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);

    // Calculate responsive sizes to strictly match the reference image's proportions
    final double paddingHorizontal = (size.width * 0.08).clamp(30.0, 48.0);
    final double paddingVertical = (size.height * 0.05).clamp(32.0, 64.0);
    final double logoSize = (size.width * 0.12).clamp(48.0, 60.0);
    final double titleFontSize = (size.width * 0.12).clamp(40.0, 48.0);
    final double subtitleFontSize = (size.width * 0.04).clamp(14.0, 16.0);
    final double buttonHeight = (size.height * 0.08).clamp(60.0, 68.0);
    final double buttonFontSize = (size.width * 0.045).clamp(16.0, 18.0);

    return Scaffold(
      backgroundColor: Colors.black, // Prevents white flash when looping back
      body: Stack(
        children: [
          // Background PageView
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
              _startTimer(); // Reset auto-slide timer when manually swiped
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(_pages[index]['image']!, fit: BoxFit.cover),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withOpacity(0.0),
                          Colors.black.withOpacity(0.4),
                          Colors.black.withOpacity(0.85),
                          Colors.black.withOpacity(1.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.4, 0.6, 0.8, 1.0],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          // Content overlay
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: paddingHorizontal,
                vertical: paddingVertical,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Logo
                  Image.asset(
                    'assets/images/home_nobg.png',
                    width: logoSize,
                    height: logoSize,
                    color: Colors.white,
                  ),
                  SizedBox(height: size.height * 0.02),
                  // Animated Text (Title)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      _pages[_currentPage]['title']!,
                      key: ValueKey<int>(_currentPage),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontSize: titleFontSize,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -1.0,
                        height: 1.1,
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.015),
                  // Animated Text (Subtitle)
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: Text(
                      _pages[_currentPage]['subtitle']!,
                      key: ValueKey<String>('sub_$_currentPage'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white.withOpacity(0.7),
                        fontSize: subtitleFontSize,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.0,
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),
                  // Smooth Page Indicator
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4.0),
                        width: _currentPage == index ? 24.0 : 8.0,
                        height: 8.0,
                        decoration: BoxDecoration(
                          color:
                              _currentPage == index
                                  ? const Color(0xFF0F9D94) // Active color
                                  : Colors.white.withOpacity(
                                    0.3,
                                  ), // Inactive color
                          borderRadius: BorderRadius.circular(4.0),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: size.height * 0.03),
                  // Button
                  SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_currentPage == _pages.length - 1) {
                          final prefs = await SharedPreferences.getInstance();
                          await prefs.setBool('has_seen_onboarding', true);

                          if (!context.mounted) return;

                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const LoginPage(),
                            ),
                          );
                        } else {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F9D94),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(19),
                        ),
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: buttonFontSize,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

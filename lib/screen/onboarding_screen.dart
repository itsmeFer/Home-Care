import 'dart:async';
import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
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
      'subtitle':
          'Melayani kebutuhan medis dan perawatan keluarga dengan sepenuh hati langsung di rumah Anda.',
    },
    {
      'image': 'assets/splash/ob2.webp',
      'title': 'Perawatan Terbaik\nUntuk Keluarga',
      'subtitle':
          'Tenaga medis profesional dan bersertifikasi siap mendampingi proses pemulihan Anda.',
    },
    {
      'image': 'assets/splash/ob3.webp',
      'title': 'Layanan Terpercaya\n& Berkualitas',
      'subtitle':
          'Kenyamanan, keamanan, dan kesehatan pasien selalu menjadi prioritas utama kami.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Pre-cache semua gambar onboarding agar tidak ada lag/hitch saat transisi
    for (final page in _pages) {
      precacheImage(AssetImage(page['image']!), context);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      if (!_pageController.hasClients) return;

      if (_currentPage < _pages.length - 1) {
        _pageController.nextPage(
          duration: const Duration(milliseconds: 650),
          curve: Curves.easeInOutCubic,
        );
      } else {
        // Transisi halus kembali ke slide 1 tanpa patah/black screen
        _pageController.animateToPage(
          0,
          duration: const Duration(milliseconds: 850),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  Future<void> _finishOnboarding() async {
    _timer?.cancel();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: Stack(
        children: [
          // 1. Full-screen PageView slider
          NotificationListener<ScrollNotification>(
            onNotification: (notification) {
              if (notification is ScrollStartNotification) {
                if (notification.dragDetails != null) {
                  _timer?.cancel();
                }
              } else if (notification is ScrollEndNotification) {
                _startTimer();
              }
              return false;
            },
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                _startTimer();
              },
              itemCount: _pages.length,
              itemBuilder: (context, index) {
                return Image.asset(
                  _pages[index]['image']!,
                  fit: BoxFit.cover,
                  gaplessPlayback: true,
                  filterQuality: FilterQuality.medium,
                  frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                    if (wasSynchronouslyLoaded) return child;
                    return AnimatedOpacity(
                      opacity: frame == null ? 0 : 1,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: child,
                    );
                  },
                );
              },
            ),
          ),

          // 2. Cinematic Gradient Overlay (clear in center, dark at bottom for text contrast)
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.40),
                      Colors.transparent,
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.60),
                      Colors.black.withValues(alpha: 0.92),
                      Colors.black,
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: const [0.0, 0.18, 0.45, 0.70, 0.88, 1.0],
                  ),
                ),
              ),
            ),
          ),

          // 3. Top Header (Logo + Lewati Button)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Image.asset(
                    'assets/images/home_nobg.png',
                    height: 28,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                  TextButton(
                    onPressed: _finishOnboarding,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white.withValues(alpha: 0.85),
                      backgroundColor: Colors.black.withValues(alpha: 0.3),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Lewati',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 4. Bottom Content (Left-aligned, elegant typography, matching Foto 2)
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title: Left-aligned, refined size (24px)
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 350),
                      child: Text(
                        _pages[_currentPage]['title']!,
                        key: ValueKey<int>(_currentPage),
                        textAlign: TextAlign.left,
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          height: 1.25,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Subtitle & Action Button in an elegant Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Left: Subtitle description + Dots Indicator
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 350),
                                child: Text(
                                  _pages[_currentPage]['subtitle']!,
                                  key: ValueKey<String>('sub_$_currentPage'),
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w400,
                                    height: 1.45,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              // Page Indicators
                              Row(
                                children: List.generate(
                                  _pages.length,
                                  (index) => AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    margin: const EdgeInsets.only(right: 6.0),
                                    width: _currentPage == index ? 22.0 : 6.0,
                                    height: 6.0,
                                    decoration: BoxDecoration(
                                      color:
                                          _currentPage == index
                                              ? AppColors.primary
                                              : Colors.white.withValues(
                                                alpha: 0.35,
                                              ),
                                      borderRadius: BorderRadius.circular(3.0),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 16),

                        // Right: Compact Rounded Pill Action Button
                        ElevatedButton(
                          onPressed: () {
                            if (isLastPage) {
                              _finishOnboarding();
                            } else {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 500),
                                curve: Curves.easeInOut,
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 22,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isLastPage ? 'Mulai' : 'Lanjut',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.arrow_forward_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

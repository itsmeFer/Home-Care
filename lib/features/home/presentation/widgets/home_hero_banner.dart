import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/core/services/storage_service.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';
import 'package:home_care/users/home_page.dart';
import 'package:home_care/users/layanan_page.dart';
import 'package:home_care/users/notifikasi_page.dart';
import 'package:home_care/users/profile.dart';
import 'package:home_care/users/search_page.dart';
import 'package:home_care/utils/app_cached_image.dart';

class HeroImageBanner extends StatefulWidget {
  const HeroImageBanner();

  @override
  State<HeroImageBanner> createState() => _HeroImageBannerState();
}

class _HeroImageBannerState extends State<HeroImageBanner> {
  final List<String> _searchTexts = [
    'Lagi butuh layanan kesehatan apa hari ini?',
    'Cari perawat yang siap datang ke rumah...',
    'Butuh fisioterapi yang nyaman di rumah?',
    'Cari medical check-up tanpa ribet...',
    'Mau konsultasi dokter dengan lebih tenang?',
  ];

  int _currentTextIndex = 0;
  String _displayedText = '';
  Timer? _typingTimer;
  bool _isTyping = true;

  @override
  void initState() {
    super.initState();
    _startTypingAnimation();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    super.dispose();
  }

  void _startTypingAnimation() {
    int charIndex = 0;
    final currentText = _searchTexts[_currentTextIndex];

    _typingTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_isTyping) {
          if (charIndex <= currentText.length) {
            _displayedText = currentText.substring(0, charIndex);
            charIndex++;
          } else {
            timer.cancel();
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) {
                _isTyping = false;
                _startDeletingAnimation();
              }
            });
          }
        }
      });
    });
  }

  void _startDeletingAnimation() {
    final currentText = _searchTexts[_currentTextIndex];
    int charIndex = currentText.length;

    _typingTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (charIndex > 0) {
          _displayedText = currentText.substring(0, charIndex);
          charIndex--;
        } else {
          timer.cancel();
          _currentTextIndex = (_currentTextIndex + 1) % _searchTexts.length;
          _isTyping = true;
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _startTypingAnimation();
            }
          });
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final bannerHeight = (screenWidth * 0.5).clamp(180.0, 250.0);
        final horizontalPadding = screenWidth > 600 ? 32.0 : 16.0;

        return Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                margin: const EdgeInsets.only(bottom: 26),
                height: bannerHeight,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  image: const DecorationImage(
                    image: NetworkImage(
                      'https://images.unsplash.com/photo-1631217868264-e5b90bb7e133?w=800',
                    ),
                    fit: BoxFit.cover,
                  ),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                      color: Colors.black.withValues(alpha: 0.15),
                    ),
                  ],
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.2),
                        Colors.black.withValues(alpha: 0.5),
                      ],
                    ),
                  ),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Kami hadir untuk merawat Anda dan keluarga dengan hangat, tenang, dan sepenuh hati.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontSize: screenWidth > 600 ? 22 : 17,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              Positioned(
                left: screenWidth > 600 ? 40 : 16,
                right: screenWidth > 600 ? 40 : 16,
                bottom: 0,
                height: 52,
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SearchPage()),
                    );
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                          color: Colors.black.withValues(alpha: 0.1),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            _displayedText,
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              color: Colors.black38,
                              fontSize: screenWidth > 600 ? 17 : 15,
                            ),
                          ),
                        ),
                        const Icon(
                          IconlyLight.search,
                          color: Colors.black38,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

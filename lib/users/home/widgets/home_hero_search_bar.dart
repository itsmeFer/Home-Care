import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/users/search_page.dart';

/// Floating rounded search bar with isolated typing micro-animation.
/// Isolates the 100ms timer rebuilds so parent hero header does not re-render.
class HomeHeroSearchBar extends StatelessWidget {
  final bool isTablet;

  const HomeHeroSearchBar({
    super.key,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: isTablet ? 32 : 18,
      right: isTablet ? 32 : 18,
      bottom: 0,
      height: 52.0,
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
            borderRadius: BorderRadius.circular(26),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                offset: const Offset(0, 4),
                color: Colors.black.withValues(alpha: 0.08),
              ),
            ],
          ),
          padding: const EdgeInsets.only(left: 18, right: 6),
          child: Row(
            children: [
              const Icon(
                IconlyLight.search,
                color: Color(0xFF94A3B8),
                size: 20,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: _AnimatedSearchPlaceholder(),
              ),
              // Filter slider button
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: HCColor.primaryLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: HCColor.primary.withValues(alpha: 0.25),
                    width: 1,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    IconlyLight.filter,
                    color: HCColor.primary,
                    size: 19,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Standalone micro-widget that handles the typing & deleting animation.
/// Keeps rebuilds localized to a single 1-line Text widget.
class _AnimatedSearchPlaceholder extends StatefulWidget {
  const _AnimatedSearchPlaceholder();

  @override
  State<_AnimatedSearchPlaceholder> createState() =>
      _AnimatedSearchPlaceholderState();
}

class _AnimatedSearchPlaceholderState
    extends State<_AnimatedSearchPlaceholder> {
  static const List<String> _searchTexts = [
    'Lagi butuh layanan kesehatan apa?',
    'Cari perawat siap datang ke rumah...',
    'Butuh fisioterapi nyaman di rumah?',
    'Cari medical check-up tanpa ribet...',
    'Mau konsultasi dokter lebih tenang?',
  ];

  int _currentTextIndex = 0;
  String _displayedText = '';
  Timer? _timer;
  bool _isTyping = true;

  @override
  void initState() {
    super.initState();
    _startTyping();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTyping() {
    int charIndex = 0;
    final currentText = _searchTexts[_currentTextIndex];

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_isTyping) {
        if (charIndex <= currentText.length) {
          setState(() {
            _displayedText = currentText.substring(0, charIndex);
          });
          charIndex++;
        } else {
          timer.cancel();
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              _isTyping = false;
              _startDeleting();
            }
          });
        }
      }
    });
  }

  void _startDeleting() {
    final currentText = _searchTexts[_currentTextIndex];
    int charIndex = currentText.length;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (charIndex > 0) {
        setState(() {
          _displayedText = currentText.substring(0, charIndex);
        });
        charIndex--;
      } else {
        timer.cancel();
        _currentTextIndex = (_currentTextIndex + 1) % _searchTexts.length;
        _isTyping = true;
        Future.delayed(const Duration(milliseconds: 400), () {
          if (mounted) {
            _startTyping();
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _displayedText.isNotEmpty
          ? _displayedText
          : 'Cari layanan medis, perawat...',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        fontFamily: 'Poppins',
        color: Color(0xFF94A3B8),
        fontSize: 13.5,
        fontWeight: FontWeight.w400,
      ),
    );
  }
}

import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:home_care/screen/login.dart';
import 'package:home_care/users/HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  bool _isResending = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  Timer? _pollingTimer; // ✅ Timer untuk polling

  static const String baseUrl = 'http://147.93.81.243/api';
  static const int cooldownDuration = 60;

  @override
  void initState() {
    super.initState();
    // ✅ Mulai polling setiap 5 detik
    _startPolling();
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _pollingTimer?.cancel(); // ✅ Cancel polling saat dispose
    super.dispose();
  }

  // ✅ POLLING: Cek status verifikasi setiap 5 detik
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkVerificationStatus();
    });
  }

  // ✅ CEK STATUS VERIFIKASI
  Future<void> _checkVerificationStatus() async {
    try {
      final url = Uri.parse('$baseUrl/check-verification-status');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': widget.email}),
      );

      if (res.statusCode == 200) {
        final body = json.decode(res.body);
        
        // Jika email sudah verified
        if (body['verified'] == true) {
          _pollingTimer?.cancel(); // Stop polling
          
          if (!mounted) return;
          
          // Simpan token jika ada
          if (body['token'] != null) {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('token', body['token']);
            await prefs.setString('auth_token', body['token']);
            
            // Simpan data user
            if (body['data'] != null) {
              final data = body['data'] as Map<String, dynamic>;
              await prefs.setInt('user_id', data['user_id'] ?? 0);
              await prefs.setInt('pasien_id', data['pasien_id'] ?? 0);
              await prefs.setString('nama_lengkap', data['nama_lengkap'] ?? '');
              await prefs.setString('email', data['email'] ?? '');
              await prefs.setString('role', data['role'] ?? 'pasien');
            }
          }
          
          // Tampilkan success message
          _showSuccessDialog();
        }
      }
    } catch (e) {
      // Silent fail - jangan ganggu user
      print('Polling error: $e');
    }
  }

  // ✅ DIALOG SUCCESS
  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 80,
              width: 80,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 50,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Email Terverifikasi!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1E3A8A),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Selamat datang! Anda akan diarahkan ke halaman utama.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );

    // Auto redirect setelah 2 detik
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    });
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _startCooldown() {
    setState(() => _cooldownSeconds = cooldownDuration);

    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds > 0) {
        setState(() => _cooldownSeconds--);
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _resendVerification() async {
    if (_cooldownSeconds > 0) {
      _showError('Tunggu $_cooldownSeconds detik sebelum kirim ulang');
      return;
    }

    setState(() => _isResending = true);

    try {
      final url = Uri.parse('$baseUrl/resend-verification');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': widget.email}),
      );

      setState(() => _isResending = false);

      final body = json.decode(res.body);

      if (res.statusCode == 200) {
        _showSuccess(body['message'] ?? 'Email verifikasi telah dikirim ulang');
        _startCooldown();
      } else {
        _showError(body['message'] ?? 'Gagal mengirim ulang email');
      }
    } catch (e) {
      setState(() => _isResending = false);
      _showError('Terjadi kesalahan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool canResend = _cooldownSeconds == 0 && !_isResending;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF3B82F6),
              Color(0xFF1E3A8A),
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.06,
              vertical: size.height * 0.04,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: size.height * 0.05),

                // Icon Email
                Center(
                  child: Container(
                    height: size.height * 0.14,
                    width: size.height * 0.14,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                          color: Colors.black.withOpacity(.2),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.email_outlined,
                      size: size.height * 0.08,
                      color: const Color(0xFF1E3A8A),
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.03),

                // Title
                Text(
                  'Verifikasi Email Anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: size.height * 0.032,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),

                SizedBox(height: size.height * 0.02),

                // Email yang dikirim
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Link verifikasi telah dikirim ke:',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.email,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: size.height * 0.025),

                // Instruksi
                Container(
                  padding: EdgeInsets.all(size.width * 0.05),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                        color: Colors.black.withOpacity(.15),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '📧 Langkah Verifikasi:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E3A8A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStep('1', 'Buka email Anda (cek folder Inbox atau Spam)'),
                      const SizedBox(height: 12),
                      _buildStep('2', 'Klik link "Verifikasi Email Saya"'),
                      const SizedBox(height: 12),
                      _buildStep('3', 'Anda akan otomatis login setelah verifikasi'),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.amber.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: const [
                            Icon(
                              Icons.info_outline,
                              color: Colors.amber,
                              size: 20,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Link akan kadaluarsa dalam 24 jam',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: size.height * 0.03),

                // Button Resend Email
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: canResend ? Colors.white : Colors.grey[300],
                      foregroundColor: canResend ? const Color(0xFF1E3A8A) : Colors.grey[600],
                      elevation: canResend ? 4 : 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: canResend ? _resendVerification : null,
                    icon: _isResending
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Color(0xFF1E3A8A),
                            ),
                          )
                        : Icon(
                            _cooldownSeconds > 0 ? Icons.timer : Icons.refresh,
                            size: 24,
                          ),
                    label: Text(
                      _isResending
                          ? 'Mengirim...'
                          : _cooldownSeconds > 0
                              ? 'Tunggu $_cooldownSeconds detik'
                              : 'Kirim Ulang Email',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Button Back to Login
                TextButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginPage(),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Kembali ke Login',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      decoration: TextDecoration.underline,
                      decorationColor: Colors.white,
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 24,
          width: 24,
          decoration: const BoxDecoration(
            color: Color(0xFF1E3A8A),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
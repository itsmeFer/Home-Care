import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  
  bool _isLoading = false;
  bool _emailSent = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  static const String baseUrl = 'http://192.168.1.5:8000/api';
  static const int cooldownDuration = 60;

  @override
  void dispose() {
    _emailController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
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

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    if (_cooldownSeconds > 0) {
      _showError('Tunggu $_cooldownSeconds detik sebelum kirim ulang');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('$baseUrl/forgot-password');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': _emailController.text.trim()}),
      );

      final body = json.decode(res.body);

      setState(() => _isLoading = false);

      if (res.statusCode == 200) {
        setState(() => _emailSent = true);
        _showSuccess(body['message'] ?? 'Link reset password telah dikirim ke email Anda');
        _startCooldown();
      } else {
        _showError(body['message'] ?? 'Gagal mengirim link reset password');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Terjadi kesalahan: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final bool canSend = _cooldownSeconds == 0 && !_isLoading;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3A8A),
              Color(0xFF3B82F6),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: SizedBox(
              height: size.height - MediaQuery.of(context).padding.top,
              child: Column(
                children: [
                  // Header dengan Back Button
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // Content Area
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon
                            Container(
                              height: 100,
                              width: 100,
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
                              child: Center(
                                child: Icon(
                                  _emailSent ? Icons.mark_email_read : Icons.lock_reset,
                                  size: 50,
                                  color: const Color(0xFF1E3A8A),
                                ),
                              ),
                            ),

                            const SizedBox(height: 30),

                            // Title
                            Text(
                              _emailSent ? 'Email Terkirim! 📧' : 'Lupa Password?',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Description
                            Text(
                              _emailSent
                                  ? 'Kami telah mengirim link reset password ke email Anda. Silakan cek inbox atau folder spam.'
                                  : 'Masukkan email Anda yang terdaftar, kami akan mengirimkan link untuk reset password.',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                color: Colors.white70,
                                height: 1.5,
                              ),
                            ),

                            const SizedBox(height: 40),

                            if (!_emailSent) ...[
                              // Email Input
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      blurRadius: 20,
                                      offset: const Offset(0, 10),
                                      color: Colors.black.withOpacity(.15),
                                    ),
                                  ],
                                ),
                                child: TextFormField(
                                  controller: _emailController,
                                  keyboardType: TextInputType.emailAddress,
                                  style: const TextStyle(fontSize: 16),
                                  decoration: InputDecoration(
                                    hintText: 'Email',
                                    hintStyle: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 16,
                                    ),
                                    prefixIcon: const Icon(
                                      Icons.email_outlined,
                                      color: Color(0xFF1E3A8A),
                                      size: 24,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: Colors.white,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 18,
                                    ),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Email tidak boleh kosong';
                                    }
                                    if (!value.contains('@')) {
                                      return 'Format email tidak valid';
                                    }
                                    return null;
                                  },
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Send Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF1E3A8A),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    disabledBackgroundColor: Colors.white.withOpacity(0.5),
                                    disabledForegroundColor: Colors.grey[600],
                                  ),
                                  onPressed: canSend ? _sendResetLink : null,
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 24,
                                          width: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Color(0xFF1E3A8A),
                                          ),
                                        )
                                      : Text(
                                          _cooldownSeconds > 0
                                              ? 'Tunggu $_cooldownSeconds detik'
                                              : 'Kirim Link Reset Password',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                            letterSpacing: 0.3,
                                          ),
                                        ),
                                ),
                              ),
                            ] else ...[
                              // Success Info Box
                              Container(
                                padding: const EdgeInsets.all(24),
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
                                  children: [
                                    const Text(
                                      'Link Terkirim!',
                                      style: TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Color(0xFF1E3A8A),
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      _emailController.text,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Color(0xFF3B82F6),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
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
                                            Icons.timer,
                                            color: Colors.amber,
                                            size: 20,
                                          ),
                                          SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              'Link akan kadaluarsa dalam 1 jam',
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

                              const SizedBox(height: 24),

                              // Resend Button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.white,
                                    foregroundColor: const Color(0xFF1E3A8A),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    disabledBackgroundColor: Colors.white.withOpacity(0.5),
                                    disabledForegroundColor: Colors.grey[600],
                                  ),
                                  onPressed: canSend ? _sendResetLink : null,
                                  icon: Icon(
                                    _cooldownSeconds > 0 ? Icons.timer : Icons.refresh,
                                    size: 24,
                                  ),
                                  label: Text(
                                    _cooldownSeconds > 0
                                        ? 'Tunggu $_cooldownSeconds detik'
                                        : 'Kirim Ulang Link',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ),
                              ),
                            ],

                            const SizedBox(height: 24),

                            // Back to Login
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                              ),
                              child: const Text(
                                'Kembali ke Login',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.white,
                                  decorationThickness: 2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
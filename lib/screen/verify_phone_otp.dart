import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_care/users/HomePage.dart';

class VerifyPhoneOTPPage extends StatefulWidget {
  final String verificationId;
  final String phoneNumber;
  final Map<String, dynamic> userData;

  const VerifyPhoneOTPPage({
    super.key,
    required this.verificationId,
    required this.phoneNumber,
    required this.userData,
  });

  @override
  State<VerifyPhoneOTPPage> createState() => _VerifyPhoneOTPPageState();
}

class _VerifyPhoneOTPPageState extends State<VerifyPhoneOTPPage> {
  final _otpC = TextEditingController();
  bool _isLoading = false;

  static const String baseUrl = 'http://192.168.1.5:8000/api';

  @override
  void dispose() {
    _otpC.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.green),
    );
  }

  // Register ke Laravel setelah OTP verified
  Future<void> _registerToLaravel() async {
    try {
      final url = Uri.parse('$baseUrl/register');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          ...widget.userData,
          'is_verified': true, // Sudah verified via Firebase
        }),
      );

      if (res.statusCode == 200 || res.statusCode == 201) {
        final body = json.decode(res.body);

        // Simpan token
        final prefs = await SharedPreferences.getInstance();
        if (body['token'] != null) {
          await prefs.setString('auth_token', body['token']);
        }

        final data = body['data'] ?? {};
        if (data['id'] != null) {
          await prefs.setInt('pasien_id', (data['id'] as num).toInt());
        }
        if (data['nama_lengkap'] != null) {
          await prefs.setString('nama_lengkap', data['nama_lengkap']);
        }

        if (!mounted) return;

        _showSuccess('Registrasi berhasil!');

        // Navigate to home
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (route) => false,
        );
      } else {
        _showError('Gagal registrasi ke server');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  // Verifikasi OTP
  Future<void> _verifyOTP() async {
    if (_otpC.text.trim().isEmpty) {
      _showError('Mohon isi kode OTP');
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Buat credential dari OTP
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: widget.verificationId,
        smsCode: _otpC.text.trim(),
      );

      // Sign in dengan credential
      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;

      _showSuccess('Verifikasi berhasil!');

      // Register ke Laravel
      await _registerToLaravel();
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      if (e.code == 'invalid-verification-code') {
        _showError('Kode OTP salah');
      } else {
        _showError('Verifikasi gagal: ${e.message}');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Terjadi kesalahan: $e');
    }
  }

  // Resend OTP
  Future<void> _resendOTP() async {
    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: widget.phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await FirebaseAuth.instance.signInWithCredential(credential);
          if (mounted) {
            _showSuccess('Verifikasi berhasil!');
            await _registerToLaravel();
          }
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          _showError('Gagal kirim OTP: ${e.message}');
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() => _isLoading = false);
          _showSuccess('Kode OTP baru telah dikirim');
        },
        codeAutoRetrievalTimeout: (String verificationId) {},
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showError('Gagal kirim ulang OTP: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

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
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Icon
                Container(
                  height: 100,
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.sms_outlined,
                    size: 50,
                    color: Color(0xFF1E3A8A),
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                const Text(
                  'Verifikasi OTP',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Kode OTP telah dikirim ke\n${widget.phoneNumber}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 40),

                // Card Form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Label
                      Text(
                        'KODE OTP (6 DIGIT)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[600],
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Input OTP
                      TextField(
                        controller: _otpC,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        maxLength: 6,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 8,
                        ),
                        decoration: InputDecoration(
                          hintText: '000000',
                          hintStyle: TextStyle(color: Colors.grey[300]),
                          filled: true,
                          fillColor: const Color(0xFFB8C5D6).withOpacity(0.3),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 20,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFF1E3A8A),
                              width: 2,
                            ),
                          ),
                          counterText: '',
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Button Verify
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E3A8A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: _isLoading ? null : _verifyOTP,
                          child: _isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  'Verifikasi',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Resend OTP
                      TextButton(
                        onPressed: _isLoading ? null : _resendOTP,
                        child: Text(
                          'Kirim Ulang Kode OTP',
                          style: TextStyle(
                            color: const Color(0xFF1E3A8A),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
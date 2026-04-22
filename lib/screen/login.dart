import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// ROUTING SESUAI ROLE
import 'package:home_care/admin/dashboard.dart';
import 'package:home_care/kordinator/dashboard.dart';
import 'package:home_care/manager/manager_dashboard.dart';
import 'package:home_care/perawat/dashboard.dart';
import 'package:home_care/direktur/direktur_dashboard.dart';
import 'package:home_care/ITDev/dashboard_it_page.dart';
import 'package:home_care/screen/forgot_password_screen.dart';
import 'package:home_care/users/HomePage.dart';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_care/screen/register.dart';
import 'package:home_care/services/firebase_notification_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameC = TextEditingController();
  final _passwordC = TextEditingController();

  bool _isLoading = false;
  bool _obscure = true;
  bool _rememberMe = false;

  static const String baseUrl = 'http://192.168.1.5:8000/api';

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void dispose() {
    _usernameC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUsername = prefs.getString('saved_username');

    if (savedUsername != null && savedUsername.isNotEmpty) {
      setState(() {
        _usernameC.text = savedUsername;
        _rememberMe = true;
      });
    }
  }

  Future<void> _doLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final res = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'username': _usernameC.text.trim(),
          'password': _passwordC.text.trim(),
        }),
      );

      if (!mounted) return;

      if (res.statusCode != 200 && res.statusCode != 201) {
        String msg = 'Login gagal (${res.statusCode})';
        try {
          final b = json.decode(res.body);
          if (b['message'] != null) msg = b['message'];
        } catch (_) {}
        _showError(msg);
        return;
      }

      final body = json.decode(res.body);

      if (body['success'] != true) {
        _showError(body['message'] ?? 'Login gagal');
        return;
      }

      final prefs = await SharedPreferences.getInstance();

      final token = body['token']?.toString() ?? '';
      if (token.isEmpty) {
        _showError('Token tidak ditemukan');
        return;
      }

      // SIMPAN TOKEN KE SHARED PREFERENCES
      await prefs.setString('auth_token', token);

      String role = 'pasien';

      if (body['data'] != null) {
        final data = body['data'] as Map<String, dynamic>;

        await prefs.setInt('user_id', (data['user_id'] ?? 0) as int);
        await prefs.setInt('pasien_id', (data['pasien_id'] ?? 0) as int);
        await prefs.setInt('perawat_id', (data['perawat_id'] ?? 0) as int);
        await prefs.setInt('koordinator_id', (data['koordinator_id'] ?? 0) as int);

        await prefs.setString(
          'nama_lengkap',
          (data['nama_lengkap'] ?? '').toString(),
        );
        await prefs.setString(
          'email',
          (data['email'] ?? '').toString(),
        );
        await prefs.setString(
          'no_rekam_medis',
          (data['no_rekam_medis'] ?? '').toString(),
        );

        if (data['role'] != null) {
          role = data['role'].toString();
          await prefs.setString('role', role);
        }
      }

      if (_rememberMe) {
        await prefs.setString('saved_username', _usernameC.text.trim());
      } else {
        await prefs.remove('saved_username');
      }

      if (!kIsWeb) {
        try {
          final notifService = FirebaseNotificationService();
          await notifService.initialize();
          await notifService.syncTokenToBackend();
          debugPrint('✅ Firebase Notification initialized after login');
        } catch (e) {
          debugPrint('❌ Notification init after login error: $e');
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login berhasil'),
          backgroundColor: Colors.green,
        ),
      );

      Widget nextPage;

      switch (role.toLowerCase()) {
        case 'admin':
          nextPage = const AdminDashboard();
          break;
        case 'koordinator':
          nextPage = const KoordinatorDashboard();
          break;
        case 'perawat':
          nextPage = const PerawatDashboard();
          break;
        case 'direktur':
          nextPage = const DirekturDashboard();
          break;
        case 'manager':
          nextPage = const ManagerDashboard();
          break;
        case 'it':
          nextPage = const ITDevDashboard();
          break;
        case 'pasien':
          nextPage = const HomePage();
          break;
        default:
          debugPrint('⚠️ Role tidak dikenali: $role, menggunakan HomePage');
          nextPage = const HomePage();
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => nextPage),
      );
    } catch (e) {
      if (!mounted) return;
      _showError('Terjadi kesalahan: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color bcaBlue = Color(0xFF0066AE);
    const Color bcaBlueDark = Color(0xFF003D82);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bcaBlue, bcaBlueDark],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 50),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/images/home_nobg.png',
                    height: 90,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 30),
                const Text(
                  'Selamat Datang',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Silakan masuk untuk melanjutkan',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white70,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(28),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1.5,
                              ),
                            ),
                            child: TextFormField(
                              controller: _usernameC,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(fontSize: 15),
                              decoration: InputDecoration(
                                hintText: 'Masukkan email Anda',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 15,
                                ),
                                prefixIcon: const Icon(
                                  Icons.email_outlined,
                                  color: bcaBlue,
                                  size: 22,
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Email wajib diisi';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Kata Sandi',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[700],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F7FA),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.grey[200]!,
                                width: 1.5,
                              ),
                            ),
                            child: TextFormField(
                              controller: _passwordC,
                              obscureText: _obscure,
                              style: const TextStyle(fontSize: 15),
                              decoration: InputDecoration(
                                hintText: 'Masukkan kata sandi',
                                hintStyle: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 15,
                                ),
                                prefixIcon: const Icon(
                                  Icons.lock_outline,
                                  color: bcaBlue,
                                  size: 22,
                                ),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscure
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    color: Colors.grey[600],
                                    size: 22,
                                  ),
                                  onPressed: () =>
                                      setState(() => _obscure = !_obscure),
                                ),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 16,
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Kata sandi wajib diisi';
                                }
                                if (v.trim().length < 4) {
                                  return 'Minimal 4 karakter';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Transform.scale(
                                scale: 0.9,
                                child: Checkbox(
                                  value: _rememberMe,
                                  onChanged: (val) => setState(
                                    () => _rememberMe = val ?? false,
                                  ),
                                  activeColor: bcaBlue,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              Text(
                                'Ingat saya',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const Spacer(),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ForgotPasswordScreen(),
                                    ),
                                  );
                                },
                                child: const Text('Lupa Password?'),
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Container(
                            width: double.infinity,
                            height: 54,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [bcaBlue, bcaBlueDark],
                              ),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: bcaBlue.withOpacity(0.4),
                                  blurRadius: 12,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _doLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        valueColor: AlwaysStoppedAnimation(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : const Text(
                                      'MASUK',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(child: Divider(color: Colors.grey[300])),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  'atau',
                                  style: TextStyle(
                                    color: Colors.grey[500],
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              Expanded(child: Divider(color: Colors.grey[300])),
                            ],
                          ),
                          const SizedBox(height: 24),
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Belum punya akun? ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterPage(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Daftar Sekarang',
                                    style: TextStyle(
                                      color: bcaBlue,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
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
                const SizedBox(height: 30),
                Text(
                  'Prima Home Care',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
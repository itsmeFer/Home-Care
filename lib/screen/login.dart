import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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

  static const String baseUrl = 'https://homecare.primamadanitalenta.my.id/api';

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

      await prefs.setString('auth_token', token);

      String role = 'pasien';

      if (body['data'] != null) {
        final data = body['data'] as Map<String, dynamic>;

        await prefs.setInt('user_id', (data['user_id'] ?? 0) as int);
        await prefs.setInt('pasien_id', (data['pasien_id'] ?? 0) as int);
        await prefs.setInt('perawat_id', (data['perawat_id'] ?? 0) as int);
        await prefs.setInt(
          'koordinator_id',
          (data['koordinator_id'] ?? 0) as int,
        );

        await prefs.setString(
          'nama_lengkap',
          (data['nama_lengkap'] ?? '').toString(),
        );
        await prefs.setString('email', (data['email'] ?? '').toString());
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
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF2196F3),
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [

                      Expanded(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40.0),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/images/home_nobg.png',
                                height: 80,
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),

                      Container(
                        width: double.infinity,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(40),
                            topRight: Radius.circular(40),
                          ),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 500),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                32,
                                40,
                                32,
                                40,
                              ),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Masuk',
                                      style: TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'Silakan masuk ke akun Anda',
                                      style: TextStyle(
                                        fontSize: 15,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                    const SizedBox(height: 32),
                                    const Text(
                                      'Email',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _usernameC,
                                      keyboardType: TextInputType.emailAddress,
                                      style: const TextStyle(fontSize: 15),
                                      decoration: InputDecoration(
                                        hintText: 'youremail@yahoo.com',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 16,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF2196F3),
                                          ),
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty)
                                          return 'Email wajib diisi';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    const Text(
                                      'Kata Sandi',
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextFormField(
                                      controller: _passwordC,
                                      obscureText: _obscure,
                                      style: const TextStyle(fontSize: 15),
                                      decoration: InputDecoration(
                                        hintText: '••••••••',
                                        hintStyle: TextStyle(
                                          color: Colors.grey[400],
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 20,
                                              vertical: 16,
                                            ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            24,
                                          ),
                                          borderSide: const BorderSide(
                                            color: Color(0xFF2196F3),
                                          ),
                                        ),
                                        suffixIcon: Padding(
                                          padding: const EdgeInsets.only(
                                            right: 8.0,
                                          ),
                                          child: IconButton(
                                            icon: Icon(
                                              _obscure
                                                  ? Icons
                                                      .visibility_off_outlined
                                                  : Icons.visibility_outlined,
                                              color: Colors.grey[600],
                                              size: 22,
                                            ),
                                            onPressed:
                                                () => setState(
                                                  () => _obscure = !_obscure,
                                                ),
                                          ),
                                        ),
                                      ),
                                      validator: (v) {
                                        if (v == null || v.trim().isEmpty)
                                          return 'Kata sandi wajib diisi';
                                        if (v.trim().length < 4)
                                          return 'Minimal 4 karakter';
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 12),
                                    Align(
                                      alignment: Alignment.centerRight,
                                      child: GestureDetector(
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder:
                                                  (_) =>
                                                      const ForgotPasswordScreen(),
                                            ),
                                          );
                                        },
                                        child: const Text(
                                          'Lupa Kata Sandi?',
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 56,
                                      child: ElevatedButton(
                                        onPressed: _isLoading ? null : _doLogin,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(
                                            0xFF1E1E1E,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              28,
                                            ),
                                          ),
                                          elevation: 0,
                                        ),
                                        child:
                                            _isLoading
                                                ? const SizedBox(
                                                  width: 24,
                                                  height: 24,
                                                  child: CircularProgressIndicator(
                                                    strokeWidth: 2.5,
                                                    valueColor:
                                                        AlwaysStoppedAnimation(
                                                          Colors.white,
                                                        ),
                                                  ),
                                                )
                                                : const Text(
                                                  'MASUK',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                      ),
                                    ),
                                    const SizedBox(height: 28),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Divider(
                                            color: Colors.grey[300],
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 16,
                                          ),
                                          child: Text(
                                            'ATAU',
                                            style: TextStyle(
                                              color: Colors.grey[500],
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Divider(
                                            color: Colors.grey[300],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 24),
                                    Center(
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "Belum punya akun? ",
                                            style: TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.push(
                                                context,
                                                MaterialPageRoute(
                                                  builder:
                                                      (_) =>
                                                          const RegisterPage(),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              'Daftar',
                                              style: TextStyle(
                                                color: Colors.black,
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
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
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

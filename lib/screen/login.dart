import 'dart:convert';
import 'package:flutter/material.dart';

// ROUTING SESUAI ROLE
import 'package:home_care/admin/dashboard.dart';
import 'package:home_care/kordinator/dashboard.dart';
import 'package:home_care/users/HomePage.dart';
import 'package:home_care/perawat/dashboard.dart'; // ⬅️ TAMBAHAN

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_care/screen/register.dart';

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

  static const String baseUrl = 'http://192.168.1.6:8000/api';

  @override
  void dispose() {
    _usernameC.dispose();
    _passwordC.dispose();
    super.dispose();
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

      // ===================== SIMPAN TOKEN & PROFIL ========================
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', body['token']); // token dari API

      String role = 'pasien';

      if (body['data'] != null) {
        final data = body['data'] as Map<String, dynamic>;

        // user_id
        if (data['user_id'] != null) {
          await prefs.setInt('user_id', data['user_id'] as int);
        } else {
          await prefs.setInt('user_id', 0);
        }

        // pasien_id
        if (data['pasien_id'] != null) {
          await prefs.setInt('pasien_id', data['pasien_id'] as int);
        } else {
          await prefs.setInt('pasien_id', 0);
        }

        // ⬇️⬇️ TAMBAHAN: perawat_id dari API
        // ⬇️⬇️ TAMBAHAN: perawat_id dari API
        if (data['perawat_id'] != null) {
          await prefs.setInt('perawat_id', data['perawat_id'] as int);
        } else {
          await prefs.setInt('perawat_id', 0);
        }

        // ⬇️⬇️ TAMBAHAN: koordinator_id dari API
        if (data['koordinator_id'] != null) {
          await prefs.setInt('koordinator_id', data['koordinator_id'] as int);
        } else {
          await prefs.setInt('koordinator_id', 0);
        }

        await prefs.setString(
          'nama_lengkap',
          (data['nama_lengkap'] ?? '') as String,
        );
        await prefs.setString('email', (data['email'] ?? '') as String);
        await prefs.setString(
          'no_rekam_medis',
          (data['no_rekam_medis'] ?? '') as String,
        );

        // Ambil ROLE langsung dari data
        if (data['role'] != null) {
          role = data['role'] as String;
          await prefs.setString('role', role);
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login berhasil'),
          backgroundColor: Colors.green,
        ),
      );

      // ===================== ROUTING SESUAI ROLE ==========================
      Widget nextPage;

      switch (role) {
        case 'admin':
          nextPage = const AdminDashboard();
          break;
        case 'koordinator':
          nextPage = const KoordinatorDashboard();
          break;
        case 'perawat': // ⬅️ TAMBAHAN PERAWAT
          nextPage = const PerawatDashboard();
          break;
        default:
          // pasien atau apapun yang tidak dikenal → ke HomePage (user)
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
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF0BA5A7), Color(0xFF088088)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                        color: Colors.black.withOpacity(.15),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.local_hospital,
                    size: 40,
                    color: Colors.white,
                  ),
                ),

                const SizedBox(height: 16),
                Text(
                  'Masuk ke Home Care',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 18,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                        color: Colors.black.withOpacity(.06),
                      ),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _usernameC,
                          decoration: const InputDecoration(
                            labelText: 'Email / No. HP',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              v!.isEmpty ? 'Mohon isi email / no HP' : null,
                        ),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _passwordC,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Kata Sandi',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.lock_outline),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                setState(() => _obscure = !_obscure);
                              },
                            ),
                          ),
                          validator: (v) =>
                              v!.length < 4 ? 'Minimal 4 karakter' : null,
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0BA5A7),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: _isLoading ? null : _doLogin,
                            child: _isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white,
                                  )
                                : const Text(
                                    'Masuk',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 18),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const RegisterPage()),
                    );
                  },
                  child: const Text('Belum punya akun? Daftar dulu'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

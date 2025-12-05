import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'package:home_care/screen/login.dart';
import 'package:home_care/users/HomePage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final _namaC = TextEditingController();
  final _noHpC = TextEditingController();
  final _emailC = TextEditingController();
  final _passwordC = TextEditingController();
  final _password2C = TextEditingController();

  bool _isLoading = false;

  static const String baseUrl = 'http://192.168.1.6:8000/api';

  @override
  void dispose() {
    _namaC.dispose();
    _noHpC.dispose();
    _emailC.dispose();
    _passwordC.dispose();
    _password2C.dispose();
    super.dispose();
  }

  Future<void> _doRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final url = Uri.parse('$baseUrl/register');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'nama_lengkap': _namaC.text.trim(),
          'no_hp': _noHpC.text.trim(),
          'email': _emailC.text.trim(),
          'password': _passwordC.text,
          'password_confirmation': _password2C.text,
          // ❌ field lain (NIK, alamat, kota, provinsi, jenis_kelamin, tanggal_lahir) tidak dikirim
        }),
      );

      if (!mounted) return;

      if (res.statusCode != 200 && res.statusCode != 201) {
        String msg = 'Gagal registrasi, kode ${res.statusCode}';
        try {
          final errBody = json.decode(res.body);
          if (errBody is Map) {
            if (errBody['message'] != null) {
              msg = errBody['message'];
            } else if (errBody['errors'] != null) {
              final errors = errBody['errors'] as Map<String, dynamic>;
              final firstKey = errors.keys.first;
              final firstErrorList = errors[firstKey];
              if (firstErrorList is List && firstErrorList.isNotEmpty) {
                msg = firstErrorList.first.toString();
              }
            }
          }
        } catch (_) {}
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final body = json.decode(res.body);
      final success = body['success'] == true;

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(body['message'] ?? 'Registrasi gagal'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Response dari AuthController@register (versi terbaru):
      // {
      //   "success": true,
      //   "message": "Registrasi berhasil.",
      //   "token": "xxxxx",
      //   "data": {
      //      "id": 3,
      //      "nama_lengkap": "...",
      //      "no_hp": "...",
      //      "email": "...",
      //      "no_rekam_medis": "RM-...."
      //   }
      // }

      final token = body['token'];
      final data = body['data'] ?? {};

      final pasienId = data['id'];
      final namaLengkap = data['nama_lengkap'];
      final noRekamMedis = data['no_rekam_medis'];

      // simpan ke SharedPreferences → anggap langsung login
      final prefs = await SharedPreferences.getInstance();
      if (token != null) {
        await prefs.setString('auth_token', token);
      }
      if (pasienId != null) {
        await prefs.setInt('pasien_id', pasienId);
      }
      if (namaLengkap != null) {
        await prefs.setString('nama_lengkap', namaLengkap);
      }
      if (noRekamMedis != null) {
        await prefs.setString('no_rekam_medis', noRekamMedis);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(body['message'] ?? 'Registrasi berhasil'),
          backgroundColor: Colors.green,
        ),
      );

      // LANGSUNG ke HomePage (auto login)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: HCColor.bg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header / Logo
                Container(
                  height: 70,
                  width: 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [HCColor.primary, HCColor.primaryDark],
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
                    Icons.person_add_alt_1,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Daftar Akun Pasien',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Isi data singkat untuk mulai menggunakan layanan Home Care.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: HCColor.textMuted,
                  ),
                ),
                const SizedBox(height: 20),

                // FORM CARD
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
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
                        // NAMA LENGKAP
                        TextFormField(
                          controller: _namaC,
                          decoration: const InputDecoration(
                            labelText: 'Nama Lengkap',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Mohon isi nama lengkap';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // EMAIL
                        TextFormField(
                          controller: _emailC,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Mohon isi email';
                            }
                            final email = v.trim();
                            if (!email.contains('@') || !email.contains('.')) {
                              return 'Format email tidak valid';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // NO HP
                        TextFormField(
                          controller: _noHpC,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            labelText: 'No. HP / WhatsApp',
                            prefixIcon: Icon(Icons.phone_iphone),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Mohon isi nomor HP';
                            }
                            if (v.trim().length < 8) {
                              return 'Nomor terlalu pendek';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // PASSWORD
                        TextFormField(
                          controller: _passwordC,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Kata Sandi',
                            prefixIcon: Icon(Icons.lock_outline),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Mohon isi kata sandi';
                            }
                            if (v.length < 6) {
                              return 'Minimal 6 karakter';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 12),

                        // ULANGI PASSWORD
                        TextFormField(
                          controller: _password2C,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Ulangi Kata Sandi',
                            prefixIcon: Icon(Icons.lock_reset),
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            if (v == null || v.isEmpty) {
                              return 'Mohon ulangi kata sandi';
                            }
                            if (v != _passwordC.text) {
                              return 'Kata sandi tidak sama';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: HCColor.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            onPressed: _isLoading ? null : _doRegister,
                            child: _isLoading
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Daftar',
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
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                    );
                  },
                  child: const Text(
                    'Sudah punya akun? Masuk',
                    style: TextStyle(fontWeight: FontWeight.w600),
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

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:home_care/screen/login.dart';

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
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  static const String baseUrl = 'http://192.168.1.5:8000/api';

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
        }),
      );

      if (!mounted) return;

      final body = json.decode(res.body);

      // ✅ HANDLE SUCCESS
      if (res.statusCode == 200 || res.statusCode == 201) {
        if (body['success'] == true) {
          _showVerificationDialog();
          return;
        }
      }

      // ❌ HANDLE ERROR RESPONSES
      String errorMessage = 'Registrasi gagal';

      if (body['message'] != null) {
        errorMessage = body['message'];
      }

      // ✅ HANDLE VALIDATION ERRORS
      if (body['errors'] != null && body['errors'] is Map) {
        final errors = body['errors'] as Map<String, dynamic>;
        
        // Ambil semua error messages
        List<String> errorMessages = [];
        errors.forEach((field, messages) {
          if (messages is List && messages.isNotEmpty) {
            errorMessages.add(messages.first.toString());
          }
        });

        if (errorMessages.isNotEmpty) {
          errorMessage = errorMessages.join('\n');
        }
      }

      _showError(errorMessage);

    } catch (e) {
      if (!mounted) return;
      _showError('Terjadi kesalahan koneksi: ${e.toString()}');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.error_outline, color: Colors.red, size: 28),
            ),
            const SizedBox(width: 12),
            const Text(
              'Registrasi Gagal',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
        content: Text(
          msg,
          style: const TextStyle(fontSize: 15, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFF0066AE),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showVerificationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF0066AE).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.mark_email_read,
                color: Color(0xFF0066AE),
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Verifikasi Email', style: TextStyle(fontSize: 18)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Kami telah mengirim link verifikasi ke email Anda.',
              style: TextStyle(fontSize: 15),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0066AE).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.email, color: Color(0xFF0066AE), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _emailC.text,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0066AE),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Silakan cek inbox dan klik link verifikasi untuk melanjutkan.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
              );
            },
            child: const Text(
              'OK, Saya Mengerti',
              style: TextStyle(
                color: Color(0xFF0066AE),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // BCA BLUE COLOR SCHEME
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
                const SizedBox(height: 30),

                // LOGO
                Container(
                  padding: const EdgeInsets.all(20),
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
                    height: 80,
                    fit: BoxFit.contain,
                  ),
                ),

                const SizedBox(height: 25),

                // WELCOME TEXT
                const Text(
                  'Daftar Akun Baru',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bergabung dengan Prima Home Care',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                  ),
                ),

                const SizedBox(height: 30),

                // WHITE CARD FORM
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
                    padding: const EdgeInsets.all(24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // NAMA LENGKAP
                          _buildLabel('Nama Lengkap'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _namaC,
                            hint: 'Masukkan nama lengkap',
                            icon: Icons.person_outline,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Nama lengkap wajib diisi';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          // EMAIL
                          _buildLabel('Email'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _emailC,
                            hint: 'Masukkan email Anda',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email wajib diisi';
                              }
                              if (!v.contains('@') || !v.contains('.')) {
                                return 'Format email tidak valid';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          // NO HP
                          _buildLabel('No. HP / WhatsApp'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _noHpC,
                            hint: 'Masukkan nomor HP',
                            icon: Icons.phone_iphone,
                            keyboardType: TextInputType.phone,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Nomor HP wajib diisi';
                              }
                              if (v.trim().length < 8) {
                                return 'Nomor terlalu pendek';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          // PASSWORD
                          _buildLabel('Kata Sandi'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _passwordC,
                            hint: 'Minimal 6 karakter',
                            icon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey[600],
                                size: 22,
                              ),
                              onPressed: () =>
                                  setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Kata sandi wajib diisi';
                              }
                              if (v.length < 6) {
                                return 'Minimal 6 karakter';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 18),

                          // CONFIRM PASSWORD
                          _buildLabel('Ulangi Kata Sandi'),
                          const SizedBox(height: 8),
                          _buildTextField(
                            controller: _password2C,
                            hint: 'Ketik ulang kata sandi',
                            icon: Icons.lock_reset,
                            obscureText: _obscureConfirm,
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscureConfirm
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: Colors.grey[600],
                                size: 22,
                              ),
                              onPressed: () =>
                                  setState(() => _obscureConfirm = !_obscureConfirm),
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

                          const SizedBox(height: 28),

                          // REGISTER BUTTON
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
                              onPressed: _isLoading ? null : _doRegister,
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
                                        valueColor:
                                            AlwaysStoppedAnimation(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'DAFTAR',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // LOGIN LINK
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Sudah punya akun? ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const LoginPage(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Masuk',
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

                const SizedBox(height: 25),

                // FOOTER
                Text(
                  'Prima Home Care',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    TextInputType? keyboardType,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!, width: 1.5),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 15),
          prefixIcon: Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF0066AE).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0066AE), size: 20),
          ),
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:home_care/ITDev/dashboard_it_page.dart';
import 'package:home_care/admin/dashboard/admin_dashboard_page.dart';
import 'package:home_care/core/services/firebase_notification_service.dart';
import 'package:home_care/core/services/storage_service.dart';
import 'package:home_care/direktur/direktur_dashboard.dart';
import 'package:home_care/features/auth/data/auth_repository.dart';
import 'package:home_care/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:home_care/features/auth/presentation/screens/register.dart';
import 'package:home_care/features/auth/presentation/widgets/login_input_field.dart';
import 'package:home_care/features/auth/presentation/widgets/social_auth_button.dart';
import 'package:home_care/kordinator/dashboard.dart';
import 'package:home_care/manager/manager_dashboard.dart';
import 'package:home_care/perawat/dashboard.dart';
import 'package:home_care/users/home/home_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameC = TextEditingController();
  final _passwordC = TextEditingController();
  final _authRepo = const AuthRepository();

  bool _isLoading = false;
  bool _obscure = true;
  bool _rememberMe = false;

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
    final prefs = await StorageService.instance;
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
      final body = await _authRepo.login(
        username: _usernameC.text.trim(),
        password: _passwordC.text.trim(),
      );

      if (!mounted) return;

      final token = (body['token'] ?? body['access_token'])?.toString() ?? '';
      if (token.isEmpty) {
        _showError('Token tidak ditemukan');
        return;
      }

      final prefs = await StorageService.instance;
      final role = prefs.getString('role') ?? 'pasien';

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
        } catch (e) {
          debugPrint('Notification init after login error: $e');
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Login berhasil'),
          backgroundColor: Color(0xFF10B981),
        ),
      );

      final nextPage = _resolveDashboardPage(role);

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

  Widget _resolveDashboardPage(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const AdminDashboard();
      case 'koordinator':
        return const KoordinatorDashboard();
      case 'perawat':
        return const PerawatDashboard();
      case 'direktur':
        return const DirekturDashboard();
      case 'manager':
        return const ManagerDashboard();
      case 'it':
        return const ITDevDashboard();
      case 'pasien':
      default:
        return const HomePage();
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: const Color(0xFFEF4444)),
    );
  }

  void _onSocialLogin(String provider) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Login dengan $provider akan segera tersedia.'),
        backgroundColor: const Color(0xFF2563EB),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Stack(
        children: [
          // Soft ambient blue mist gradient at top
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 220,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFD6E4FB),
                    Color(0xFFE9F1FE),
                    Color(0x00F8FAFC),
                  ],
                  stops: [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;
                // Mode kompak otomatis jika tinggi layar terbatas (< 690px)
                final isCompact = availableHeight < 690;
                final logoHeight = isCompact ? 60.0 : 72.0;
                final gapBetween = isCompact ? 10.0 : 14.0;
                final headerFontSize = isCompact ? 26.0 : 29.0;
                final inputPadding = isCompact
                    ? const EdgeInsets.symmetric(horizontal: 16, vertical: 12)
                    : const EdgeInsets.symmetric(horizontal: 18, vertical: 14);

                return Center(
                  child: SingleChildScrollView(
                    // Kunci scroll saat keyboard tertutup agar pas 1 layar penuh
                    physics: isKeyboardOpen
                        ? const ClampingScrollPhysics()
                        : const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: isCompact ? 10 : 16,
                    ),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 420),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Centered App Logo Prima Home Care
                            Center(
                              child: Image.asset(
                                'assets/images/home_nobg.png',
                                height: logoHeight,
                                fit: BoxFit.contain,
                              ),
                            ),
                            SizedBox(height: isCompact ? 14 : 20),

                            // Title & Subtitle
                            Text(
                              'Sign in to your\nAccount',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: headerFontSize,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF0F172A),
                                height: 1.15,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Enter your email and password to log in',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: isCompact ? 13.0 : 14.0,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF64748B),
                                letterSpacing: -0.1,
                              ),
                            ),
                            SizedBox(height: isCompact ? 16 : 22),

                            // Email / Username input
                            LoginInputField(
                              controller: _usernameC,
                              hintText: 'Loisbecket@gmail.com',
                              keyboardType: TextInputType.emailAddress,
                              contentPadding: inputPadding,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Email atau username wajib diisi';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: gapBetween),

                            // Password input
                            LoginInputField(
                              controller: _passwordC,
                              hintText: '••••••••',
                              obscureText: _obscure,
                              contentPadding: inputPadding,
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: const Color(0xFF94A3B8),
                                  size: 20,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure = !_obscure),
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
                            SizedBox(height: gapBetween),

                            // Remember Me & Forgot Password Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                RememberMeCheckbox(
                                  isChecked: _rememberMe,
                                  onChanged: (val) =>
                                      setState(() => _rememberMe = val),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) =>
                                            const ForgotPasswordScreen(),
                                      ),
                                    );
                                  },
                                  child: const Text(
                                    'Forgot Password ?',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13.0,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF2563EB),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isCompact ? 16 : 20),

                            // Log In Button
                            SizedBox(
                              width: double.infinity,
                              height: isCompact ? 48 : 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _doLogin,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2563EB),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  shadowColor: const Color(0xFF2563EB)
                                      .withValues(alpha: 0.35),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        width: 22,
                                        height: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2.2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Log In',
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 15.5,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.2,
                                        ),
                                      ),
                              ),
                            ),
                            SizedBox(height: isCompact ? 14 : 18),

                            // Divider "─── Or ───"
                            const Row(
                              children: [
                                Expanded(
                                  child: Divider(
                                    color: Color(0xFFE2E8F0),
                                    thickness: 1,
                                  ),
                                ),
                                Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 14),
                                  child: Text(
                                    'Or',
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF94A3B8),
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Divider(
                                    color: Color(0xFFE2E8F0),
                                    thickness: 1,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isCompact ? 12 : 16),

                            // Social Buttons - 1 BARIS (Side-by-Side)
                            Row(
                              children: [
                                Expanded(
                                  child: SocialAuthButton(
                                    icon: const GoogleLogoIcon(size: 20),
                                    label: 'Google',
                                    height: isCompact ? 44 : 46,
                                    onPressed: () => _onSocialLogin('Google'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: SocialAuthButton(
                                    icon: const FacebookLogoIcon(size: 20),
                                    label: 'Facebook',
                                    height: isCompact ? 44 : 46,
                                    onPressed: () => _onSocialLogin('Facebook'),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: isCompact ? 16 : 22),

                            // Sign Up Footer
                            Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account? ",
                                    style: TextStyle(
                                      fontFamily: 'Plus Jakarta Sans',
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF64748B),
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
                                      'Sign Up',
                                      style: TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF2563EB),
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
              },
            ),
          ),
        ],
      ),
    );
  }
}

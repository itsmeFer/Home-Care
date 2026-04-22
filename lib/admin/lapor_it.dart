// admin/pages/lapor_it.dart
// ✅ Halaman Lapor IT untuk Admin
// ✅ Design system konsisten dengan AdminDashboard
// ✅ Responsive mobile, tablet, desktop
// ✅ Form validation lengkap
// ✅ Integrasi dengan halaman riwayat laporan

import 'dart:convert';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

class LaporITPageAdmin extends StatefulWidget {
  const LaporITPageAdmin({Key? key}) : super(key: key);

  @override
  State<LaporITPageAdmin> createState() => _LaporITPageAdminState();
}

class _LaporITPageAdminState extends State<LaporITPageAdmin> {
  // ====== DESIGN SYSTEM (SAMA DENGAN MANAGER DASHBOARD) ======
  static const Color kBg = Color(0xFFF8FAFC);
  static const Color kCard = Colors.white;
  static const Color kBorder = Color(0xFFE2E8F0);
  static const Color kText = Color(0xFF0F172A);
  static const Color kMuted = Color(0xFF64748B);
  static const Color kPrimary = Color(0xFF0EA5E9);
  static const Color kSuccess = Color(0xFF10B981);
  static const Color kWarning = Color(0xFFF59E0B);
  static const Color kDanger = Color(0xFFEF4444);

  // ====== API CONFIG ======
  static const String kBaseUrl = 'http://192.168.1.5:8000';
  String get kApiBase => '$kBaseUrl/api';

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedCategory = 'bug';
  String _selectedPriority = 'medium';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _categories = const [
    {
      'value': 'bug',
      'label': 'Bug/Error',
      'icon': Icons.bug_report_outlined,
      'desc': 'Kesalahan sistem'
    },
    {
      'value': 'error',
      'label': 'Error System',
      'icon': Icons.error_outline,
      'desc': 'Masalah teknis'
    },
    {
      'value': 'performance',
      'label': 'Performance',
      'icon': Icons.speed_outlined,
      'desc': 'Lambat/hang'
    },
    {
      'value': 'access',
      'label': 'Akses',
      'icon': Icons.lock_outline,
      'desc': 'Permission/login'
    },
    {
      'value': 'other',
      'label': 'Lainnya',
      'icon': Icons.help_outline,
      'desc': 'Masalah lain'
    },
  ];

  final List<Map<String, dynamic>> _priorities = const [
    {
      'value': 'low',
      'label': 'Rendah',
      'color': Color(0xFF10B981),
      'icon': Icons.arrow_downward_rounded,
      'desc': 'Tidak mendesak'
    },
    {
      'value': 'medium',
      'label': 'Sedang',
      'color': Color(0xFFF59E0B),
      'icon': Icons.remove_rounded,
      'desc': 'Cukup penting'
    },
    {
      'value': 'high',
      'label': 'Tinggi',
      'color': Color(0xFFEF4444),
      'icon': Icons.arrow_upward_rounded,
      'desc': 'Sangat mendesak'
    },
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ===============================
  // Helpers
  // ===============================
  String _platform() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'other';
    }
  }

  void _showToast(String msg, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                msg,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? kDanger : kSuccess,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ===============================
  // SUBMIT
  // ===============================
  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      final token = (prefs.getString('auth_token') ??
              prefs.getString('token') ??
              '')
          .trim();
      if (token.isEmpty) {
        throw Exception('Token kosong. Silakan login ulang.');
      }

      final subject = _subjectController.text.trim();
      final description = _descriptionController.text.trim();

      final payload = {
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'subject': subject,
        'description': description,
        'platform': _platform(),
        'app_version': null,
        'meta': {
          'source': 'admin.lapor_it',
          'is_web': kIsWeb,
        },
      };

      final uri = Uri.parse('$kApiBase/support-tickets');

      final response = await http.post(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(payload),
      );

      Map<String, dynamic> bodyMap = {};
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map) bodyMap = Map<String, dynamic>.from(decoded);
      } catch (_) {}

      final ok = response.statusCode >= 200 && response.statusCode < 300;

      if (ok) {
        final successFlag = bodyMap['success'];
        if (successFlag == false) {
          final msg =
              (bodyMap['message'] ?? 'Gagal mengirim laporan').toString();
          throw Exception(msg);
        }

        if (!mounted) return;

        _showToast('✅ Laporan berhasil dikirim ke tim IT');

        // Clear form
        _subjectController.clear();
        _descriptionController.clear();
        setState(() {
          _selectedCategory = 'bug';
          _selectedPriority = 'medium';
        });

        // Delay sedikit untuk user baca toast, lalu balik
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) Navigator.pop(context, true);
      } else {
        String msg = 'Gagal mengirim laporan (HTTP ${response.statusCode})';

        if (bodyMap['message'] != null) {
          msg = bodyMap['message'].toString();
        } else if (bodyMap['error'] != null) {
          msg = bodyMap['error'].toString();
        } else if (bodyMap['errors'] is Map) {
          final errors = Map<String, dynamic>.from(bodyMap['errors']);
          final firstKey = errors.keys.isNotEmpty ? errors.keys.first : null;
          if (firstKey != null) {
            final v = errors[firstKey];
            if (v is List && v.isNotEmpty) {
              msg = v.first.toString();
            } else {
              msg = v.toString();
            }
          }
        } else if (response.body.isNotEmpty) {
          msg = response.body;
        }

        throw Exception(msg);
      }
    } catch (e) {
      if (!mounted) return;
      _showToast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ===============================
  // NAVIGATE TO HISTORY
  // ===============================
  void _goToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const RiwayatLaporanITPageAdmin(),
      ),
    );
  }

  // ===============================
  // UI BUILD
  // ===============================
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 760;
    final isTablet = w >= 760 && w < 1100;
    final isDesktop = w >= 1100;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kCard,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: kText, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Lapor ke IT',
          style: TextStyle(
            color: kText,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: kBorder,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isDesktop ? 900 : double.infinity,
            ),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : (isTablet ? 24 : 32)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Card
                  _HeaderCard(),
                  const SizedBox(height: 24),

                  // Form Card
                  Container(
                    decoration: BoxDecoration(
                      color: kCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: kBorder),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x08000000),
                          blurRadius: 24,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(isMobile ? 20 : 28),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category Section
                                _buildSectionTitle(
                                  'Kategori Masalah',
                                  'Pilih jenis masalah yang dialami',
                                ),
                                const SizedBox(height: 16),
                                _buildCategorySelector(isMobile),

                                const SizedBox(height: 32),

                                // Priority Section
                                _buildSectionTitle(
                                  'Tingkat Prioritas',
                                  'Seberapa mendesak masalah ini',
                                ),
                                const SizedBox(height: 16),
                                _buildPrioritySelector(isMobile),

                                const SizedBox(height: 32),

                                // Subject Section
                                _buildSectionTitle(
                                  'Judul Masalah',
                                  'Ringkasan singkat dari masalah',
                                ),
                                const SizedBox(height: 16),
                                _buildSubjectField(),

                                const SizedBox(height: 32),

                                // Description Section
                                _buildSectionTitle(
                                  'Deskripsi Lengkap',
                                  'Jelaskan masalah secara detail',
                                ),
                                const SizedBox(height: 16),
                                _buildDescriptionField(),

                                const SizedBox(height: 28),

                                // Info Box
                                _buildInfoBox(),
                              ],
                            ),
                          ),

                          // Divider
                          Container(
                            height: 1,
                            color: kBorder,
                          ),

                          // Actions
                          Padding(
                            padding: EdgeInsets.all(isMobile ? 20 : 28),
                            child: Column(
                              children: [
                                _buildSubmitButton(isMobile),
                                const SizedBox(height: 12),
                                _buildHistoryButton(isMobile),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===============================
  // UI COMPONENTS
  // ===============================

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w900,
            color: kText,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildCategorySelector(bool isMobile) {
    if (isMobile) {
      // Mobile: Grid 2 kolom
      return GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 1.4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          return _buildCategoryCard(cat, true);
        },
      );
    } else {
      // Desktop/Tablet: Wrap horizontal
      return Wrap(
        spacing: 12,
        runSpacing: 12,
        children: _categories.map((cat) {
          return SizedBox(
            width: 180,
            child: _buildCategoryCard(cat, false),
          );
        }).toList(),
      );
    }
  }

  Widget _buildCategoryCard(Map<String, dynamic> cat, bool isMobile) {
    final isSelected = _selectedCategory == cat['value'];

    return InkWell(
      onTap: () => setState(() => _selectedCategory = cat['value'] as String),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE0F2FE) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFFBAE6FD) : kBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              cat['icon'] as IconData,
              size: isMobile ? 28 : 32,
              color: isSelected ? kPrimary : kMuted,
            ),
            SizedBox(height: isMobile ? 8 : 12),
            Text(
              cat['label'] as String,
              style: TextStyle(
                fontSize: isMobile ? 13 : 14,
                fontWeight: FontWeight.w900,
                color: isSelected ? kText : kMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              cat['desc'] as String,
              style: TextStyle(
                fontSize: isMobile ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: kMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySelector(bool isMobile) {
    return Row(
      children: _priorities.map((priority) {
        final isSelected = _selectedPriority == priority['value'];
        final color = priority['color'] as Color;
        final isLast = priority == _priorities.last;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 10),
            child: InkWell(
              onTap: () => setState(
                  () => _selectedPriority = priority['value'] as String),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: EdgeInsets.symmetric(
                  vertical: isMobile ? 14 : 18,
                  horizontal: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.08)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? color : kBorder,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      priority['icon'] as IconData,
                      size: isMobile ? 28 : 32,
                      color: isSelected ? color : kMuted,
                    ),
                    SizedBox(height: isMobile ? 8 : 10),
                    Text(
                      priority['label'] as String,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 14,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? color : kMuted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      priority['desc'] as String,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: kMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSubjectField() {
    return TextFormField(
      controller: _subjectController,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: kText,
      ),
      decoration: InputDecoration(
        hintText: 'Contoh: Dashboard admin tidak bisa dibuka',
        hintStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: kMuted.withOpacity(0.6),
        ),
        prefixIcon: const Icon(Icons.title_rounded, color: kMuted, size: 20),
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kDanger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kDanger, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Judul masalah harus diisi';
        }
        if (value.trim().length < 5) return 'Judul minimal 5 karakter';
        return null;
      },
      maxLength: 255,
    );
  }

  Widget _buildDescriptionField() {
    return TextFormField(
      controller: _descriptionController,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: kText,
        height: 1.5,
      ),
      decoration: InputDecoration(
        hintText:
            'Jelaskan masalah yang dialami secara detail:\n\n• Kapan masalah terjadi\n• Langkah-langkah yang dilakukan\n• Pesan error (jika ada)\n• Screenshot (jika perlu)',
        hintStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: kMuted.withOpacity(0.6),
          height: 1.5,
        ),
        alignLabelWithHint: true,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kPrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kDanger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: kDanger, width: 2),
        ),
        contentPadding: const EdgeInsets.all(16),
      ),
      maxLines: 10,
      minLines: 8,
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return 'Deskripsi masalah harus diisi';
        }
        if (value.trim().length < 20) return 'Deskripsi minimal 20 karakter';
        return null;
      },
    );
  }

  Widget _buildInfoBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF3C7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE047)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: Color(0xFFA16207),
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Perhatian',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF78350F),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Tim IT akan merespon laporan Anda secepatnya sesuai dengan prioritas yang dipilih. Pastikan informasi yang diberikan lengkap dan jelas.',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF78350F),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isMobile) {
    return SizedBox(
      width: double.infinity,
      height: isMobile ? 52 : 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: kMuted.withOpacity(0.3),
          elevation: 0,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.send_rounded, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Kirim Laporan',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHistoryButton(bool isMobile) {
    return SizedBox(
      width: double.infinity,
      height: isMobile ? 52 : 56,
      child: OutlinedButton(
        onPressed: _goToHistory,
        style: OutlinedButton.styleFrom(
          foregroundColor: kPrimary,
          side: const BorderSide(color: kBorder, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.history_rounded, size: 20),
            SizedBox(width: 10),
            Text(
              'Lihat Riwayat Laporan',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===============================
// HEADER CARD
// ===============================
class _HeaderCard extends StatelessWidget {
  static const Color kCard = Colors.white;
  static const Color kBorder = Color(0xFFE2E8F0);
  static const Color kText = Color(0xFF0F172A);
  static const Color kMuted = Color(0xFF64748B);
  static const Color kPrimary = Color(0xFF0EA5E9);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x200EA5E9),
            blurRadius: 24,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Support Ticket Admin',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Laporkan masalah atau bug yang Anda temukan agar tim IT dapat segera menanganinya.',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white.withOpacity(0.95),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ===============================
// RIWAYAT LAPORAN IT PAGE MANAGER
// ===============================
class RiwayatLaporanITPageAdmin extends StatefulWidget {
  const RiwayatLaporanITPageAdmin({Key? key}) : super(key: key);

  @override
  State<RiwayatLaporanITPageAdmin> createState() =>
      _RiwayatLaporanITPageAdminState();
}

class _RiwayatLaporanITPageAdminState
    extends State<RiwayatLaporanITPageAdmin> {
  // ====== DESIGN SYSTEM ======
  static const Color kBg = Color(0xFFF8FAFC);
  static const Color kCard = Colors.white;
  static const Color kBorder = Color(0xFFE2E8F0);
  static const Color kText = Color(0xFF0F172A);
  static const Color kMuted = Color(0xFF64748B);
  static const Color kPrimary = Color(0xFF0EA5E9);
  static const Color kSuccess = Color(0xFF10B981);
  static const Color kWarning = Color(0xFFF59E0B);
  static const Color kDanger = Color(0xFFEF4444);

  // ====== API CONFIG ======
  static const String kBaseUrl = 'http://192.168.1.5:8000';
  String get kApiBase => '$kBaseUrl/api';

  bool _isLoading = true;
  List<Map<String, dynamic>> _tickets = [];
  String? _errorMessage;

  // Filter
  String? _filterStatus;
  String? _filterPriority;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  // ===============================
  // LOAD TICKETS
  // ===============================
  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = (prefs.getString('auth_token') ??
              prefs.getString('token') ??
              '')
          .trim();

      if (token.isEmpty) {
        throw Exception('Token kosong. Silakan login ulang.');
      }

      // Build query params
      final queryParams = <String, String>{};
      if (_filterStatus != null) queryParams['status'] = _filterStatus!;
      if (_filterPriority != null) queryParams['priority'] = _filterPriority!;

      final uri = Uri.parse('$kApiBase/support-tickets')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final decoded = jsonDecode(response.body);

        if (decoded is Map && decoded['success'] == true) {
          final data = decoded['data'];

          if (data is List) {
            setState(() {
              _tickets = data.map((e) => Map<String, dynamic>.from(e)).toList();
              _isLoading = false;
            });
          } else {
            throw Exception('Format data tidak valid');
          }
        } else {
          throw Exception(decoded['message'] ?? 'Gagal memuat data');
        }
      } else {
        throw Exception('HTTP ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  // ===============================
  // HELPERS
  // ===============================
  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dt = DateTime.parse(dateStr);
      return DateFormat('dd MMM yyyy, HH:mm').format(dt);
    } catch (_) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return kWarning;
      case 'in_progress':
        return kPrimary;
      case 'solved':
        return kSuccess;
      case 'closed':
        return kMuted;
      default:
        return kMuted;
    }
  }

  String _getStatusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return 'Terbuka';
      case 'in_progress':
        return 'Diproses';
      case 'solved':
        return 'Selesai';
      case 'closed':
        return 'Ditutup';
      default:
        return status;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return kSuccess;
      case 'medium':
        return kWarning;
      case 'high':
        return kDanger;
      default:
        return kMuted;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return 'Rendah';
      case 'medium':
        return 'Sedang';
      case 'high':
        return 'Tinggi';
      default:
        return priority;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'bug':
        return Icons.bug_report_outlined;
      case 'error':
        return Icons.error_outline;
      case 'performance':
        return Icons.speed_outlined;
      case 'access':
        return Icons.lock_outline;
      default:
        return Icons.help_outline;
    }
  }

  // ===============================
  // UI BUILD
  // ===============================
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 760;

    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: kCard,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: kBorder),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: kText, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Riwayat Laporan IT',
          style: TextStyle(
            color: kText,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list_rounded, color: kText),
            onPressed: _showFilterDialog,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kBorder),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadTickets,
        child: _buildBody(isMobile),
      ),
    );
  }

  Widget _buildBody(bool isMobile) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2.5),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline,
                  size: 64, color: kDanger.withOpacity(0.5)),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kMuted,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadTickets,
                icon: const Icon(Icons.refresh_rounded, size: 20),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPrimary,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_tickets.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 80,
                color: kMuted.withOpacity(0.3),
              ),
              const SizedBox(height: 16),
              const Text(
                'Belum ada laporan',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: kText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Laporan IT Anda akan muncul di sini',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: kMuted.withOpacity(0.8),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      itemCount: _tickets.length,
      itemBuilder: (context, index) {
        final ticket = _tickets[index];
        return _buildTicketCard(ticket, isMobile);
      },
    );
  }

  Widget _buildTicketCard(Map<String, dynamic> ticket, bool isMobile) {
    final status = ticket['status']?.toString() ?? 'open';
    final priority = ticket['priority']?.toString() ?? 'medium';
    final category = ticket['category']?.toString() ?? 'bug';
    final subject = ticket['subject']?.toString() ?? 'Tanpa Judul';
    final createdAt = ticket['created_at']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 12,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showTicketDetail(ticket),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 14 : 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Category Icon + Status Badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: kPrimary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        _getCategoryIcon(category),
                        size: 20,
                        color: kPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subject,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              color: kText,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatDate(createdAt),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: kMuted.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(status),
                  ],
                ),

                const SizedBox(height: 12),

                // Priority Badge
                Row(
                  children: [
                    _buildPriorityBadge(priority),
                    const Spacer(),
                    Text(
                      'ID: #${ticket['id']}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: kMuted.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final color = _getStatusColor(status);
    final label = _getStatusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPriorityBadge(String priority) {
    final color = _getPriorityColor(priority);
    final label = _getPriorityLabel(priority);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ===============================
  // FILTER DIALOG
  // ===============================
  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'Filter Laporan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Status',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip('Semua', null, _filterStatus, (val) {
                  setState(() => _filterStatus = val);
                }),
                _buildFilterChip('Terbuka', 'open', _filterStatus, (val) {
                  setState(() => _filterStatus = val);
                }),
                _buildFilterChip('Diproses', 'in_progress', _filterStatus,
                    (val) {
                  setState(() => _filterStatus = val);
                }),
                _buildFilterChip('Selesai', 'solved', _filterStatus, (val) {
                  setState(() => _filterStatus = val);
                }),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Prioritas',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildFilterChip('Semua', null, _filterPriority, (val) {
                  setState(() => _filterPriority = val);
                }),
                _buildFilterChip('Rendah', 'low', _filterPriority, (val) {
                  setState(() => _filterPriority = val);
                }),
                _buildFilterChip('Sedang', 'medium', _filterPriority, (val) {
                  setState(() => _filterPriority = val);
                }),
                _buildFilterChip('Tinggi', 'high', _filterPriority, (val) {
                  setState(() => _filterPriority = val);
                }),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _filterStatus = null;
                _filterPriority = null;
              });
              Navigator.pop(context);
              _loadTickets();
            },
            child: const Text('Reset'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _loadTickets();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPrimary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Terapkan'),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(
    String label,
    String? value,
    String? currentValue,
    Function(String?) onTap,
  ) {
    final isSelected = currentValue == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        onTap(value);
      },
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: isSelected ? kPrimary : kMuted,
      ),
      backgroundColor: Colors.transparent,
      selectedColor: kPrimary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? kPrimary : kBorder,
        ),
      ),
    );
  }

  // ===============================
  // DETAIL DIALOG
  // ===============================
  void _showTicketDetail(Map<String, dynamic> ticket) {
    final status = ticket['status']?.toString() ?? 'open';
    final priority = ticket['priority']?.toString() ?? 'medium';
    final category = ticket['category']?.toString() ?? 'bug';
    final subject = ticket['subject']?.toString() ?? 'Tanpa Judul';
    final description = ticket['description']?.toString() ?? '-';
    final createdAt = ticket['created_at']?.toString();
    final solvedAt = ticket['solved_at']?.toString();
    final itNotes = ticket['it_notes']?.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: const BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: kBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Detail Laporan #${ticket['id']}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: kText,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: kMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status & Priority
                    Row(
                      children: [
                        _buildStatusBadge(status),
                        const SizedBox(width: 8),
                        _buildPriorityBadge(priority),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Subject
                    const Text(
                      'Judul',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: kMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subject,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: kText,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Description
                    const Text(
                      'Deskripsi',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: kMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kText,
                        height: 1.5,
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Created At
                    _buildInfoRow('Dibuat', _formatDate(createdAt)),

                    if (solvedAt != null && solvedAt.isNotEmpty)
                      _buildInfoRow('Diselesaikan', _formatDate(solvedAt)),

                    if (itNotes != null && itNotes.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Catatan IT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          color: kMuted,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: kPrimary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: kPrimary.withOpacity(0.1)),
                        ),
                        child: Text(
                          itNotes,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: kText,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: kMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kText,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
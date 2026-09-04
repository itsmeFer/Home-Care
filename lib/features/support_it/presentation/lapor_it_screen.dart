import 'dart:convert';

import 'package:flutter/foundation.dart'
    show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LaporITScreen extends StatefulWidget {
  final String source;
  final String title;

  const LaporITScreen({
    super.key,
    this.source = 'user.lapor_it',
    this.title = 'Lapor IT Support',
  });

  @override
  State<LaporITScreen> createState() => _LaporITScreenState();
}

class _LaporITScreenState extends State<LaporITScreen> {
  static const Color kBg = AppColors.background;
  static const Color kCard = AppColors.card;
  static const Color kBorder = AppColors.border;
  static const Color kText = AppColors.textPrimary;
  static const Color kMuted = AppColors.textSecondary;
  static const Color kPrimary = Color(0xFF0EA5E9);
  static const Color kSuccess = AppColors.success;
  static const Color kDanger = AppColors.danger;

  String get kApiBase => ApiConstants.apiBase;

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
      'desc': 'Kesalahan sistem',
    },
    {
      'value': 'error',
      'label': 'Error System',
      'icon': Icons.error_outline,
      'desc': 'Masalah teknis',
    },
    {
      'value': 'performance',
      'label': 'Performance',
      'icon': Icons.speed_outlined,
      'desc': 'Lambat/hang',
    },
    {
      'value': 'access',
      'label': 'Akses',
      'icon': Icons.lock_outline,
      'desc': 'Permission/login',
    },
    {
      'value': 'other',
      'label': 'Lainnya',
      'icon': Icons.help_outline,
      'desc': 'Masalah lain',
    },
  ];

  final List<Map<String, dynamic>> _priorities = const [
    {
      'value': 'low',
      'label': 'Rendah',
      'color': Color(0xFF10B981),
      'icon': Icons.arrow_downward_rounded,
      'desc': 'Tidak mendesak',
    },
    {
      'value': 'medium',
      'label': 'Sedang',
      'color': Color(0xFFF59E0B),
      'icon': Icons.remove_rounded,
      'desc': 'Cukup penting',
    },
    {
      'value': 'high',
      'label': 'Tinggi',
      'color': Color(0xFFEF4444),
      'icon': Icons.arrow_upward_rounded,
      'desc': 'Sangat mendesak',
    },
  ];

  @override
  void dispose() {
    _subjectController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

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
        return 'unknown';
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

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();

      final token =
          (prefs.getString('auth_token') ?? prefs.getString('token') ?? '')
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
        'meta': {'source': widget.source, 'is_web': kIsWeb},
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

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (bodyMap['success'] == true ||
            (response.statusCode == 201 || response.statusCode == 200)) {
          if (!mounted) return;

          _subjectController.clear();
          _descriptionController.clear();
          setState(() {
            _selectedCategory = 'bug';
            _selectedPriority = 'medium';
          });

          _showToast('Laporan Anda berhasil dikirim ke tim IT.');

          Future.delayed(const Duration(milliseconds: 600), () {
            if (!mounted) return;
            _goToHistory();
          });
          return;
        }
      }

      String msg = 'Gagal mengirim laporan';
      if (bodyMap.containsKey('message') &&
          bodyMap['message'] != null &&
          bodyMap['message'].toString().trim().isNotEmpty) {
        msg = bodyMap['message'].toString();
      } else if (bodyMap.containsKey('errors') && bodyMap['errors'] is Map) {
        final errs = bodyMap['errors'] as Map;
        if (errs.isNotEmpty) {
          final firstKey = errs.keys.first;
          final v = errs[firstKey];
          if (v is List && v.isNotEmpty) {
            msg = v.first.toString();
          } else if (v != null) {
            msg = v.toString();
          }
        }
      } else if (response.body.isNotEmpty) {
        msg = response.body;
      }

      throw Exception(msg);
    } catch (e) {
      if (!mounted) return;
      _showToast(e.toString().replaceFirst('Exception: ', ''), isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goToHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RiwayatLaporanITScreen(source: widget.source),
      ),
    );
  }

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
        title: Text(
          widget.title,
          style: const TextStyle(
            color: kText,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: kText),
            tooltip: 'Riwayat Laporan',
            onPressed: _goToHistory,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: kBorder),
        ),
      ),
      body: SingleChildScrollView(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 16 : 24),
              child: isDesktop
                  ? _buildDesktopLayout()
                  : _buildMobileTabletLayout(isMobile, isTablet),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: Container(
            decoration: BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: kBorder),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(32),
            child: _buildForm(isMobile: false),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          flex: 5,
          child: Column(
            children: [
              const _HeaderCard(),
              const SizedBox(height: 16),
              _buildInfoPanel(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTabletLayout(bool isMobile, bool isTablet) {
    return Column(
      children: [
        const _HeaderCard(),
        SizedBox(height: isMobile ? 16 : 20),
        Container(
          decoration: BoxDecoration(
            color: kCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: kBorder),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(isMobile ? 18 : 24),
          child: _buildForm(isMobile: isMobile),
        ),
        SizedBox(height: isMobile ? 16 : 20),
        _buildInfoPanel(),
      ],
    );
  }

  Widget _buildForm({required bool isMobile}) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Formulir Laporan',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: kText,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Isi data di bawah dengan jelas agar masalah mudah dianalisis.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: kMuted,
            ),
          ),
          const SizedBox(height: 24),
          _buildCategorySelector(isMobile),
          const SizedBox(height: 20),
          _buildPrioritySelector(isMobile),
          const SizedBox(height: 20),
          _buildSubjectField(),
          const SizedBox(height: 20),
          _buildDescriptionField(),
          const SizedBox(height: 28),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildCategorySelector(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori Masalah *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: kText,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _categories.map((cat) {
            final isSelected = _selectedCategory == cat['value'];
            return InkWell(
              onTap: () {
                setState(() => _selectedCategory = cat['value']);
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isSelected ? kPrimary.withOpacity(0.1) : kCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? kPrimary : kBorder,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat['icon'] as IconData,
                      size: 18,
                      color: isSelected ? kPrimary : kMuted,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cat['label'] as String,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: isSelected ? kPrimary : kText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector(bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Prioritas *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: kText,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: _priorities.map((p) {
            final isSelected = _selectedPriority == p['value'];
            final color = p['color'] as Color;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: InkWell(
                  onTap: () {
                    setState(() => _selectedPriority = p['value']);
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? color.withOpacity(0.1) : kCard,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? color : kBorder,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          p['icon'] as IconData,
                          size: 18,
                          color: isSelected ? color : kMuted,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          p['label'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: isSelected ? color : kText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubjectField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Judul Masalah *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: kText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _subjectController,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Judul masalah wajib diisi';
            }
            if (v.trim().length < 5) {
              return 'Judul minimal 5 karakter';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: 'Contoh: Menu pasien gagal memuat data',
            hintStyle: const TextStyle(fontSize: 13, color: kMuted),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
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
              borderSide: const BorderSide(color: kPrimary, width: 1.5),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Deskripsi Lengkap *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: kText,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _descriptionController,
          maxLines: 5,
          validator: (v) {
            if (v == null || v.trim().isEmpty) {
              return 'Deskripsi masalah wajib diisi';
            }
            if (v.trim().length < 10) {
              return 'Deskripsi minimal 10 karakter';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText:
                'Jelaskan kronologi kendala, tombol yang ditekan, atau pesan error yang muncul...',
            hintStyle: const TextStyle(fontSize: 13, color: kMuted),
            contentPadding: const EdgeInsets.all(16),
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
              borderSide: const BorderSide(color: kPrimary, width: 1.5),
            ),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: kPrimary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: kPrimary.withOpacity(0.5),
        ),
        child: _isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.send_rounded, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Kirim Laporan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildInfoPanel() {
    return Container(
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: kPrimary, size: 20),
              SizedBox(width: 8),
              Text(
                'Alur Penanganan Tiket',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: kText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStep(
            '1',
            'Tiket Terkirim',
            'Laporan masuk ke antrian dashboard IT Developer.',
          ),
          const SizedBox(height: 8),
          _buildStep(
            '2',
            'Investigasi',
            'Tim IT memeriksa log sistem dan mereproduksi kendala.',
          ),
          const SizedBox(height: 8),
          _buildStep(
            '3',
            'Penyelesaian',
            'Solusi diaplikasikan dan status tiket diubah menjadi Selesai.',
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String num, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: kPrimary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            num,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: kPrimary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: kText,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 11,
                  color: kMuted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x200EA5E9),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pusat Bantuan & Tiket IT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Laporkan kendala teknis atau bug sistem',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class RiwayatLaporanITScreen extends StatefulWidget {
  final String source;

  const RiwayatLaporanITScreen({super.key, this.source = 'user.lapor_it'});

  @override
  State<RiwayatLaporanITScreen> createState() => _RiwayatLaporanITScreenState();
}

class _RiwayatLaporanITScreenState extends State<RiwayatLaporanITScreen> {
  static const Color kBg = AppColors.background;
  static const Color kCard = AppColors.card;
  static const Color kBorder = AppColors.border;
  static const Color kText = AppColors.textPrimary;
  static const Color kMuted = AppColors.textSecondary;
  static const Color kPrimary = Color(0xFF0EA5E9);
  static const Color kSuccess = AppColors.success;
  static const Color kWarning = AppColors.warning;
  static const Color kDanger = AppColors.danger;

  String get kApiBase => ApiConstants.apiBase;

  bool _isLoading = true;
  List<Map<String, dynamic>> _tickets = [];
  String? _errorMessage;

  String? _filterStatus;
  String? _filterPriority;

  @override
  void initState() {
    super.initState();
    _loadTickets();
  }

  Future<void> _loadTickets() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token =
          (prefs.getString('auth_token') ?? prefs.getString('token') ?? '')
              .trim();

      if (token.isEmpty) {
        throw Exception('Token kosong. Silakan login ulang.');
      }

      final queryParams = <String, String>{};
      if (_filterStatus != null) queryParams['status'] = _filterStatus!;
      if (_filterPriority != null) queryParams['priority'] = _filterPriority!;

      final uri = Uri.parse(
        '$kApiBase/support-tickets',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

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

  String _formatDate(String? dateStr) {
    return AppFormatters.formatDate(dateStr, pattern: 'dd MMM yyyy, HH:mm');
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'open':
        return kWarning;
      case 'in_progress':
        return kPrimary;
      case 'solved':
      case 'resolved':
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
      case 'resolved':
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
      return const Center(child: CircularProgressIndicator(strokeWidth: 2.5));
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: kDanger.withOpacity(0.5),
              ),
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
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

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
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
                    _buildFilterChip('Diproses', 'in_progress', _filterStatus, (
                      val,
                    ) {
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
                    _buildFilterChip('Sedang', 'medium', _filterPriority, (
                      val,
                    ) {
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
      onSelected: (_) => onTap(value),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: isSelected ? kPrimary : kMuted,
      ),
      backgroundColor: Colors.transparent,
      selectedColor: kPrimary.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? kPrimary : kBorder),
      ),
    );
  }

  void _showTicketDetail(Map<String, dynamic> ticket) {
    final status = ticket['status']?.toString() ?? 'open';
    final priority = ticket['priority']?.toString() ?? 'medium';
    final subject = ticket['subject']?.toString() ?? 'Tanpa Judul';
    final description = ticket['description']?.toString() ?? '-';
    final createdAt = ticket['created_at']?.toString();
    final solvedAt = ticket['solved_at']?.toString();
    final itNotes = ticket['it_notes']?.toString();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.8,
            decoration: const BoxDecoration(
              color: kCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: kBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
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
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _buildStatusBadge(status),
                            const SizedBox(width: 8),
                            _buildPriorityBadge(priority),
                          ],
                        ),
                        const SizedBox(height: 20),
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
                              border: Border.all(
                                color: kPrimary.withOpacity(0.1),
                              ),
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

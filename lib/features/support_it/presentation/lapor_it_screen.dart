import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/support_it/data/support_it_service.dart';
import 'package:home_care/features/support_it/presentation/riwayat_laporan_it_screen.dart';
import 'package:home_care/features/support_it/presentation/widgets/support_it_info_card.dart';
import 'package:home_care/features/support_it/presentation/widgets/support_it_selectors.dart';

export 'package:home_care/features/support_it/domain/support_it_models.dart';
export 'package:home_care/features/support_it/presentation/riwayat_laporan_it_screen.dart';

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
  static const Color _bg = AppColors.background;
  static const Color _card = AppColors.card;
  static const Color _border = AppColors.border;
  static const Color _text = AppColors.textPrimary;
  static const Color _muted = AppColors.textSecondary;
  static const Color _primary = Color(0xFF0EA5E9);
  static const Color _success = AppColors.success;
  static const Color _danger = AppColors.danger;

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String _selectedCategory = 'bug';
  String _selectedPriority = 'medium';
  bool _isLoading = false;

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
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        backgroundColor: isError ? _danger : _success,
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
      final payload = {
        'category': _selectedCategory,
        'priority': _selectedPriority,
        'subject': _subjectController.text.trim(),
        'description': _descriptionController.text.trim(),
        'platform': _platform(),
        'app_version': null,
        'meta': {'source': widget.source, 'is_web': kIsWeb},
      };

      await SupportItService.submitReport(payload);

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
    final w = MediaQuery.sizeOf(context).width;
    final isMobile = w < 760;
    final isTablet = w >= 760 && w < 1100;
    final isDesktop = w >= 1100;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _card,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _border),
            ),
            child: const Icon(Icons.arrow_back_rounded, color: _text, size: 18),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: _text,
            fontSize: 17,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, color: _text),
            tooltip: 'Riwayat Laporan',
            onPressed: _goToHistory,
          ),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: _border),
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
              color: _card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _border),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            padding: const EdgeInsets.all(32),
            child: _buildForm(),
          ),
        ),
        const SizedBox(width: 24),
        const Expanded(
          flex: 5,
          child: Column(
            children: [
              SupportItHeaderCard(),
              SizedBox(height: 16),
              SupportItWorkflowCard(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileTabletLayout(bool isMobile, bool isTablet) {
    return Column(
      children: [
        const SupportItHeaderCard(),
        SizedBox(height: isMobile ? 16 : 20),
        Container(
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _border),
            boxShadow: const [
              BoxShadow(
                color: Color(0x08000000),
                blurRadius: 16,
                offset: Offset(0, 4),
              ),
            ],
          ),
          padding: EdgeInsets.all(isMobile ? 18 : 24),
          child: _buildForm(),
        ),
        SizedBox(height: isMobile ? 16 : 20),
        const SupportItWorkflowCard(),
      ],
    );
  }

  Widget _buildForm() {
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
              color: _text,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Isi data di bawah dengan jelas agar masalah mudah dianalisis.',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _muted,
            ),
          ),
          const SizedBox(height: 24),
          SupportItCategorySelector(
            selectedCategory: _selectedCategory,
            onSelected: (cat) => setState(() => _selectedCategory = cat),
          ),
          const SizedBox(height: 20),
          SupportItPrioritySelector(
            selectedPriority: _selectedPriority,
            onSelected: (p) => setState(() => _selectedPriority = p),
          ),
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

  Widget _buildSubjectField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Judul Masalah *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: _text,
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
            hintStyle: const TextStyle(fontSize: 13, color: _muted),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 1.5),
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
            color: _text,
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
            hintStyle: const TextStyle(fontSize: 13, color: _muted),
            contentPadding: const EdgeInsets.all(16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _primary, width: 1.5),
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
          backgroundColor: _primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          disabledBackgroundColor: _primary.withValues(alpha: 0.5),
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
      ),
    );
  }
}

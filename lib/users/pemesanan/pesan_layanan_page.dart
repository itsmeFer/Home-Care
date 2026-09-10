import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';
import 'package:home_care/core/widgets/app_cached_image.dart';
import 'package:home_care/features/orders/domain/order_pricing_calculator.dart';
import 'package:home_care/features/orders/presentation/widgets/booking/booking_addons_step.dart';
import 'package:home_care/features/orders/presentation/widgets/booking/booking_bottom_bar.dart';
import 'package:home_care/features/orders/presentation/widgets/booking/booking_details_step.dart';
import 'package:home_care/features/orders/presentation/widgets/booking/booking_location_step.dart';
import 'package:home_care/features/orders/presentation/widgets/booking/booking_schedule_step.dart';
import 'package:home_care/features/orders/presentation/widgets/booking/booking_step_indicator.dart';
import 'package:home_care/features/orders/presentation/widgets/booking/booking_summary_step.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';
import 'package:home_care/users/pemesanan/payment_method_page.dart';
import 'package:home_care/users/pemesanan/services/booking_service.dart';
import 'package:home_care/users/pemesanan/widgets/booking_metrics_grid.dart';
import 'package:home_care/users/pemesanan/widgets/booking_related_services.dart';
import 'package:home_care/users/pemesanan/widgets/booking_sop_section.dart';
import 'package:home_care/users/pemesanan/widgets/booking_supervisor_card.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

export 'package:home_care/features/orders/domain/addon_model.dart';

class PesanLayananPage extends StatefulWidget {
  final Layanan layanan;

  const PesanLayananPage({super.key, required this.layanan});

  @override
  State<PesanLayananPage> createState() => _PesanLayananPageState();
}

class _PesanLayananPageState extends State<PesanLayananPage> {
  final _bookingService = const BookingService();
  final _formKey = GlobalKey<FormState>();

  final _tanggalController = TextEditingController();
  final _jamController = TextEditingController();
  final _alamatController = TextEditingController();
  final _kecamatanController = TextEditingController();
  final _kotaController = TextEditingController();
  final _catatanController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  XFile? _kondisiPasienImage;
  Uint8List? _kondisiPasienBytes;
  int _qty = 1;

  bool _isLoadingAddons = false;
  List<Addon> _availableAddons = [];
  final List<Addon> _selectedAddons = [];

  bool _isSubmitting = false;
  int _currentStep = 0;

  bool _isLoadingProfile = false;
  Map<String, dynamic>? _profileData;

  bool _isFavorite = false;
  bool _isDescriptionExpanded = false;
  int _selectedSegmentTab = 0; // 0: Form Pemesanan, 1: Tata Cara & SOP
  List<Layanan> _relatedLayanan = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    _fetchAddons();
    _fetchRelatedServices();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _tanggalController.dispose();
    _jamController.dispose();
    _alamatController.dispose();
    _kecamatanController.dispose();
    _kotaController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  Future<void> _fetchProfileData() async {
    setState(() => _isLoadingProfile = true);
    try {
      final pasien = await _bookingService.fetchUserProfile();
      if (!mounted) return;
      if (pasien != null) {
        setState(() {
          _profileData = pasien;
          _alamatController.text = pasien['alamat']?.toString() ?? '';
          _kecamatanController.text = pasien['kecamatan']?.toString() ?? '';
          _kotaController.text = pasien['kota']?.toString() ?? '';
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingProfile = false);
    }
  }

  Future<void> _fetchAddons() async {
    setState(() => _isLoadingAddons = true);
    try {
      final addons = await _bookingService.fetchAddons(widget.layanan.id);
      if (!mounted) return;
      setState(() => _availableAddons = addons);
    } finally {
      if (mounted) setState(() => _isLoadingAddons = false);
    }
  }

  Future<void> _fetchRelatedServices() async {
    try {
      final allServices = await _bookingService.fetchRelatedServices();
      if (!mounted) return;
      setState(() {
        _relatedLayanan = allServices
            .where((item) => item.id != widget.layanan.id)
            .take(6)
            .toList();
      });
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Foto kondisi pasien hanya bisa diambil dari kamera di aplikasi Android/iPhone.',
          ),
        ),
      );
      return;
    }

    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        setState(() {
          _kondisiPasienImage = pickedFile;
          _kondisiPasienBytes = bytes;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal membuka kamera: $e')));
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: HCColor.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _tanggalController.text = DateFormat(
          'dd MMM yyyy',
          'id_ID',
        ).format(picked);
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: HCColor.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _jamController.text = picked.format(context);
      });
    }
  }

  double _calculateTotal() {
    return OrderPricingCalculator.calculateTotal(
      basePrice: widget.layanan.hargaFix,
      quantity: _qty,
      selectedAddons: _selectedAddons,
    );
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon lengkapi semua field yang wajib')),
      );
      return;
    }

    if (_kondisiPasienImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon upload foto kondisi pasien'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon pilih tanggal kunjungan')),
      );
      return;
    }

    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mohon pilih jam kunjungan')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final fields = <String, String>{
        'layanan_id': widget.layanan.id.toString(),
        'tanggal_mulai': DateFormat('yyyy-MM-dd').format(_selectedDate!),
        'jam_mulai':
            '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}',
        'alamat_lengkap': _alamatController.text.trim(),
        'kecamatan': _kecamatanController.text.trim(),
        'kota': _kotaController.text.trim(),
        'qty': _qty.toString(),
      };

      if (_catatanController.text.trim().isNotEmpty) {
        fields['catatan_pasien'] = _catatanController.text.trim();
      }

      if (_selectedAddons.isNotEmpty) {
        final addonsData = _selectedAddons
            .map((addon) => {'addon_id': addon.id, 'qty': addon.qty})
            .toList();
        fields['addons'] = json.encode(addonsData);
      }

      final data = await _bookingService.submitDraft(
        fields: fields,
        kondisiBytes: _kondisiPasienBytes,
        kondisiFileName: _kondisiPasienImage?.name,
      );

      if (!mounted) return;

      final draft = data['draft'];
      final draftId = draft['id'];
      final totalBayar = draft['total_bayar'];

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Draft pesanan berhasil dibuat!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentMethodPage(
            draftId: draftId,
            totalBayar: (totalBayar is int)
                ? totalBayar
                : (totalBayar is double)
                    ? totalBayar.toInt()
                    : int.tryParse(totalBayar.toString()) ?? 0,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  InputDecoration _inputDecoration({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    bool alignLabelWithHint = false,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      alignLabelWithHint: alignLabelWithHint,
      prefixIcon: prefixIcon,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: HCColor.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final bool isTablet = screenWidth >= 600;
    final double expandedHeroHeight = isTablet ? 360.0 : 310.0;

    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          SliverAppBar(
            expandedHeight: expandedHeroHeight,
            pinned: true,
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            leadingWidth: 76,
            toolbarHeight: 64,
            leading: Padding(
              padding: const EdgeInsets.only(left: 18, top: 10, bottom: 10),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(15),
                    onTap: () => Navigator.pop(context),
                    child: const Center(
                      child: Icon(
                        Icons.close_rounded,
                        color: Color(0xFF0F172A),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 18, top: 10, bottom: 10),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        setState(() => _isFavorite = !_isFavorite);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              _isFavorite
                                  ? 'Disimpan ke layanan favorit'
                                  : 'Dihapus dari favorit',
                            ),
                            duration: const Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Center(
                        child: Icon(
                          _isFavorite ? IconlyBold.heart : IconlyLight.heart,
                          color: _isFavorite
                              ? const Color(0xFFEF4444)
                              : const Color(0xFF0F172A),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
            title: AnimatedBuilder(
              animation: _scrollController,
              builder: (context, _) {
                double offset = 0;
                if (_scrollController.hasClients) {
                  offset = _scrollController.offset;
                }
                final double opacity = ((offset - 130) / 80).clamp(0.0, 1.0);

                return Opacity(
                  opacity: opacity,
                  child: Text(
                    widget.layanan.namaLayanan,
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                );
              },
            ),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: const Color(0xFFF8FAFC)),
                  if (widget.layanan.gambarUrl != null)
                    AppCachedImage(
                      imageUrl: widget.layanan.gambarUrl,
                      fit: BoxFit.cover,
                    )
                  else
                    Container(
                      color: const Color(0xFFE6F5F5),
                      child: const Center(
                        child: Icon(
                          IconlyLight.activity,
                          size: 80,
                          color: HCColor.primary,
                        ),
                      ),
                    ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: -1,
                    height: 38,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(38),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          margin: const EdgeInsets.only(top: 8, bottom: 20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE2E8F0),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                widget.layanan.namaLayanan,
                                style: TextStyle(
                                  fontSize: screenWidth < 360 ? 20 : 23,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF0F172A),
                                  height: 1.2,
                                  letterSpacing: -0.4,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  IconlyLight.timeCircle,
                                  size: 16,
                                  color: Color(0xFF64748B),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  widget.layanan.durasiMenit != null
                                      ? '${widget.layanan.durasiMenit} Min'
                                      : '${widget.layanan.jumlahVisit ?? 1}x Visit',
                                  style: TextStyle(
                                    fontSize: screenWidth < 360 ? 12 : 13,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 14,
                              color: Color(0xFF64748B),
                              height: 1.5,
                            ),
                            children: [
                              TextSpan(
                                text: (widget.layanan.deskripsi != null &&
                                        widget.layanan.deskripsi!.trim().isNotEmpty)
                                    ? (_isDescriptionExpanded
                                        ? '${widget.layanan.deskripsi!} '
                                        : (widget.layanan.deskripsi!.length > 95
                                            ? '${widget.layanan.deskripsi!.substring(0, 95)}... '
                                            : '${widget.layanan.deskripsi!} '))
                                    : 'Layanan perawatan medis dan pendampingan kesehatan berkualitas langsung di rumah Anda. ',
                              ),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.baseline,
                                baseline: TextBaseline.alphabetic,
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isDescriptionExpanded = !_isDescriptionExpanded;
                                    });
                                  },
                                  child: Text(
                                    _isDescriptionExpanded
                                        ? 'Tutup'
                                        : 'Lihat Selengkapnya',
                                    style: const TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: BookingMetricsGrid(layanan: widget.layanan),
                      ),
                      const SizedBox(height: 22),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildSegmentedPillTab(),
                      ),
                      const SizedBox(height: 20),
                      if (_selectedSegmentTab == 0) ...[
                        BookingStepIndicator(
                          currentStep: _currentStep,
                          horizontalPadding: 20,
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                if (_currentStep == 0)
                                  BookingScheduleStep(
                                    tanggalController: _tanggalController,
                                    jamController: _jamController,
                                    onPickDate: _pickDate,
                                    onPickTime: _pickTime,
                                  ),
                                if (_currentStep == 1)
                                  BookingLocationStep(
                                    alamatController: _alamatController,
                                    kotaController: _kotaController,
                                    kecamatanController: _kecamatanController,
                                    isLoadingProfile: _isLoadingProfile,
                                    onUseProfile: () {
                                      if (_profileData != null) {
                                        setState(() {
                                          _alamatController.text = (_profileData!['alamat'] ?? '').toString();
                                          _kotaController.text = (_profileData!['kota'] ?? '').toString();
                                          _kecamatanController.text = (_profileData!['kecamatan'] ?? '').toString();
                                        });
                                      }
                                    },
                                  ),
                                if (_currentStep == 2)
                                  BookingDetailsStep(
                                    catatanController: _catatanController,
                                    qty: _qty,
                                    onIncrementQty: () => setState(() => _qty++),
                                    onDecrementQty: () => setState(() {
                                      if (_qty > 1) _qty--;
                                    }),
                                    kondisiPasienBytes: _kondisiPasienBytes,
                                    onPickImage: _pickImage,
                                    inputDecoration: _inputDecoration,
                                  ),
                                if (_currentStep == 3)
                                  BookingAddonsStep(
                                    isLoadingAddons: _isLoadingAddons,
                                    availableAddons: _availableAddons,
                                    selectedAddons: _selectedAddons,
                                    onToggleAddon: (addon) {
                                      setState(() {
                                        if (_selectedAddons.contains(addon)) {
                                          _selectedAddons.remove(addon);
                                        } else {
                                          _selectedAddons.add(addon);
                                        }
                                      });
                                    },
                                    onIncrementAddon: (addon) {
                                      setState(() => addon.qty++);
                                    },
                                    onDecrementAddon: (addon) {
                                      setState(() {
                                        if (addon.qty > 1) {
                                          addon.qty--;
                                        } else {
                                          _selectedAddons.remove(addon);
                                        }
                                      });
                                    },
                                    formatRupiah: AppFormatters.currency,
                                  ),
                                if (_currentStep == 4)
                                  BookingSummaryStep(
                                    namaLayanan: widget.layanan.namaLayanan,
                                    hargaLayanan: widget.layanan.hargaFix,
                                    tanggal: _tanggalController.text,
                                    jam: _jamController.text,
                                    lokasi: _kotaController.text,
                                    qty: _qty,
                                    selectedAddons: _selectedAddons,
                                    total: _calculateTotal(),
                                    formatRupiah: AppFormatters.currency,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: BookingSopSection(),
                        ),
                      ],
                      const SizedBox(height: 28),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: BookingSupervisorCard(),
                      ),
                      const SizedBox(height: 28),
                      BookingRelatedServicesSection(
                        relatedLayanan: _relatedLayanan,
                        onSelectLayanan: (rel) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PesanLayananPage(layanan: rel),
                            ),
                          );
                        },
                        onSeeAll: () => Navigator.pop(context),
                      ),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BookingBottomBar(
        currentStep: _currentStep,
        totalSteps: 5,
        totalPrice: _calculateTotal(),
        isSubmitting: _isSubmitting,
        onBack: () => setState(() => _currentStep--),
        onNextOrSubmit: _handleNextOrSubmit,
      ),
    );
  }

  Widget _buildSegmentedPillTab() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3F5),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedSegmentTab = 0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedSegmentTab == 0
                      ? const Color(0xFF0F3E3E)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: _selectedSegmentTab == 0
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0F3E3E).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Formulir Pemesanan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _selectedSegmentTab == 0
                          ? Colors.white
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedSegmentTab = 1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: _selectedSegmentTab == 1
                      ? const Color(0xFF0F3E3E)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: _selectedSegmentTab == 1
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0F3E3E).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Tata Cara & SOP',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _selectedSegmentTab == 1
                          ? Colors.white
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNextOrSubmit() {
    if (_selectedSegmentTab != 0) {
      setState(() => _selectedSegmentTab = 0);
      return;
    }

    if (_currentStep == 2 && _kondisiPasienBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon upload foto kondisi pasien terlebih dahulu'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    if (_currentStep < 4) {
      if (_formKey.currentState!.validate()) {
        setState(() => _currentStep++);
      }
    } else {
      _submitOrder();
    }
  }
}

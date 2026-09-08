import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/services/storage_service.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';
import 'package:home_care/features/orders/domain/order_pricing_calculator.dart';
import 'package:home_care/features/orders/presentation/widgets/booking/booking_addons_step.dart';
import 'package:home_care/features/orders/presentation/widgets/booking/booking_bottom_bar.dart';
import 'package:home_care/features/orders/presentation/widgets/booking/booking_details_step.dart';
import 'package:home_care/features/orders/presentation/widgets/booking/booking_location_step.dart';
import 'package:home_care/features/orders/presentation/widgets/booking/booking_schedule_step.dart';
import 'package:home_care/features/orders/presentation/widgets/booking/booking_step_indicator.dart';
import 'package:home_care/features/orders/presentation/widgets/booking/booking_summary_step.dart';
import 'package:home_care/users/layanan_page.dart';
import 'package:home_care/users/payment_method_page.dart';
import 'package:home_care/utils/app_cached_image.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

export 'package:home_care/features/orders/domain/addon_model.dart';

String get kBaseUrl => ApiConstants.apiBase;

class PesanLayananPage extends StatefulWidget {
  final Layanan layanan;

  const PesanLayananPage({super.key, required this.layanan});

  @override
  State<PesanLayananPage> createState() => _PesanLayananPageState();
}

class _PesanLayananPageState extends State<PesanLayananPage> {
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
      final token = await StorageService.getToken();
      if (token == null) return;

      final uri = Uri.parse('$kBaseUrl/me');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          final data = body['data'] as Map<String, dynamic>;
          final pasien = data['pasien'] as Map<String, dynamic>?;

          if (pasien != null) {
            setState(() {
              _profileData = pasien;
              _alamatController.text = pasien['alamat']?.toString() ?? '';
              _kecamatanController.text = pasien['kecamatan']?.toString() ?? '';
              _kotaController.text = pasien['kota']?.toString() ?? '';
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingProfile = false);
      }
    }
  }

  Future<void> _fetchAddons() async {
    setState(() => _isLoadingAddons = true);

    try {
      final token = await StorageService.getToken();
      if (token == null) return;

      final uri = Uri.parse(
        '$kBaseUrl/pasien/layanan/${widget.layanan.id}/addons',
      );

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true) {
          final List<dynamic> data = body['data'] ?? [];
          setState(() {
            _availableAddons = data.map((e) => Addon.fromJson(e)).toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching addons: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingAddons = false);
      }
    }
  }

  Future<void> _fetchRelatedServices() async {
    try {
      final token = await StorageService.getToken();
      final uri = Uri.parse('$kBaseUrl/pasien/layanan');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = json.decode(response.body);
        if (body['success'] == true && body['data'] != null) {
          final List<dynamic> list = body['data'] is List ? body['data'] : [];
          setState(() {
            _relatedLayanan =
                list
                    .map((e) => Layanan.fromJson(e))
                    .where((item) => item.id != widget.layanan.id)
                    .take(6)
                    .toList();
          });
        }
      }
    } catch (e) {
      debugPrint('Error fetching related services: $e');
    }
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
      final token = await StorageService.getToken();

      if (token == null || token.isEmpty) {
        throw Exception('Token tidak ditemukan. Silakan login ulang.');
      }

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$kBaseUrl/pasien/order-layanan'),
      );

      request.headers['Accept'] = 'application/json';
      request.headers['Authorization'] = 'Bearer $token';

      request.fields['layanan_id'] = widget.layanan.id.toString();
      request.fields['tanggal_mulai'] = DateFormat(
        'yyyy-MM-dd',
      ).format(_selectedDate!);
      request.fields['jam_mulai'] =
          '${_selectedTime!.hour.toString().padLeft(2, '0')}:${_selectedTime!.minute.toString().padLeft(2, '0')}';
      request.fields['alamat_lengkap'] = _alamatController.text.trim();
      request.fields['kecamatan'] = _kecamatanController.text.trim();
      request.fields['kota'] = _kotaController.text.trim();
      request.fields['qty'] = _qty.toString();

      if (_catatanController.text.trim().isNotEmpty) {
        request.fields['catatan_pasien'] = _catatanController.text.trim();
      }

      if (_kondisiPasienImage != null && _kondisiPasienBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'kondisi_pasien',
            _kondisiPasienBytes!,
            filename: _kondisiPasienImage!.name,
          ),
        );
      }

      if (_selectedAddons.isNotEmpty) {
        final addonsData =
            _selectedAddons
                .map((addon) => {'addon_id': addon.id, 'qty': addon.qty})
                .toList();
        request.fields['addons'] = json.encode(addonsData);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      debugPrint('RESPONSE STATUS: ${response.statusCode}');
      debugPrint('RESPONSE BODY: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          final data = responseData['data'];
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
              builder:
                  (_) => PaymentMethodPage(
                    draftId: draftId,
                    totalBayar:
                        (totalBayar is int)
                            ? totalBayar
                            : (totalBayar is double)
                            ? totalBayar.toInt()
                            : int.tryParse(totalBayar.toString()) ?? 0,
                  ),
            ),
          );
        } else {
          throw Exception(responseData['message'] ?? 'Gagal membuat pesanan');
        }
      } else if (response.statusCode == 422) {
        final errorData = json.decode(response.body);
        final errors = errorData['errors'] as Map<String, dynamic>?;

        if (errors != null) {
          final errorMessages = errors.values
              .expand((e) => e is List ? e : [e])
              .join('\n');

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Validasi gagal:\n$errorMessages'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
            ),
          );
        } else {
          throw Exception('Validasi gagal');
        }
      } else {
        throw Exception('Server error (${response.statusCode})');
      }
    } catch (e, stackTrace) {
      debugPrint('ERROR SUBMIT ORDER: $e');
      debugPrint('STACK TRACE: $stackTrace');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _formatRupiah(double amount) => AppFormatters.currency(amount);

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
    final screenWidth = MediaQuery.of(context).size.width;
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
          // 1. Immersive Hero Image with Floating Squircle Action Buttons & Smooth Collapsing Title
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
                          color:
                              _isFavorite
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
                // Smoothly fade in title as the hero scrolls away (between 130px and 210px)
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
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: AnimatedBuilder(
                animation: _scrollController,
                builder: (context, _) {
                  double offset = 0;
                  if (_scrollController.hasClients) {
                    offset = _scrollController.offset;
                  }
                  final double opacity = ((offset - 170) / 40).clamp(0.0, 1.0);
                  return Container(
                    height: 1.0,
                    color: const Color(0xFFE2E8F0).withValues(alpha: opacity),
                  );
                },
              ),
            ),
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
                  // Smooth bottom curved overlay (Matching Reference Screenshot)
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

          // 2. Overlapping Curved Sheet Body (Responsive & Silky Smooth)
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Drag Handle
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

                      // Header Row: Title & Clean Duration Indicator (Responsive across all screens)
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

                      // Subtitle / Description with inline bold "Lihat Selengkapnya" (Matching Screenshot)
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
                                text:
                                    (widget.layanan.deskripsi != null &&
                                            widget.layanan.deskripsi!
                                                .trim()
                                                .isNotEmpty)
                                        ? (_isDescriptionExpanded
                                            ? '${widget.layanan.deskripsi!} '
                                            : (widget
                                                        .layanan
                                                        .deskripsi!
                                                        .length >
                                                    95
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
                                      _isDescriptionExpanded =
                                          !_isDescriptionExpanded;
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

                      // 3. 2x2 Quick Metrics Grid
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _build2x2MetricsGrid(),
                      ),

                      const SizedBox(height: 22),

                      // 4. Segmented Pill Switch (Ingredients vs Instructions style)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildSegmentedPillTab(),
                      ),

                      const SizedBox(height: 20),

                      // 5. Active Tab View
                      if (_selectedSegmentTab == 0) ...[
                        // Step Indicator
                        BookingStepIndicator(
                          currentStep: _currentStep,
                          horizontalPadding: 20,
                        ),

                        const SizedBox(height: 16),

                        // Active Step Form
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                if (_currentStep == 0) _buildScheduleForm(),
                                if (_currentStep == 1) _buildLocationForm(),
                                if (_currentStep == 2) _buildDetailsForm(),
                                if (_currentStep == 3) _buildAddonsSection(),
                                if (_currentStep == 4) _buildSummary(),
                              ],
                            ),
                          ),
                        ),
                      ] else ...[
                        // Panduan & SOP Kunjungan
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: _buildInstructionsSection(),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // 6. Medical Supervisor Section ("Creator" style)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _buildCreatorSection(),
                      ),

                      const SizedBox(height: 28),

                      // 7. Layanan Terkait ("Related Recipes" style)
                      _buildRelatedServicesSection(),

                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _build2x2MetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: IconlyLight.bag2,
                title: widget.layanan.tipeLayanan.toUpperCase(),
                subtitle: 'Tipe Layanan',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: IconlyLight.swap,
                title: '${widget.layanan.jumlahVisit ?? 1}x Visit',
                subtitle: 'Frekuensi Visit',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildMetricCard(
                icon: IconlyLight.activity,
                title: (widget.layanan.syaratPerawat ?? 'Umum').toUpperCase(),
                subtitle: 'Tenaga Medis',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildMetricCard(
                icon: IconlyLight.wallet,
                title: _formatRupiah(widget.layanan.hargaFix),
                subtitle: 'Tarif Dasar',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5FAF9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5F1F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: HCColor.lightTeal,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: HCColor.primary, size: 18),
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
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ),
        ],
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
                  color:
                      _selectedSegmentTab == 0
                          ? const Color(0xFF0F3E3E)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow:
                      _selectedSegmentTab == 0
                          ? [
                            BoxShadow(
                              color: const Color(
                                0xFF0F3E3E,
                              ).withValues(alpha: 0.25),
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
                      color:
                          _selectedSegmentTab == 0
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
                  color:
                      _selectedSegmentTab == 1
                          ? const Color(0xFF0F3E3E)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow:
                      _selectedSegmentTab == 1
                          ? [
                            BoxShadow(
                              color: const Color(
                                0xFF0F3E3E,
                              ).withValues(alpha: 0.25),
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
                      color:
                          _selectedSegmentTab == 1
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

  Widget _buildInstructionsSection() {
    final sops = [
      {
        'title': 'Konfirmasi Jadwal',
        'desc':
            'Perawat akan menghubungi keluarga pasien 1 jam sebelum kedatangan.',
        'icon': IconlyLight.timeCircle,
      },
      {
        'title': 'Protokol Kebersihan & APD',
        'desc':
            'Tenaga medis menggunakan masker medis, hand-sanitizer, dan seragam resmi.',
        'icon': IconlyLight.shieldDone,
      },
      {
        'title': 'Pemeriksaan Awal (TTV)',
        'desc':
            'Pengecekan tensi darah, detak jantung, suhu, dan saturasi oksigen.',
        'icon': IconlyLight.activity,
      },
      {
        'title': 'Tindakan Keperawatan',
        'desc':
            'Pelaksanaan prosedur medis sesuai paket yang dipilih dan catatan pasien.',
        'icon': IconlyLight.document,
      },
      {
        'title': 'Edukasi & Laporan Visit',
        'desc':
            'Keluarga menerima ringkasan catatan perkembangan pasien pasca visit.',
        'icon': IconlyLight.tickSquare,
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEEF2F6)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prosedur Layanan Medis (SOP)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Standar pelayanan klinis menjamin kenyamanan dan keamanan pasien',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 18),
          ...sops.asMap().entries.map((entry) {
            final idx = entry.key + 1;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: HCColor.lightTeal,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        '$idx',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: HCColor.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          item['desc'] as String,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCreatorSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Standar Mutu & Tenaga Medis',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFEEF2F6)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      HCColor.primary,
                      HCColor.primary.withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: const Center(
                  child: Icon(
                    IconlyBold.shieldDone,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tenaga Medis Berlisensi STR Aktif',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      'Perawat profesional terverifikasi ditugaskan oleh koordinator medis',
                      style: TextStyle(fontSize: 12, color: HCColor.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRelatedServicesSection() {
    if (_relatedLayanan.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Layanan Terkait',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: HCColor.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 145,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: _relatedLayanan.length,
            itemBuilder: (context, index) {
              final rel = _relatedLayanan[index];
              return GestureDetector(
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PesanLayananPage(layanan: rel),
                    ),
                  );
                },
                child: Container(
                  width: 125,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          width: 125,
                          height: 90,
                          color: const Color(0xFFE8F6F6),
                          child:
                              rel.gambarUrl != null
                                  ? AppCachedImage(
                                    imageUrl: rel.gambarUrl,
                                    width: 125,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  )
                                  : const Center(
                                    child: Icon(
                                      IconlyLight.activity,
                                      size: 32,
                                      color: HCColor.primary,
                                    ),
                                  ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        rel.namaLayanan,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _formatRupiah(rel.hargaFix),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: HCColor.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleForm() {
    return BookingScheduleStep(
      tanggalController: _tanggalController,
      jamController: _jamController,
      onPickDate: _pickDate,
      onPickTime: _pickTime,
    );
  }

  Widget _buildLocationForm() {
    return BookingLocationStep(
      alamatController: _alamatController,
      kotaController: _kotaController,
      kecamatanController: _kecamatanController,
      isLoadingProfile: _isLoadingProfile,
      onUseProfile: () {
        if (_profileData != null) {
          setState(() {
            _alamatController.text = (_profileData!['alamat'] ?? '').toString();
            _kotaController.text = (_profileData!['kota'] ?? '').toString();
            _kecamatanController.text =
                (_profileData!['kecamatan'] ?? '').toString();
          });
        }
      },
    );
  }

  Widget _buildDetailsForm() {
    return BookingDetailsStep(
      catatanController: _catatanController,
      qty: _qty,
      onIncrementQty: () => setState(() => _qty++),
      onDecrementQty:
          () => setState(() {
            if (_qty > 1) _qty--;
          }),
      kondisiPasienBytes: _kondisiPasienBytes,
      onPickImage: _pickImage,
      inputDecoration: _inputDecoration,
    );
  }

  Widget _buildAddonsSection() {
    return BookingAddonsStep(
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
        setState(() {
          addon.qty++;
        });
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
      formatRupiah: _formatRupiah,
    );
  }

  Widget _buildSummary() {
    final total = OrderPricingCalculator.calculateTotal(
      basePrice: widget.layanan.hargaFix,
      quantity: _qty,
      selectedAddons: _selectedAddons,
    );

    return BookingSummaryStep(
      namaLayanan: widget.layanan.namaLayanan,
      hargaLayanan: widget.layanan.hargaFix,
      tanggal: _tanggalController.text,
      jam: _jamController.text,
      lokasi: _kotaController.text,
      qty: _qty,
      selectedAddons: _selectedAddons,
      total: total,
      formatRupiah: _formatRupiah,
    );
  }

  Widget _buildBottomBar() {
    return BookingBottomBar(
      currentStep: _currentStep,
      totalSteps: 5,
      totalPrice: _calculateTotal(),
      isSubmitting: _isSubmitting,
      onBack: () => setState(() => _currentStep--),
      onNextOrSubmit: _handleNextOrSubmit,
    );
  }

  void _handleNextOrSubmit() {
    // Automatically switch to tab 0 if user taps bottom bar while viewing SOP
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

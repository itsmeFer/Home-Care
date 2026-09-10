import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_image_compressor.dart';
import 'package:home_care/features/orders/domain/order_pricing_calculator.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';
import 'package:home_care/users/pemesanan/payment_method_page.dart';
import 'package:home_care/users/pemesanan/services/booking_service.dart';
import 'package:home_care/users/pemesanan/widgets/widgets.dart';
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
        // Pre-upload client side image compression
        final compressedBytes = await AppImageCompressor.compressXFile(pickedFile);
        setState(() {
          _kondisiPasienImage = pickedFile;
          _kondisiPasienBytes = compressedBytes;
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
          BookingHeroAppBar(
            layanan: widget.layanan,
            scrollController: _scrollController,
            expandedHeroHeight: expandedHeroHeight,
            isFavorite: _isFavorite,
            onToggleFavorite: () {
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
            onClose: () => Navigator.pop(context),
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
                      BookingHeaderTitleSection(
                        layanan: widget.layanan,
                        screenWidth: screenWidth,
                        isDescriptionExpanded: _isDescriptionExpanded,
                        onToggleDescription: () {
                          setState(() {
                            _isDescriptionExpanded = !_isDescriptionExpanded;
                          });
                        },
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: BookingMetricsGrid(layanan: widget.layanan),
                      ),
                      const SizedBox(height: 22),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: BookingSegmentedTab(
                          selectedSegmentTab: _selectedSegmentTab,
                          onTabChanged: (tab) => setState(() => _selectedSegmentTab = tab),
                        ),
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
                          child: BookingStepContent(
                            currentStep: _currentStep,
                            formKey: _formKey,
                            tanggalController: _tanggalController,
                            jamController: _jamController,
                            onPickDate: _pickDate,
                            onPickTime: _pickTime,
                            alamatController: _alamatController,
                            kotaController: _kotaController,
                            kecamatanController: _kecamatanController,
                            isLoadingProfile: _isLoadingProfile,
                            onUseProfile: () {
                              if (_profileData != null) {
                                setState(() {
                                  _alamatController.text =
                                      (_profileData!['alamat'] ?? '').toString();
                                  _kotaController.text =
                                      (_profileData!['kota'] ?? '').toString();
                                  _kecamatanController.text =
                                      (_profileData!['kecamatan'] ?? '')
                                          .toString();
                                });
                              }
                            },
                            catatanController: _catatanController,
                            qty: _qty,
                            onIncrementQty: () => setState(() => _qty++),
                            onDecrementQty: () => setState(() {
                              if (_qty > 1) _qty--;
                            }),
                            kondisiPasienBytes: _kondisiPasienBytes,
                            onPickImage: _pickImage,
                            inputDecoration: _inputDecoration,
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
                            layanan: widget.layanan,
                            total: _calculateTotal(),
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

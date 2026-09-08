import 'dart:convert';
import 'package:home_care/core/services/storage_service.dart';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_care/users/layanan_page.dart';
import 'package:home_care/users/payment_method_page.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_care/features/orders/domain/addon_model.dart';
import 'package:home_care/features/orders/domain/order_pricing_calculator.dart';
import 'package:home_care/features/orders/presentation/widgets/booking/booking_step_indicator.dart';
import 'package:home_care/features/orders/presentation/widgets/booking/booking_schedule_step.dart';
import 'package:home_care/features/orders/presentation/widgets/booking/booking_location_step.dart';
import 'package:home_care/features/orders/presentation/widgets/booking/booking_bottom_bar.dart';
import 'package:home_care/features/orders/presentation/widgets/booking/booking_details_step.dart';
import 'package:home_care/features/orders/presentation/widgets/booking/booking_addons_step.dart';
import 'package:home_care/features/orders/presentation/widgets/booking/booking_summary_step.dart';

export 'package:home_care/features/orders/domain/addon_model.dart';

String get kBaseUrl => ApiConstants.apiBase;

class PesanLayananPage extends StatefulWidget {
  final Layanan layanan;

  const PesanLayananPage({Key? key, required this.layanan}) : super(key: key);

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
  List<Addon> _selectedAddons = [];

  bool _isSubmitting = false;
  int _currentStep = 0;

  bool _isLoadingProfile = false;
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _fetchProfileData();
    _fetchAddons();
  }

  @override
  void dispose() {
    _tanggalController.dispose();
    _jamController.dispose();
    _alamatController.dispose();
    _kecamatanController.dispose();
    _kotaController.dispose();
    _catatanController.dispose();
    super.dispose();
  }

  bool _isSmallScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 360;

  bool _isMediumScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 430;

  double _horizontalPagePadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 12;
    if (width < 430) return 14;
    return 16;
  }

  double _sectionPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < 360) return 16;
    return 20;
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
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: HCColor.primary, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColor.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            backgroundColor: HCColor.primary,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background:
                  widget.layanan.gambarUrl != null
                      ? Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            widget.layanan.gambarUrl!,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => Container(
                                  color: HCColor.lightTeal,
                                  child: const Icon(
                                    Icons.medical_services,
                                    size: 64,
                                    color: HCColor.primary,
                                  ),
                                ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  Colors.black.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ],
                      )
                      : Container(
                        color: HCColor.lightTeal,
                        child: const Icon(
                          Icons.medical_services,
                          size: 64,
                          color: HCColor.primary,
                        ),
                      ),
            ),
          ),
          SliverToBoxAdapter(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderCard(),
                  _buildAboutSection(),
                  _buildStepIndicator(),
                  if (_currentStep == 0) _buildScheduleForm(),
                  if (_currentStep == 1) _buildLocationForm(),
                  if (_currentStep == 2) _buildDetailsForm(),
                  if (_currentStep == 3) _buildAddonsSection(),
                  if (_currentStep == 4) _buildSummary(),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildCardSection({required Widget child}) {
    return Container(
      margin: EdgeInsets.fromLTRB(
        _horizontalPagePadding(context),
        16,
        _horizontalPagePadding(context),
        0,
      ),
      padding: EdgeInsets.all(_sectionPadding(context)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildHeaderCard() {
    final small = _isSmallScreen(context);

    return _buildCardSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          small
              ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _formatRupiah(widget.layanan.hargaFix),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: HCColor.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (widget.layanan.kategori != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: HCColor.lightTeal,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.layanan.kategori!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: HCColor.primary,
                        ),
                      ),
                    ),
                ],
              )
              : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      _formatRupiah(widget.layanan.hargaFix),
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: HCColor.primary,
                      ),
                    ),
                  ),
                  if (widget.layanan.kategori != null)
                    Container(
                      margin: const EdgeInsets.only(left: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: HCColor.lightTeal,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        widget.layanan.kategori!,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: HCColor.primary,
                        ),
                      ),
                    ),
                ],
              ),
          const SizedBox(height: 12),
          Text(
            widget.layanan.namaLayanan,
            style: TextStyle(
              fontSize: small ? 18 : 20,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
              height: 1.3,
            ),
          ),
          if (widget.layanan.deskripsi != null &&
              widget.layanan.deskripsi!.trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.layanan.deskripsi!,
              style: const TextStyle(
                fontSize: 13,
                color: HCColor.textMuted,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return _buildCardSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tentang Layanan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                Icons.inventory_2,
                widget.layanan.tipeLayanan == 'paket' ? 'Paket' : 'Single',
              ),
              if (widget.layanan.durasiMenit != null)
                _buildInfoChip(
                  Icons.access_time,
                  '${widget.layanan.durasiMenit} menit',
                ),
              if (widget.layanan.jumlahVisit != null)
                _buildInfoChip(
                  Icons.repeat,
                  '${widget.layanan.jumlahVisit}x visit',
                ),
              if (widget.layanan.syaratPerawat != null)
                _buildInfoChip(
                  Icons.medical_services,
                  widget.layanan.syaratPerawat!.toUpperCase(),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: HCColor.lightTeal,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: HCColor.primary.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: HCColor.primary),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: HCColor.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator() {
    return BookingStepIndicator(
      currentStep: _currentStep,
      horizontalPadding: _horizontalPagePadding(context),
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
            _kecamatanController.text = (_profileData!['kecamatan'] ?? '').toString();
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
      onDecrementQty: () => setState(() => _qty--),
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

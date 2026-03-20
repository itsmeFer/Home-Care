import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:home_care/users/layananPage.dart';
import 'package:home_care/users/payment_method_page.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kBaseUrl = 'http://147.93.81.243/api';

class HCColor {
  static const primary = Color(0xFF0BA5A7);
  static const primaryDark = Color(0xFF088088);
  static const bg = Color(0xFFF5F7FA);
  static const card = Colors.white;
  static const textMuted = Colors.black54;
  static const lightTeal = Color(0xFFE0F7F7);
}

class Addon {
  final int id;
  final String namaAddon;
  final double hargaFix;
  final bool isQtyEnabled;
  int qty;

  Addon({
    required this.id,
    required this.namaAddon,
    required this.hargaFix,
    required this.isQtyEnabled,
    this.qty = 1,
  });

  factory Addon.fromJson(Map<String, dynamic> json) {
    return Addon(
      id: json['id'] as int,
      namaAddon: json['nama_addon'] ?? '',
      hargaFix: _parseDouble(json['harga_fix']),
      isQtyEnabled:
          json['is_qty_enabled'] == 1 || json['is_qty_enabled'] == true,
    );
  }

  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

class PesanLayananPage extends StatefulWidget {
  final Layanan layanan;

  const PesanLayananPage({
    Key? key,
    required this.layanan,
  }) : super(key: key);

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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuka kamera: $e')),
      );
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
    final subtotal = widget.layanan.hargaFix * _qty;
    final addonsTotal = _selectedAddons.fold<double>(
      0,
      (sum, addon) => sum + (addon.hargaFix * addon.qty),
    );
    return subtotal + addonsTotal;
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
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

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
      request.fields['tanggal_mulai'] =
          DateFormat('yyyy-MM-dd').format(_selectedDate!);
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
        final addonsData = _selectedAddons
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

  String _formatRupiah(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
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
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
              background: widget.layanan.gambarUrl != null
                  ? Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          widget.layanan.gambarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
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
    final steps = ['Jadwal', 'Lokasi', 'Detail', 'Add-ons', 'Ringkasan'];

    return Container(
      margin: EdgeInsets.fromLTRB(
        _horizontalPagePadding(context),
        16,
        _horizontalPagePadding(context),
        0,
      ),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: Row(
          children: List.generate(steps.length, (index) {
            final isActive = index == _currentStep;
            final isDone = index < _currentStep;

            return Padding(
              padding: EdgeInsets.only(right: index == steps.length - 1 ? 0 : 14),
              child: Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isDone
                          ? HCColor.primary
                          : (isActive ? HCColor.lightTeal : Colors.grey[200]),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isActive ? HCColor.primary : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check, color: Colors.white, size: 18)
                          : Text(
                              '${index + 1}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: isActive ? HCColor.primary : Colors.grey,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    steps[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive ? HCColor.primary : Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildScheduleForm() {
    return _buildCardSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jadwal Kunjungan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _tanggalController,
            readOnly: true,
            onTap: _pickDate,
            decoration: _inputDecoration(
              labelText: 'Tanggal',
              prefixIcon: const Icon(
                Icons.calendar_today,
                color: HCColor.primary,
              ),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Pilih tanggal kunjungan';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _jamController,
            readOnly: true,
            onTap: _pickTime,
            decoration: _inputDecoration(
              labelText: 'Jam',
              prefixIcon: const Icon(Icons.access_time, color: HCColor.primary),
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Pilih jam kunjungan';
              }
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLocationForm() {
    final small = _isMediumScreen(context);

    return _buildCardSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          small
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Lokasi Kunjungan',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    _buildUseProfileButton(),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Expanded(
                      child: Text(
                        'Lokasi Kunjungan',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    _buildUseProfileButton(),
                  ],
                ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HCColor.lightTeal,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: HCColor.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Alamat dari profil Anda sudah dimuat otomatis. Anda bisa mengeditnya jika berbeda.',
                    style: TextStyle(
                      fontSize: _isSmallScreen(context) ? 10.5 : 11,
                      color: HCColor.textMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _alamatController,
            maxLines: 3,
            decoration: _inputDecoration(
              labelText: 'Alamat Lengkap',
              hintText: 'Masukkan alamat lengkap...',
              alignLabelWithHint: true,
              prefixIcon: const Padding(
                padding: EdgeInsets.only(top: 12, left: 12),
                child: Icon(Icons.home_outlined, color: HCColor.primary),
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Masukkan alamat lengkap';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _kecamatanController,
            decoration: _inputDecoration(
              labelText: 'Kecamatan',
              hintText: 'Contoh: Medan Kota',
              prefixIcon: const Icon(
                Icons.location_city,
                color: HCColor.primary,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Masukkan kecamatan';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _kotaController,
            decoration: _inputDecoration(
              labelText: 'Kota',
              hintText: 'Contoh: Medan',
              prefixIcon: const Icon(Icons.location_on, color: HCColor.primary),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Masukkan kota';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          if (_profileData != null &&
              (_profileData!['alamat']?.toString().isNotEmpty ?? false))
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bookmark, size: 16, color: HCColor.textMuted),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Alamat di Profil:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: HCColor.textMuted,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _profileData!['alamat']?.toString() ?? '-',
                    style: const TextStyle(fontSize: 12, color: Colors.black87),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_profileData!['kecamatan'] ?? '-'}, ${_profileData!['kota'] ?? '-'}',
                    style: TextStyle(fontSize: 11, color: HCColor.textMuted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUseProfileButton() {
    return TextButton.icon(
      onPressed: _isLoadingProfile
          ? null
          : () {
              if (_profileData != null) {
                setState(() {
                  _alamatController.text =
                      _profileData!['alamat']?.toString() ?? '';
                  _kecamatanController.text =
                      _profileData!['kecamatan']?.toString() ?? '';
                  _kotaController.text =
                      _profileData!['kota']?.toString() ?? '';
                });

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Alamat profil berhasil dimuat'),
                    duration: Duration(seconds: 2),
                    backgroundColor: HCColor.primary,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Profil tidak ditemukan'),
                    backgroundColor: Colors.orange,
                  ),
                );
              }
            },
      icon: _isLoadingProfile
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.my_location, size: 16),
      label: Text(
        _isLoadingProfile ? 'Loading...' : 'Gunakan Profil',
        style: const TextStyle(fontSize: 12),
      ),
      style: TextButton.styleFrom(
        foregroundColor: HCColor.primary,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
    );
  }

  Widget _buildDetailsForm() {
    final small = _isSmallScreen(context);

    return _buildCardSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Tambahan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          small ? _buildQuantityCompact() : _buildQuantityNormal(),
          const SizedBox(height: 16),
          TextFormField(
            controller: _catatanController,
            maxLines: 3,
            decoration: _inputDecoration(
              labelText: 'Catatan (opsional)',
              hintText: 'Tambahkan catatan khusus...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: const [
              Text(
                'Foto Kondisi Pasien',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withOpacity(0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ambil foto terkini kondisi pasien untuk membantu tenaga medis.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blue[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _pickImage,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: 180,
                maxHeight: _kondisiPasienBytes != null ? 420 : 180,
              ),
              decoration: BoxDecoration(
                color: _kondisiPasienBytes == null
                    ? HCColor.lightTeal
                    : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _kondisiPasienBytes == null
                      ? HCColor.primary.withOpacity(0.3)
                      : HCColor.primary,
                  width: 2,
                ),
              ),
              child: _kondisiPasienBytes == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 50,
                          color: HCColor.primary.withOpacity(0.7),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Tap untuk ambil foto',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: HCColor.primary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Ukuran maks: 5MB',
                          style: TextStyle(
                            fontSize: 11,
                            color: HCColor.textMuted,
                          ),
                        ),
                      ],
                    )
                  : Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.memory(
                            _kondisiPasienBytes!,
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        ),
                        Positioned(
                          top: 12,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Foto Terupload',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          right: 12,
                          child: Material(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            elevation: 3,
                            child: InkWell(
                              onTap: _pickImage,
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.edit,
                                      size: 16,
                                      color: HCColor.primary,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Ganti Foto',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: HCColor.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (_kondisiPasienBytes == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_rounded, size: 14, color: Colors.red[700]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Foto kondisi pasien wajib diupload',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildQuantityNormal() {
    return Row(
      children: [
        const Text(
          'Quantity',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        IconButton(
          onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
          icon: const Icon(Icons.remove_circle_outline),
          color: HCColor.primary,
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: HCColor.lightTeal,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            '$_qty',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: HCColor.primary,
            ),
          ),
        ),
        IconButton(
          onPressed: () => setState(() => _qty++),
          icon: const Icon(Icons.add_circle_outline),
          color: HCColor.primary,
        ),
      ],
    );
  }

  Widget _buildQuantityCompact() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quantity',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            IconButton(
              onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
              icon: const Icon(Icons.remove_circle_outline),
              color: HCColor.primary,
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: HCColor.lightTeal,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$_qty',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: HCColor.primary,
                ),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _qty++),
              icon: const Icon(Icons.add_circle_outline),
              color: HCColor.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAddonsSection() {
    return _buildCardSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tambahan (Opsional)',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (_isLoadingAddons)
            const Center(child: CircularProgressIndicator())
          else if (_availableAddons.isEmpty)
            Text(
              'Tidak ada add-ons tersedia',
              style: TextStyle(color: HCColor.textMuted),
            )
          else
            ..._availableAddons.map((addon) {
              final isSelected = _selectedAddons.contains(addon);

              return CheckboxListTile(
                value: isSelected,
                onChanged: (bool? value) {
                  setState(() {
                    if (value == true) {
                      _selectedAddons.add(addon);
                    } else {
                      _selectedAddons.remove(addon);
                    }
                  });
                },
                title: Text(
                  addon.namaAddon,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _formatRupiah(addon.hargaFix),
                  style: const TextStyle(
                    fontSize: 12,
                    color: HCColor.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                activeColor: HCColor.primary,
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              );
            }),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    final subtotal = widget.layanan.hargaFix * _qty;
    final addonsTotal = _selectedAddons.fold<double>(
      0,
      (sum, addon) => sum + (addon.hargaFix * addon.qty),
    );
    final total = subtotal + addonsTotal;
    final small = _isSmallScreen(context);

    return _buildCardSection(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Pesanan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _buildSummaryRow('Layanan', widget.layanan.namaLayanan),
          _buildSummaryRow('Tanggal', _tanggalController.text),
          _buildSummaryRow('Jam', _jamController.text),
          _buildSummaryRow('Lokasi', _kotaController.text),
          const Divider(height: 24),
          _buildSummaryRow(
            'Harga layanan',
            _formatRupiah(widget.layanan.hargaFix),
          ),
          _buildSummaryRow('Qty', '${_qty}x'),
          if (_selectedAddons.isNotEmpty) ...[
            const SizedBox(height: 8),
            ..._selectedAddons.map(
              (addon) => _buildSummaryRow(
                addon.namaAddon,
                _formatRupiah(addon.hargaFix),
              ),
            ),
          ],
          const Divider(height: 24),
          small
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Bayar',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatRupiah(total),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: HCColor.primary,
                      ),
                    ),
                  ],
                )
              : Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total Bayar',
                        style:
                            TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        _formatRupiah(total),
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: HCColor.primary,
                        ),
                      ),
                    ),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 5,
            child: Text(
              value,
              textAlign: TextAlign.right,
              softWrap: true,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    final small = _isMediumScreen(context);
    final padding = _horizontalPagePadding(context);

    return Container(
      padding: EdgeInsets.fromLTRB(padding, 12, padding, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: small ? _buildBottomBarCompact() : _buildBottomBarNormal(),
      ),
    );
  }

  Widget _buildBottomBarNormal() {
    return Row(
      children: [
        if (_currentStep > 0)
          Expanded(
            child: OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                side: const BorderSide(color: HCColor.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Kembali',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: HCColor.primary,
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(width: 12),
        Expanded(
          flex: _currentStep > 0 ? 1 : 2,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleNextOrSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: HCColor.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _currentStep < 4 ? 'Lanjut' : 'Pesan Sekarang',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomBarCompact() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_currentStep > 0)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => setState(() => _currentStep--),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                side: const BorderSide(color: HCColor.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Kembali',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: HCColor.primary,
                ),
              ),
            ),
          ),
        if (_currentStep > 0) const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isSubmitting ? null : _handleNextOrSubmit,
            style: ElevatedButton.styleFrom(
              backgroundColor: HCColor.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSubmitting
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(
                    _currentStep < 4 ? 'Lanjut' : 'Pesan Sekarang',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          ),
        ),
      ],
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
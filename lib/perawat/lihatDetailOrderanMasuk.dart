import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

const String kBaseUrl = 'http://192.168.1.5:8000/api';

class HCColor {
  static const primary = Color(0xFF0BA5A7);
  static const primaryDark = Color(0xFF088088);
  static const bg = Color(0xFFF5F7FA);
  static const card = Colors.white;
  static const textMuted = Colors.black54;
  static const lightTeal = Color(0xFFE0F7F7);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
}

class DetailOrderanMasukPerawatPage extends StatefulWidget {
  final int orderId;

  const DetailOrderanMasukPerawatPage({Key? key, required this.orderId})
      : super(key: key);

  @override
  State<DetailOrderanMasukPerawatPage> createState() =>
      _DetailOrderanMasukPerawatPageState();
}

class _DetailOrderanMasukPerawatPageState
    extends State<DetailOrderanMasukPerawatPage> with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;

  XFile? _fotoHadir;
  bool _isUploadingSampai = false;

  XFile? _fotoSelesai;
  bool _isUploadingSelesai = false;

  XFile? _fotoBuktiPembayaran;
  bool _isUploadingBuktiBayar = false;

  final ImagePicker _picker = ImagePicker();
  Map<String, dynamic>? _order;
  
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this); // ✅ 5 tabs sekarang
    _fetchDetail();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  // ===== API CALLS =====
  
  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final token = await _getToken();
    if (token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Token tidak ditemukan. Silakan login sebagai perawat.';
      });
      return;
    }

    try {
      final uri = Uri.parse('$kBaseUrl/perawat/order-layanan/${widget.orderId}');
      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final success = decoded['success'] == true;

        if (!success) {
          setState(() {
            _isLoading = false;
            _error = decoded['message']?.toString() ?? 'Gagal memuat detail order.';
          });
          return;
        }

        setState(() {
          _order = decoded['data'] as Map<String, dynamic>;
          _isLoading = false;
        });
        
        // ✅ Debug print untuk cek addons
        print('📦 Order Addons: ${_order?['order_addons']}');
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Gagal memuat detail. Kode: ${response.statusCode}';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Terjadi kesalahan: $e';
      });
    }
  }

  Future<void> _onTerimaOrder() async {
    if (_order == null) return;

    final konfirmasi = await _showConfirmDialog(
      title: 'Terima Order',
      message: 'Anda yakin ingin menerima order ini dan menuju lokasi pasien?',
      confirmText: 'Ya, Terima',
    );

    if (konfirmasi != true) return;

    await _performAction(
      endpoint: '${widget.orderId}/terima',
      successMessage: 'Order diterima. Anda akan menuju lokasi pasien.',
    );
  }

  Future<void> _onTolakOrder() async {
    if (_order == null) return;

    final alasan = await _showReasonDialog();
    if (alasan == null) return;

    await _performActionWithBody(
      endpoint: '${widget.orderId}/tolak',
      body: {'alasan': alasan},
      successMessage: 'Order berhasil ditolak.',
      shouldPop: true,
    );
  }

  Future<void> _onMulaiVisit() async {
    final konfirmasi = await _showConfirmDialog(
      title: 'Mulai Tindakan',
      message: 'Apakah Anda sudah bertemu pasien dan siap memulai tindakan?',
      confirmText: 'Ya, Mulai',
    );

    if (konfirmasi != true) return;

    await _performAction(
      endpoint: '${widget.orderId}/mulai-visit',
      successMessage: 'Tindakan dimulai',
    );
  }

  Future<void> _onSudahSampaiDiTempat() async {
    if (_fotoHadir == null) {
      _showSnackBar('Silakan ambil foto hadir terlebih dahulu.', isError: true);
      return;
    }

    final konfirmasi = await _showConfirmDialog(
      title: 'Konfirmasi Kedatangan',
      message: 'Anda yakin sudah sampai di lokasi pasien?',
      confirmText: 'Ya, Kirim',
    );

    if (konfirmasi != true) return;

    await _uploadPhoto(
      endpoint: '${widget.orderId}/sampai',
      fieldName: 'foto_hadir',
      photo: _fotoHadir!,
      isUploadingFlag: () => _isUploadingSampai,
      setUploadingFlag: (val) => setState(() => _isUploadingSampai = val),
    );
  }

  Future<void> _onSelesaiTindakan() async {
    if (_fotoSelesai == null) {
      _showSnackBar('Silakan ambil foto setelah tindakan terlebih dahulu.', isError: true);
      return;
    }

    final konfirmasi = await _showConfirmDialog(
      title: 'Selesai Tindakan',
      message: 'Apakah tindakan sudah selesai?',
      confirmText: 'Ya, Selesai',
    );

    if (konfirmasi != true) return;

    await _uploadPhoto(
      endpoint: '${widget.orderId}/selesai',
      fieldName: 'foto_selesai',
      photo: _fotoSelesai!,
      isUploadingFlag: () => _isUploadingSelesai,
      setUploadingFlag: (val) => setState(() => _isUploadingSelesai = val),
    );
  }

  Future<void> _onUploadBuktiPembayaran() async {
    if (_fotoBuktiPembayaran == null) {
      _showSnackBar('Silakan ambil foto bukti pembayaran terlebih dahulu.', isError: true);
      return;
    }

    final konfirmasi = await _showConfirmDialog(
      title: 'Upload Bukti Pembayaran',
      message: 'Apakah Anda yakin ingin mengupload bukti pembayaran tunai?',
      confirmText: 'Ya, Upload',
    );

    if (konfirmasi != true) return;

    await _uploadPhoto(
      endpoint: '${widget.orderId}/upload-bukti-bayar',
      fieldName: 'bukti_pembayaran',
      photo: _fotoBuktiPembayaran!,
      isUploadingFlag: () => _isUploadingBuktiBayar,
      setUploadingFlag: (val) => setState(() => _isUploadingBuktiBayar = val),
    );
  }

  // ===== HELPER METHODS =====

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: HCColor.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }

  Future<String?> _showReasonDialog() async {
    final controller = TextEditingController();
    
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Alasan Menolak'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Silakan isi alasan kenapa Anda menolak order ini.'),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Contoh: Jadwal bentrok, lokasi terlalu jauh...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              final text = controller.text.trim();
              if (text.isEmpty) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(content: Text('Alasan tidak boleh kosong')),
                );
                return;
              }
              Navigator.of(ctx).pop(text);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HCColor.error,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Kirim'),
          ),
        ],
      ),
    );
  }

  Future<void> _performAction({
    required String endpoint,
    required String successMessage,
  }) async {
    final token = await _getToken();
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/perawat/order-layanan/$endpoint'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true) {
          setState(() {
            _order = decoded['data'];
            _isLoading = false;
          });
          _showSnackBar(successMessage);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Terjadi kesalahan: $e', isError: true);
    }
  }

  Future<void> _performActionWithBody({
    required String endpoint,
    required Map<String, dynamic> body,
    required String successMessage,
    bool shouldPop = false,
  }) async {
    final token = await _getToken();
    if (token == null) return;

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$kBaseUrl/perawat/order-layanan/$endpoint'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode(body),
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true) {
          _showSnackBar(successMessage);
          if (shouldPop) Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackBar('Terjadi kesalahan: $e', isError: true);
    }
  }

  Future<void> _uploadPhoto({
  required String endpoint,
  required String fieldName,
  required XFile photo,
  required bool Function() isUploadingFlag,
  required Function(bool) setUploadingFlag,
}) async {
  final token = await _getToken();
  if (token == null) return;

  setUploadingFlag(true);

  try {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$kBaseUrl/perawat/order-layanan/$endpoint'),
    )
      ..headers['Accept'] = 'application/json'
      ..headers['Authorization'] = 'Bearer $token';

    if (kIsWeb) {
      final bytes = await photo.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes(fieldName, bytes, filename: photo.name),
      );
    } else {
      request.files.add(
        await http.MultipartFile.fromPath(fieldName, photo.path),
      );
    }

    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);

    if (!mounted) return;

    setUploadingFlag(false);

    if (response.statusCode == 200) {
      final decoded = json.decode(response.body);
      
      // ✅ DEBUG: Print response untuk lihat struktur
      print('📦 Upload Response: ${response.body}');
      
      if (decoded['success'] == true) {
        setState(() {
          var data = decoded['data'];
          
          // ✅ PERBAIKAN: Cek struktur response
          if (data is Map<String, dynamic>) {
            // Jika data punya key 'order', ambil itu (format upload-bukti-bayar)
            if (data.containsKey('order')) {
              _order = data['order'] as Map<String, dynamic>;
              print('✅ Using data.order');
            } 
            // Jika tidak, data langsung adalah order (format sampai/selesai)
            else {
              _order = data;
              print('✅ Using data directly');
            }
          }
        });
        
        _showSnackBar('Berhasil');
        
        // ✅ PENTING: Refresh data untuk sync dengan backend
        await _fetchDetail();
      }
    }
  } catch (e) {
    if (!mounted) return;
    setUploadingFlag(false);
    _showSnackBar('Terjadi kesalahan: $e', isError: true);
  }
}

  Future<XFile?> _pickImage() async {
    try {
      ImageSource? source;

      if (kIsWeb) {
        source = ImageSource.gallery;
      } else {
        source = await showModalBottomSheet<ImageSource>(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (ctx) => SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: HCColor.primary),
                  title: const Text('Kamera'),
                  onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: HCColor.primary),
                  title: const Text('Galeri'),
                  onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      }

      if (source == null) return null;

      return await _picker.pickImage(source: source, imageQuality: 85);
    } catch (e) {
      _showSnackBar('Gagal mengambil foto: $e', isError: true);
      return null;
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? HCColor.error : HCColor.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ===== FORMATTING =====

  String _fmtTanggal(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  String _fmtDateTime(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      return DateFormat('dd MMM yyyy HH:mm').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  String _fmtJam(String? jam) {
    if (jam == null || jam.isEmpty) return '-';
    return jam.length >= 5 ? jam.substring(0, 5) : jam;
  }

  String _fmtUang(dynamic val) {
    if (val == null) return 'Rp 0';
    double d = val is num ? val.toDouble() : (double.tryParse(val.toString()) ?? 0);
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return formatter.format(d);
  }

  String _getNama(Map<String, dynamic>? obj) {
    if (obj == null) return '-';
    return obj['nama_lengkap']?.toString() ??
        obj['nama']?.toString() ??
        obj['full_name']?.toString() ??
        '-';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
      case 'menunggu_penugasan':
        return HCColor.warning;
      case 'mendapatkan_perawat':
        return Colors.blue;
      case 'sedang_dalam_perjalanan':
        return Colors.teal;
      case 'sampai_ditempat':
        return Colors.indigo;
      case 'sedang_berjalan':
        return Colors.purple;
      case 'selesai':
        return HCColor.success;
      case 'dibatalkan':
        return HCColor.error;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'menunggu_penugasan':
        return 'Menunggu Penugasan';
      case 'mendapatkan_perawat':
        return 'Menunggu Respon';
      case 'sedang_dalam_perjalanan':
        return 'Dalam Perjalanan';
      case 'sampai_ditempat':
        return 'Sudah Sampai';
      case 'sedang_berjalan':
        return 'Sedang Berjalan';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String? _mediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    var cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$kBaseUrl/media/$cleanPath';
  }

  // ===== UI BUILDERS =====

  @override
  Widget build(BuildContext context) {
    final kodeOrder = _order?['kode_order']?.toString() ?? 'Detail Order';
    final status = _order?['status_order']?.toString() ?? 'pending';

    return Scaffold(
      backgroundColor: HCColor.bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(kodeOrder, status),
          if (_isLoading)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    CircularProgressIndicator(color: HCColor.primary),
                    SizedBox(height: 16),
                    Text('Memuat detail order...'),
                  ],
                ),
              ),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: _buildError(),
            )
          else if (_order != null)
            SliverToBoxAdapter(
              child: _buildContent(),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar(String kodeOrder, String status) {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      backgroundColor: HCColor.primary,
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          kodeOrder,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [HCColor.primary, HCColor.primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _statusColor(status).withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.5)),
          ),
          child: Text(
            _statusLabel(status),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 64, color: HCColor.error),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchDetail,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HCColor.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return RefreshIndicator(
      onRefresh: _fetchDetail,
      color: HCColor.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildQuickInfo(),
            const SizedBox(height: 16),
            _buildTabbedContent(),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickInfo() {
    final o = _order!;
    final pasien = o['pasien'] as Map<String, dynamic>?;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: HCColor.lightTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.medical_services, color: HCColor.primary, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o['nama_layanan']?.toString() ?? '-',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Pasien: ${_getNama(pasien)}',
                      style: TextStyle(
                        fontSize: 13,
                        color: HCColor.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _quickInfoItem(
                icon: Icons.calendar_today,
                label: _fmtTanggal(o['tanggal_mulai']?.toString()),
              ),
              const SizedBox(width: 12),
              _quickInfoItem(
                icon: Icons.access_time,
                label: _fmtJam(o['jam_mulai']?.toString()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickInfoItem({required IconData icon, required String label}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: HCColor.lightTeal.withOpacity(0.5),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: HCColor.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabbedContent() {
    if (_tabController == null) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: HCColor.primary),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          TabBar(
            controller: _tabController!,
            labelColor: HCColor.primary,
            unselectedLabelColor: HCColor.textMuted,
            indicatorColor: HCColor.primary,
            isScrollable: true,
            tabs: const [
              Tab(text: 'Detail'),
              Tab(text: 'Lokasi'),
              Tab(text: 'Pembayaran'),
              Tab(text: 'Addons'), // ✅ Tab baru
              Tab(text: 'Foto'),
            ],
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController!,
              children: [
                _buildDetailTab(),
                _buildLokasiTab(),
                _buildPembayaranTab(),
                _buildAddonsTab(), // ✅ Tab baru
                _buildFotoTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailTab() {
    final o = _order!;
    final pasien = o['pasien'] as Map<String, dynamic>?;
    final koordinator = o['koordinator'] as Map<String, dynamic>?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoRow('Pasien', _getNama(pasien)),
        _infoRow('No HP Pasien', pasien?['no_hp']),
        _infoRow('Koordinator', _getNama(koordinator)),
        _infoRow('No HP Koordinator', koordinator?['no_hp']),
        const Divider(height: 24),
        _infoRow('Tipe Layanan', o['tipe_layanan']),
        _infoRow('Jumlah Visit', o['jumlah_visit_dipesan']),
        _infoRow('Durasi per Visit', '${o['durasi_menit_per_visit']} menit'),
        _infoRow('Quantity', o['qty']),
      ],
    );
  }

  Widget _buildLokasiTab() {
    final o = _order!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoRow('Alamat', o['alamat_lengkap']),
        _infoRow('Kecamatan', o['kecamatan']),
        _infoRow('Kota', o['kota']),
        if (o['catatan_pasien'] != null) ...[
          const Divider(height: 24),
          const Text(
            'Catatan Pasien:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HCColor.lightTeal.withOpacity(0.3),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              o['catatan_pasien'].toString(),
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPembayaranTab() {
    final o = _order!;
    final paymentInfo = o['payment_info'] as Map<String, dynamic>?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoRow('Harga Satuan', _fmtUang(o['harga_satuan'])),
        _infoRow('Subtotal', _fmtUang(o['subtotal'])),
        _infoRow('Diskon', _fmtUang(o['diskon'])),
        _infoRow('Biaya Tambahan', _fmtUang(o['biaya_tambahan'])),
        
        // ✅ Addons Total (jika ada)
        if (o['addons_total'] != null && o['addons_total'] != 0)
          _infoRow('Total Addons', _fmtUang(o['addons_total'])),
        
        const Divider(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Total Bayar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              _fmtUang(o['total_bayar']),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: HCColor.primary,
              ),
            ),
          ],
        ),
        const Divider(height: 24),
        _infoRow('Metode', o['metode_pembayaran']),
        _infoRow('Status', o['status_pembayaran']),
        if (paymentInfo != null) ...[
          _infoRow('Channel', paymentInfo['channel']),
          _infoRow('Dibayar pada', _fmtDateTime(o['dibayar_pada']?.toString())),
        ],
      ],
    );
  }

  // ✅ TAB ADDONS BARU
  Widget _buildAddonsTab() {
    final addons = _order?['order_addons'] as List?;

    if (addons == null || addons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_bag_outlined, size: 64, color: HCColor.textMuted),
            const SizedBox(height: 16),
            Text(
              'Tidak ada addon',
              style: TextStyle(
                fontSize: 14,
                color: HCColor.textMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: addons.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final addon = addons[index] as Map<String, dynamic>;
        final addonDetail = addon['addon'] as Map<String, dynamic>?;
        
        final namaAddon = addon['nama_addon']?.toString() ?? 
                         addonDetail?['nama_addon']?.toString() ?? 
                         '-';
        final hargaSatuan = addon['harga_satuan'];
        final qty = addon['qty'] ?? 1;
        final subtotal = addon['subtotal'];
        final deskripsi = addonDetail?['deskripsi']?.toString();

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: HCColor.lightTeal.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: HCColor.primary.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: HCColor.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_shopping_cart,
                      color: HCColor.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          namaAddon,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (deskripsi != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            deskripsi,
                            style: TextStyle(
                              fontSize: 12,
                              color: HCColor.textMuted,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),
              
              // Details
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Harga Satuan',
                        style: TextStyle(
                          fontSize: 12,
                          color: HCColor.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fmtUang(hargaSatuan),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        'Qty',
                        style: TextStyle(
                          fontSize: 12,
                          color: HCColor.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: HCColor.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'x$qty',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: HCColor.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Subtotal',
                        style: TextStyle(
                          fontSize: 12,
                          color: HCColor.textMuted,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _fmtUang(subtotal),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: HCColor.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFotoTab() {
    final o = _order!;
    final paymentInfo = o['payment_info'] as Map<String, dynamic>?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _fotoPreview('Kondisi Pasien', _mediaUrl(o['kondisi_pasien'])),
        _fotoPreview('Foto Hadir', _mediaUrl(o['foto_hadir'])),
        _fotoPreview('Foto Selesai', _mediaUrl(o['foto_selesai'])),
        _fotoPreview('Bukti Pembayaran', _mediaUrl(paymentInfo?['bukti_pembayaran'])),
      ],
    );
  }

  Widget _infoRow(String label, dynamic value) {
    final text = (value == null || value.toString().isEmpty) ? '-' : value.toString();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: HCColor.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(fontSize: 13)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _fotoPreview(String label, String? url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          if (url == null)
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: HCColor.lightTeal.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.image_not_supported, color: HCColor.textMuted),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada foto',
                      style: TextStyle(color: HCColor.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (ctx) => Dialog(
                    backgroundColor: Colors.transparent,
                    child: InteractiveViewer(
                      child: Image.network(url, fit: BoxFit.contain),
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  url,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    if (_isLoading || _order == null) return const SizedBox.shrink();

    final status = _order!['status_order']?.toString() ?? 'pending';
    final metodeBayar = _order!['metode_pembayaran']?.toString().toLowerCase() ?? '';
    final statusPembayaran = _order!['status_pembayaran']?.toString().toLowerCase() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: _getBottomBarContent(status, metodeBayar, statusPembayaran),
      ),
    );
  }

  Widget _getBottomBarContent(String status, String metodeBayar, String statusPembayaran) {
    switch (status) {
      case 'mendapatkan_perawat':
        return Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _onTolakOrder,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: HCColor.error),
                  foregroundColor: HCColor.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Tolak', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _onTerimaOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: HCColor.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Terima Order',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );

      case 'sedang_dalam_perjalanan':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_fotoHadir != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HCColor.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: HCColor.success, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Foto hadir sudah dipilih',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploadingSampai
                        ? null
                        : () async {
                            final picked = await _pickImage();
                            if (picked != null) {
                              setState(() => _fotoHadir = picked);
                            }
                          },
                    icon: const Icon(Icons.camera_alt, size: 20),
                    label: Text(_fotoHadir == null ? 'Ambil Foto' : 'Ganti Foto'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: HCColor.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: (_isUploadingSampai || _fotoHadir == null)
                        ? null
                        : _onSudahSampaiDiTempat,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HCColor.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isUploadingSampai
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Sudah Sampai',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        );

      case 'sampai_ditempat':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _onMulaiVisit,
            style: ElevatedButton.styleFrom(
              backgroundColor: HCColor.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Mulai Tindakan',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        );

      case 'sedang_berjalan':
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_fotoSelesai != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: HCColor.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: HCColor.success, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Foto dokumentasi sudah dipilih',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isUploadingSelesai
                        ? null
                        : () async {
                            final picked = await _pickImage();
                            if (picked != null) {
                              setState(() => _fotoSelesai = picked);
                            }
                          },
                    icon: const Icon(Icons.camera_alt, size: 20),
                    label: Text(_fotoSelesai == null ? 'Ambil Foto' : 'Ganti Foto'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: HCColor.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: (_isUploadingSelesai || _fotoSelesai == null)
                        ? null
                        : _onSelesaiTindakan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HCColor.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isUploadingSelesai
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Selesai',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        );

      case 'selesai':
        if (metodeBayar == 'cash' && statusPembayaran != 'lunas') {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_fotoBuktiPembayaran != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: HCColor.success.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: HCColor.success, size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Foto bukti pembayaran sudah dipilih',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isUploadingBuktiBayar
                          ? null
                          : () async {
                              final picked = await _pickImage();
                              if (picked != null) {
                                setState(() => _fotoBuktiPembayaran = picked);
                              }
                            },
                      icon: const Icon(Icons.receipt_long, size: 20),
                      label: Text(
                        _fotoBuktiPembayaran == null ? 'Ambil Bukti' : 'Ganti Bukti',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: HCColor.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed:
                          (_isUploadingBuktiBayar || _fotoBuktiPembayaran == null)
                              ? null
                              : _onUploadBuktiPembayaran,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HCColor.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isUploadingBuktiBayar
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Upload Bukti',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          );
        }
        return const SizedBox.shrink();

      default:
        return const SizedBox.shrink();
    }
  }
}
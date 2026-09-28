import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/perawat/orderan/services/perawat_orderan_service.dart';
import 'package:home_care/perawat/orderan/tabs/tabs.dart';

class DetailOrderanMasukPerawatPage extends StatefulWidget {
  final int orderId;

  const DetailOrderanMasukPerawatPage({super.key, required this.orderId});

  @override
  State<DetailOrderanMasukPerawatPage> createState() =>
      _DetailOrderanMasukPerawatPageState();
}

class _DetailOrderanMasukPerawatPageState
    extends State<DetailOrderanMasukPerawatPage>
    with SingleTickerProviderStateMixin {
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
    _tabController = TabController(length: 5, vsync: this);
    _fetchDetail();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _fetchDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final decoded = await PerawatOrderanService.fetchDetail(widget.orderId);

      if (!mounted) return;

      final success = decoded['success'] == true;

      if (!success) {
        setState(() {
          _isLoading = false;
          _error =
              decoded['message']?.toString() ?? 'Gagal memuat detail order.';
        });
        return;
      }

      setState(() {
        _order = decoded['data'] as Map<String, dynamic>?;
        _isLoading = false;
      });
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
      _showSnackBar(
        'Silakan ambil foto setelah tindakan terlebih dahulu.',
        isError: true,
      );
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
      _showSnackBar(
        'Silakan ambil foto bukti pembayaran terlebih dahulu.',
        isError: true,
      );
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

  Future<bool?> _showConfirmDialog({
    required String title,
    required String message,
    required String confirmText,
  }) {
    return showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
      builder:
          (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                      const SnackBar(
                        content: Text('Alasan tidak boleh kosong'),
                      ),
                    );
                    return;
                  }
                  Navigator.of(ctx).pop(text);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: HCColor.error,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
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
    setState(() => _isLoading = true);

    try {
      final decoded = await PerawatOrderanService.performAction(endpoint);

      if (!mounted) return;

      if (decoded['success'] == true) {
        setState(() {
          _order = decoded['data'] as Map<String, dynamic>?;
          _isLoading = false;
        });
        _showSnackBar(successMessage);
      } else {
        setState(() => _isLoading = false);
        _showSnackBar(
          decoded['message']?.toString() ?? 'Gagal memproses.',
          isError: true,
        );
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
    setState(() => _isLoading = true);

    try {
      final decoded = await PerawatOrderanService.performActionWithBody(
        endpoint,
        body,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (decoded['success'] == true) {
        _showSnackBar(successMessage);
        if (shouldPop) Navigator.of(context).pop(true);
      } else {
        _showSnackBar(
          decoded['message']?.toString() ?? 'Gagal memproses.',
          isError: true,
        );
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
    setUploadingFlag(true);

    try {
      final decoded = await PerawatOrderanService.uploadPhoto(
        endpoint: endpoint,
        fieldName: fieldName,
        photo: photo,
      );

      if (!mounted) return;

      setUploadingFlag(false);

      if (decoded['success'] == true) {
        setState(() {
          var data = decoded['data'];

          if (data is Map<String, dynamic>) {
            if (data.containsKey('order')) {
              _order = data['order'] as Map<String, dynamic>?;
            } else {
              _order = data;
            }
          }
        });

        _showSnackBar('Berhasil');

        await _fetchDetail();
      } else {
        _showSnackBar(
          decoded['message']?.toString() ?? 'Gagal mengunggah foto.',
          isError: true,
        );
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
          builder:
              (ctx) => SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(
                        Icons.camera_alt,
                        color: HCColor.primary,
                      ),
                      title: const Text('Kamera'),
                      onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.photo_library,
                        color: HCColor.primary,
                      ),
                      title: const Text('Galeri'),
                      onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
                    ),
                  ],
                ),
              ),
        );
      }

      if (source == null) return null;

      return await _picker.pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
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

  String _fmtTanggal(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      return DateFormat('dd MMM yyyy').format(DateTime.parse(iso));
    } catch (_) {
      return iso;
    }
  }

  String _fmtJam(String? jam) {
    if (jam == null || jam.isEmpty) return '-';
    return jam.length >= 5 ? jam.substring(0, 5) : jam;
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
            SliverFillRemaining(child: _buildError())
          else if (_order != null)
            SliverToBoxAdapter(child: _buildContent()),
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
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          kodeOrder,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
            color: _statusColor(status).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
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
            color: Colors.black.withValues(alpha: 0.05),
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
                child: const Icon(
                  Icons.medical_services,
                  color: HCColor.primary,
                  size: 28,
                ),
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
                      style: TextStyle(fontSize: 13, color: HCColor.textMuted),
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
          color: HCColor.lightTeal.withValues(alpha: 0.5),
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
            color: Colors.black.withValues(alpha: 0.05),
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
              Tab(text: 'Addons'),
              Tab(text: 'Foto'),
            ],
          ),
          SizedBox(
            height: 400,
            child: TabBarView(
              controller: _tabController!,
              children: [
                OrderTabDetail(order: _order!),
                OrderTabLokasi(order: _order!),
                OrderTabPembayaran(order: _order!),
                OrderTabAddons(order: _order!),
                OrderTabFoto(order: _order!),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBottomBar() {
    if (_isLoading || _order == null) return const SizedBox.shrink();

    final status = _order!['status_order']?.toString() ?? 'pending';
    final metodeBayar =
        _order!['metode_pembayaran']?.toString().toLowerCase() ?? '';
    final statusPembayaran =
        _order!['status_pembayaran']?.toString().toLowerCase() ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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

  Widget _getBottomBarContent(
    String status,
    String metodeBayar,
    String statusPembayaran,
  ) {
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Tolak',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                  color: HCColor.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: HCColor.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Foto hadir sudah dipilih',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _isUploadingSampai
                            ? null
                            : () async {
                              final picked = await _pickImage();
                              if (picked != null) {
                                setState(() => _fotoHadir = picked);
                              }
                            },
                    icon: const Icon(Icons.camera_alt, size: 20),
                    label: Text(
                      _fotoHadir == null ? 'Ambil Foto' : 'Ganti Foto',
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
                        (_isUploadingSampai || _fotoHadir == null)
                            ? null
                            : _onSudahSampaiDiTempat,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HCColor.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isUploadingSampai
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

      case 'sampai_ditempat':
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _onMulaiVisit,
            style: ElevatedButton.styleFrom(
              backgroundColor: HCColor.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
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
                  color: HCColor.success.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: HCColor.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Foto dokumentasi sudah dipilih',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed:
                        _isUploadingSelesai
                            ? null
                            : () async {
                              final picked = await _pickImage();
                              if (picked != null) {
                                setState(() => _fotoSelesai = picked);
                              }
                            },
                    icon: const Icon(Icons.camera_alt, size: 20),
                    label: Text(
                      _fotoSelesai == null ? 'Ambil Foto' : 'Ganti Foto',
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
                        (_isUploadingSelesai || _fotoSelesai == null)
                            ? null
                            : _onSelesaiTindakan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HCColor.success,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child:
                        _isUploadingSelesai
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
                    color: HCColor.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: HCColor.success,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Foto bukti pembayaran sudah dipilih',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed:
                          _isUploadingBuktiBayar
                              ? null
                              : () async {
                                final picked = await _pickImage();
                                if (picked != null) {
                                  setState(() => _fotoBuktiPembayaran = picked);
                                }
                              },
                      icon: const Icon(Icons.receipt_long, size: 20),
                      label: Text(
                        _fotoBuktiPembayaran == null
                            ? 'Ambil Bukti'
                            : 'Ganti Bukti',
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
                          (_isUploadingBuktiBayar ||
                                  _fotoBuktiPembayaran == null)
                              ? null
                              : _onUploadBuktiPembayaran,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: HCColor.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child:
                          _isUploadingBuktiBayar
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

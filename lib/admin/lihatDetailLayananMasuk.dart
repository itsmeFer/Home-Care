import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const error = Color(0xFFEF4444);
}

class DetailOrderLayananAdminPage extends StatefulWidget {
  final int orderId;

  const DetailOrderLayananAdminPage({Key? key, required this.orderId})
    : super(key: key);

  @override
  State<DetailOrderLayananAdminPage> createState() =>
      _DetailOrderLayananAdminPageState();
}

class _DetailOrderLayananAdminPageState
    extends State<DetailOrderLayananAdminPage>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  String? _error;

  Map<String, dynamic>? _order;

  // ====== bagian KOORDINATOR ======
  bool _isLoadingKoordinator = false;
  bool _isAssigningKoordinator = false;
  List<Map<String, dynamic>> _koordinators = [];
  int? _selectedKoordinatorId;

  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this); // ✅ Dari 5 jadi 6
    _initialLoad();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _initialLoad() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await Future.wait([
        _fetchDetail(internalCall: true),
        _fetchKoordinators(internalCall: true),
      ]);

      // setelah dua-duanya dapat, set selected koordinator dari data order
      final koorId = _order?['koordinator_id'];
      if (koorId != null && koorId is int) {
        _selectedKoordinatorId = koorId;
      } else if (koorId != null) {
        _selectedKoordinatorId = int.tryParse(koorId.toString());
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Terjadi kesalahan saat memuat data: $e';
      });
    }
  }

  String? _mediaUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    var cleanPath = path.startsWith('/') ? path.substring(1) : path;
    return '$kBaseUrl/media/$cleanPath';
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
        _fotoPreview(
          'Bukti Pembayaran',
          _mediaUrl(paymentInfo?['bukti_pembayaran']),
        ),
      ],
    );
  }

  Widget _fotoPreview(String label, String? url) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.image, size: 16, color: HCColor.primary),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (url == null)
            Container(
              height: 150,
              decoration: BoxDecoration(
                color: HCColor.lightTeal.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: HCColor.primary.withOpacity(0.2)),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.image_not_supported,
                      color: HCColor.textMuted,
                      size: 48,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Belum ada foto',
                      style: TextStyle(color: HCColor.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () {
                // ✅ FULLSCREEN MODAL
                showDialog(
                  context: context,
                  builder: (ctx) => Dialog(
                    backgroundColor: Colors.transparent,
                    insetPadding: const EdgeInsets.all(16),
                    child: Stack(
                      children: [
                        // Background dismiss
                        GestureDetector(
                          onTap: () => Navigator.pop(ctx),
                          child: Container(
                            color: Colors.black.withOpacity(0.8),
                          ),
                        ),
                        // Image viewer
                        Center(
                          child: InteractiveViewer(
                            minScale: 0.5,
                            maxScale: 4.0,
                            child: Image.network(
                              url,
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        value:
                                            loadingProgress
                                                    .expectedTotalBytes !=
                                                null
                                            ? loadingProgress
                                                      .cumulativeBytesLoaded /
                                                  loadingProgress
                                                      .expectedTotalBytes!
                                            : null,
                                      ),
                                    );
                                  },
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        size: 48,
                                        color: HCColor.error,
                                      ),
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Gagal memuat gambar',
                                        style: TextStyle(fontSize: 14),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        // Close button
                        Positioned(
                          top: 40,
                          right: 16,
                          child: IconButton(
                            icon: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    Image.network(
                      url,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: HCColor.lightTeal.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: CircularProgressIndicator(
                              color: HCColor.primary,
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          decoration: BoxDecoration(
                            color: HCColor.error.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: HCColor.error.withOpacity(0.3),
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: HCColor.error,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Gagal memuat gambar',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                    // Overlay indicator untuk zoom
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.zoom_in, color: Colors.white, size: 14),
                            SizedBox(width: 4),
                            Text(
                              'Tap untuk perbesar',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _fetchDetail({bool internalCall = false}) async {
    if (!internalCall) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    final token = await _getToken();
    if (token == null) {
      setState(() {
        _isLoading = false;
        _error = 'Token tidak ditemukan. Silakan login sebagai admin.';
      });
      return;
    }

    try {
      final uri = Uri.parse('$kBaseUrl/admin/order-layanan/${widget.orderId}');

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
            _error =
                decoded['message']?.toString() ?? 'Gagal memuat detail order.';
          });
          return;
        }

        setState(() {
          _order = decoded['data'] as Map<String, dynamic>;
        });

        // ✅ Debug print
        print('📦 Order Addons: ${_order?['order_addons']}');
      } else if (response.statusCode == 404) {
        setState(() {
          _isLoading = false;
          _error = 'Order tidak ditemukan (404).';
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
          _error = 'Sesi login admin berakhir. Silakan login ulang.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _error =
              'Gagal memuat detail. Kode: ${response.statusCode} ${response.reasonPhrase}';
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

  Future<void> _fetchKoordinators({bool internalCall = false}) async {
    if (!internalCall) {
      setState(() {
        _isLoadingKoordinator = true;
      });
    }

    final token = await _getToken();
    if (token == null) {
      setState(() {
        _isLoadingKoordinator = false;
      });
      return;
    }

    try {
      final uri = Uri.parse('$kBaseUrl/admin/koordinator-list');

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
            _isLoadingKoordinator = false;
          });
          return;
        }

        final List<dynamic> data = decoded['data'] ?? [];

        final list = data.map<Map<String, dynamic>>((e) {
          final m = (e as Map).map((k, v) => MapEntry(k.toString(), v));
          return m;
        }).toList();

        setState(() {
          _koordinators = list;
          _isLoadingKoordinator = false;
        });
      } else {
        setState(() {
          _isLoadingKoordinator = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoadingKoordinator = false;
      });
    }
  }

  Future<void> _assignKoordinator() async {
    if (_selectedKoordinatorId == null) {
      _showSnackBar(
        'Silakan pilih koordinator terlebih dahulu.',
        isError: true,
      );
      return;
    }

    setState(() {
      _isAssigningKoordinator = true;
    });

    final token = await _getToken();
    if (token == null) {
      setState(() {
        _isAssigningKoordinator = false;
      });
      _showSnackBar(
        'Token tidak ditemukan. Silakan login ulang.',
        isError: true,
      );
      return;
    }

    try {
      final uri = Uri.parse(
        '$kBaseUrl/admin/order-layanan/${widget.orderId}/assign-koordinator',
      );

      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {'koordinator_id': _selectedKoordinatorId!.toString()},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        final success = decoded['success'] == true;

        if (success) {
          setState(() {
            _order = decoded['data'] as Map<String, dynamic>;
          });

          _showSnackBar('Koordinator berhasil ditugaskan.');
          Navigator.pop(context, true);
          return;
        } else {
          _showSnackBar(
            decoded['message']?.toString() ??
                'Gagal menyimpan penugasan koordinator.',
            isError: true,
          );
        }
      } else if (response.statusCode == 422) {
        final decoded = json.decode(response.body) as Map<String, dynamic>;
        _showSnackBar(
          decoded['message']?.toString() ?? 'Validasi gagal (422).',
          isError: true,
        );
      } else {
        _showSnackBar(
          'Gagal menyimpan penugasan. Kode: ${response.statusCode} ${response.reasonPhrase}',
          isError: true,
        );
      }
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Terjadi kesalahan: $e', isError: true);
    } finally {
      if (mounted) {
        setState(() {
          _isAssigningKoordinator = false;
        });
      }
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
      final date = DateTime.parse(iso);
      return DateFormat('dd MMM yyyy').format(date);
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
    if (jam.length >= 5) return jam.substring(0, 5);
    return jam;
  }

  String _fmtUang(dynamic val) {
    if (val == null) return 'Rp 0';
    double d;
    if (val is num) {
      d = val.toDouble();
    } else {
      d = double.tryParse(val.toString()) ?? 0;
    }
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(d);
  }

  String _getNama(Map<String, dynamic>? obj) {
    if (obj == null) return '-';
    return obj['nama']?.toString() ??
        obj['nama_lengkap']?.toString() ??
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
              onPressed: _initialLoad,
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
      onRefresh: _initialLoad,
      color: HCColor.primary,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildQuickInfo(),
            const SizedBox(height: 16),
            _buildTabbedContent(),
            const SizedBox(height: 16),
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
              Tab(text: 'Addons'),
              Tab(text: 'Koordinator'),
              Tab(text: 'Foto'), // ✅ TAB BARU
            ],
          ),
          SizedBox(
            height: 450,
            child: TabBarView(
              controller: _tabController!,
              children: [
                _buildDetailTab(),
                _buildLokasiTab(),
                _buildPembayaranTab(),
                _buildAddonsTab(),
                _buildKoordinatorTab(),
                _buildFotoTab(), // ✅ TAB BARU
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
    final perawat = o['perawat'] as Map<String, dynamic>?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoRow('Pasien', _getNama(pasien)),
        _infoRow('No RM', pasien?['no_rekam_medis']),
        _infoRow('No HP Pasien', pasien?['no_hp']),
        _infoRow('Email Pasien', pasien?['email']),
        const Divider(height: 24),
        _infoRow('Perawat', _getNama(perawat)),
        _infoRow('ID Perawat', perawat?['id']),
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
        _infoRow('Latitude', o['latitude']),
        _infoRow('Longitude', o['longitude']),
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

  Widget _buildAddonsTab() {
    final addons = _order?['order_addons'] as List?;

    if (addons == null || addons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 64,
              color: HCColor.textMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'Tidak ada addon',
              style: TextStyle(fontSize: 14, color: HCColor.textMuted),
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

        final namaAddon =
            addon['nama_addon']?.toString() ??
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

  Widget _buildKoordinatorTab() {
    final koordinator = _order?['koordinator'] as Map<String, dynamic>?;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _infoRow('Nama Koordinator', _getNama(koordinator)),
        _infoRow('ID Koordinator', koordinator?['id']),
        _infoRow('Wilayah', koordinator?['wilayah']),
        _infoRow('No HP', koordinator?['no_hp']),
        const SizedBox(height: 24),
        _buildKoordinatorAssignSection(),
      ],
    );
  }

  Widget _buildKoordinatorAssignSection() {
    if (_isLoadingKoordinator) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(color: HCColor.primary),
        ),
      );
    }

    if (_koordinators.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: HCColor.error.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: HCColor.error, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Belum ada data koordinator aktif.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    // ✅ CEK STATUS ORDER
    final status = _order?['status_order']?.toString() ?? '';
    final isOrderFinished = status == 'selesai' || status == 'dibatalkan';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOrderFinished
            ? Colors.grey.withOpacity(0.1)
            : HCColor.lightTeal.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOrderFinished
              ? Colors.grey.withOpacity(0.3)
              : HCColor.primary.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_ind,
                color: isOrderFinished ? Colors.grey : HCColor.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Ubah / Pilih Koordinator',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),

          // ✅ PERINGATAN JIKA ORDER SUDAH SELESAI
          if (isOrderFinished) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HCColor.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: HCColor.warning.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.lock, color: HCColor.warning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status == 'selesai'
                          ? 'Order sudah selesai. Tidak dapat mengubah penugasan.'
                          : 'Order dibatalkan. Tidak dapat mengubah penugasan.',
                      style: TextStyle(
                        fontSize: 12,
                        color: HCColor.warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12),

          // ✅ DROPDOWN DISABLED JIKA SELESAI
          DropdownButtonFormField<int>(
            value: _selectedKoordinatorId,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: isOrderFinished ? Colors.grey[200] : Colors.white,
              isDense: true,
            ),
            items: _koordinators.map((k) {
              final rawId = k['id'];
              final intId = (rawId is int)
                  ? rawId
                  : int.tryParse(rawId.toString()) ?? 0;

              final nama =
                  k['nama_lengkap']?.toString() ?? k['nama']?.toString() ?? '-';
              final wilayah = k['wilayah']?.toString();

              return DropdownMenuItem<int>(
                value: intId,
                child: Text(
                  (wilayah == null || wilayah.isEmpty)
                      ? nama
                      : '$nama - ($wilayah)',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: isOrderFinished
                ? null // ✅ DISABLE DROPDOWN
                : (val) {
                    setState(() {
                      _selectedKoordinatorId = val;
                    });
                  },
          ),

          const SizedBox(height: 12),

          // ✅ BUTTON DISABLED JIKA SELESAI
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (isOrderFinished || _isAssigningKoordinator)
                  ? null // ✅ DISABLE BUTTON
                  : _assignKoordinator,
              icon: _isAssigningKoordinator
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      isOrderFinished ? Icons.lock : Icons.assignment_turned_in,
                      size: 18,
                    ),
              label: Text(
                _isAssigningKoordinator
                    ? 'Menyimpan...'
                    : isOrderFinished
                    ? 'Tidak Dapat Diubah'
                    : 'Simpan Penugasan',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isOrderFinished
                    ? Colors.grey
                    : HCColor.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, dynamic value) {
    final text = (value == null || value.toString().isEmpty)
        ? '-'
        : value.toString();

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
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

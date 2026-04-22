import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:home_care/users/payment_method_page.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kBaseUrl = 'http://192.168.1.5:8000/api';

// ===== COLOR SCHEME =====
class HCColors {
  static const primary = Color(0xFF0BA5A7);
  static const primaryDark = Color(0xFF088088);
  static const accent = Color(0xFF6C63FF);
  static const bg = Color(0xFFF5F7FA);
  static const card = Colors.white;
  static const textDark = Color(0xFF2D3436);
  static const textMuted = Color(0xFF636E72);
  static const success = Color(0xFF00B894);
  static const warning = Color(0xFFFDAA2E);
  static const danger = Color(0xFFFF6B6B);
  static const pending = Color(0xFFFF9F43);
}

class LihatDetailDraftPemesananPage extends StatefulWidget {
  final int draftId;

  const LihatDetailDraftPemesananPage({Key? key, required this.draftId})
    : super(key: key);

  @override
  State<LihatDetailDraftPemesananPage> createState() =>
      _LihatDetailDraftPemesananPageState();
}

class _LihatDetailDraftPemesananPageState
    extends State<LihatDetailDraftPemesananPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _draft;

  @override
  void initState() {
    super.initState();
    _fetchDraftDetail();
  }

  Future<void> _fetchDraftDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null || token.isEmpty) {
        setState(() {
          _isLoading = false;
          _error = 'Token tidak ditemukan. Silakan login ulang.';
        });
        return;
      }

      final uri = Uri.parse('$kBaseUrl/pasien/order-draft/${widget.draftId}');

      debugPrint('🔵 Fetching draft detail: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('🔵 Response status: ${response.statusCode}');
      debugPrint('🔵 Response body: ${response.body}');

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        if (jsonBody is Map && jsonBody['success'] == true) {
          final data = (jsonBody['data'] ?? {}) as Map<String, dynamic>;

          setState(() {
            _draft = data;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error =
                jsonBody['message']?.toString() ??
                'Gagal mengambil detail draft.';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 404) {
        setState(() {
          _error = 'Draft tidak ditemukan.';
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _error = 'Sesi login berakhir. Silakan login ulang.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Gagal mengambil detail draft. Kode: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error fetching draft: $e');
      if (!mounted) return;
      setState(() {
        _error = 'Terjadi kesalahan: $e';
        _isLoading = false;
      });
    }
  }

  String _formatTanggal(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final d = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy', 'id_ID').format(d);
    } catch (_) {
      return raw;
    }
  }

  String _formatJam(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      if (raw.length == 5) return raw;
      final t = DateFormat('HH:mm:ss').parse(raw);
      return DateFormat('HH:mm').format(t);
    } catch (_) {
      return raw;
    }
  }

  String _formatRupiah(num? n) {
    if (n == null) return 'Rp 0';
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(n);
  }

  num _getAddonsTotal() {
    final backendTotal =
        num.tryParse(_draft?['addons_total']?.toString() ?? '0') ?? 0;

    if (backendTotal > 0) return backendTotal;

    final addons = _getDraftAddons();
    num calculatedTotal = 0;

    for (final addon in addons) {
      final subtotal = num.tryParse(addon['subtotal']?.toString() ?? '0') ?? 0;
      calculatedTotal += subtotal;
    }

    return calculatedTotal;
  }

  List<Map<String, dynamic>> _getDraftAddons() {
    final raw = _draft?['addons'];

    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }

    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColors.bg,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: HCColors.primary),
            )
          : _error != null
          ? _buildErrorState()
          : _draft == null
          ? const Center(child: Text('Data draft tidak ditemukan.'))
          : _buildContent(),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: HCColors.danger.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: HCColors.textMuted),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchDraftDetail,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HCColors.primary,
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

  Widget _buildContent() {
    final status = _draft!['status']?.toString() ?? 'menunggu_pembayaran';
    final totalBayar =
        num.tryParse(_draft!['total_bayar']?.toString() ?? '0') ?? 0;

    String? gambarLayanan;
    if (_draft!['layanan'] != null && _draft!['layanan'] is Map) {
      gambarLayanan = _draft!['layanan']['gambar_url']?.toString();
    }

    return Scaffold(
      backgroundColor: HCColors.bg,
      body: RefreshIndicator(
        onRefresh: _fetchDraftDetail,
        color: HCColors.primary,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 280,
              pinned: true,
              backgroundColor: HCColors.warning,
              elevation: 0,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(
                      Icons.arrow_back_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (gambarLayanan != null && gambarLayanan.isNotEmpty)
                        Image.network(
                          gambarLayanan,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [HCColors.warning, HCColors.pending],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.medical_services_rounded,
                                size: 64,
                                color: Colors.white54,
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [HCColors.warning, HCColors.pending],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.medical_services_rounded,
                              size: 64,
                              color: Colors.white54,
                            ),
                          ),
                        ),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.88),
                              Colors.black.withOpacity(0.35),
                              Colors.transparent,
                            ],
                            stops: const [0.0, 0.35, 0.85],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                title: Text(
                  _draft!['draft_code']?.toString() ?? 'DRAFT',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        color: Colors.black45,
                        offset: Offset(0, 1),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                ),
                centerTitle: true,
                titlePadding: const EdgeInsets.only(bottom: 16),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildStatusCard(status),
                  const SizedBox(height: 16),
                  _buildLayananCard(),
                  const SizedBox(height: 16),
                  _buildAddonsCard(),
                  const SizedBox(height: 16),
                  _buildJadwalLokasiCard(),
                  const SizedBox(height: 16),
                  if ((_draft!['catatan_pasien']?.toString() ?? '').isNotEmpty)
                    _buildCatatanCard(),
                  const SizedBox(height: 16),
                  _buildPembayaranCard(),
                  const SizedBox(height: 100), // ✅ Space untuk bottom button
                ]),
              ),
            ),
          ],
        ),
      ),
      // ✅ BOTTOM BUTTON DI SINI
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PaymentMethodPage(
                    draftId: widget.draftId,
                    totalBayar: totalBayar.toInt(),
                  ),
                ),
              );

              if (result == true && mounted) {
                Navigator.pop(context, true);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: HCColors.warning,
              padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.payment, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Bayar Sekarang - ${_formatRupiah(totalBayar)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusCard(String status) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HCColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: HCColors.warning.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.hourglass_empty_rounded,
              color: HCColors.warning,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Menunggu Pembayaran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: HCColors.warning,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Selesaikan pembayaran untuk memproses pesanan',
                  style: TextStyle(fontSize: 13, color: HCColors.textMuted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLayananCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HCColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.medical_services_rounded,
                color: HCColors.primary,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Layanan',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HCColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _draft!['nama_layanan']?.toString() ?? '-',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: HCColors.textDark,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildInfoChip(
                'Tipe: ${_draft!['tipe_layanan'] ?? '-'}',
                Icons.inventory_2_rounded,
              ),
              _buildInfoChip(
                'Durasi: ${_draft!['durasi_menit'] ?? '-'} menit',
                Icons.timer_rounded,
              ),
              _buildInfoChip(
                'Qty: ${_draft!['qty'] ?? 1}',
                Icons.shopping_cart_rounded,
              ),
              _buildInfoChip(
                'Visit: ${_draft!['jumlah_visit'] ?? '-'}x',
                Icons.repeat_rounded,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddonsCard() {
    final addons = _getDraftAddons();

    if (addons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HCColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.add_box_rounded, color: HCColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Add-ons',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HCColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(addons.length, (index) {
            final addon = addons[index];
            final namaAddon = addon['nama_addon']?.toString() ?? '-';
            final qty = int.tryParse(addon['qty']?.toString() ?? '0') ?? 0;
            final hargaSatuan =
                num.tryParse(addon['harga_satuan']?.toString() ?? '0') ?? 0;
            final subtotal =
                num.tryParse(addon['subtotal']?.toString() ?? '0') ?? 0;

            return Container(
              margin: EdgeInsets.only(
                bottom: index == addons.length - 1 ? 0 : 12,
              ),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: HCColors.bg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: HCColors.primary.withOpacity(0.08)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    namaAddon,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: HCColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Qty',
                        style: TextStyle(
                          fontSize: 12,
                          color: HCColors.textMuted,
                        ),
                      ),
                      Text(
                        '$qty',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: HCColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Harga satuan',
                        style: TextStyle(
                          fontSize: 12,
                          color: HCColors.textMuted,
                        ),
                      ),
                      Text(
                        _formatRupiah(hargaSatuan),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: HCColors.textDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Subtotal',
                        style: TextStyle(
                          fontSize: 12,
                          color: HCColors.textMuted,
                        ),
                      ),
                      Text(
                        _formatRupiah(subtotal),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: HCColors.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: HCColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: HCColors.primary),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: HCColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJadwalLokasiCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HCColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.schedule_rounded, color: HCColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Jadwal & Lokasi',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HCColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            Icons.today_outlined,
            'Tanggal',
            _formatTanggal(_draft!['tanggal_mulai']?.toString()),
          ),
          const SizedBox(height: 12),
          _buildDetailRow(
            Icons.access_time_rounded,
            'Jam',
            _formatJam(_draft!['jam_mulai']?.toString()),
          ),
          const Divider(height: 24),
          _buildDetailRow(
            Icons.location_on_rounded,
            'Alamat',
            _draft!['alamat_lengkap']?.toString() ?? '-',
          ),
          const SizedBox(height: 8),
          Text(
            [_draft!['kecamatan'], _draft!['kota']]
                .where((e) => e != null && e.toString().isNotEmpty)
                .join(', ')
                .toString(),
            style: const TextStyle(fontSize: 13, color: HCColors.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildCatatanCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HCColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.note_rounded, color: HCColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Catatan Pasien',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HCColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _draft!['catatan_pasien'].toString(),
            style: const TextStyle(
              fontSize: 14,
              color: HCColors.textMuted,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPembayaranCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: HCColors.card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.payments_rounded, color: HCColors.primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Rincian Pembayaran',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: HCColors.textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildPaymentRow(
            'Harga satuan',
            _formatRupiah(
              num.tryParse(_draft!['harga_satuan']?.toString() ?? '0'),
            ),
          ),
          _buildPaymentRow('Qty', '${_draft!['qty'] ?? 1}'),
          const Divider(height: 20),
          _buildPaymentRow(
            'Subtotal',
            _formatRupiah(num.tryParse(_draft!['subtotal']?.toString() ?? '0')),
          ),
          _buildPaymentRow(
            'Diskon',
            _formatRupiah(num.tryParse(_draft!['diskon']?.toString() ?? '0')),
            isDiscount: true,
          ),
          _buildPaymentRow('Add-ons', _formatRupiah(_getAddonsTotal())),
          const Divider(height: 20),
          _buildPaymentRow(
            'Total Bayar',
            _formatRupiah(
              num.tryParse(_draft!['total_bayar']?.toString() ?? '0'),
            ),
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRow(
    String label,
    String value, {
    bool isDiscount = false,
    bool isTotal = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 15 : 13,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: HCColors.textMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 17 : 14,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              color: isDiscount
                  ? HCColors.danger
                  : isTotal
                  ? HCColors.primary
                  : HCColors.textDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: HCColors.textMuted.withOpacity(0.7)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: HCColors.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: HCColors.textDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

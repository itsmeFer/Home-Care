import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:home_care/users/layananPage.dart'; // untuk kBaseUrl (sesuaikan kalau beda)
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LihatDetailHistoriPemesananPage extends StatefulWidget {
  final int orderId;

  const LihatDetailHistoriPemesananPage({Key? key, required this.orderId})
    : super(key: key);

  @override
  State<LihatDetailHistoriPemesananPage> createState() =>
      _LihatDetailHistoriPemesananPageState();
}

class _LihatDetailHistoriPemesananPageState
    extends State<LihatDetailHistoriPemesananPage> {
  bool _isLoading = true;
  String? _error;
  Map<String, dynamic>? _order;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
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

      // endpoint histori detail, sesuaikan dengan API kamu
      final uri = Uri.parse('$kBaseUrl/pasien/order-layanan/${widget.orderId}');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final jsonBody = json.decode(response.body);
        if (jsonBody is Map && jsonBody['success'] == true) {
          final data = (jsonBody['data'] ?? {}) as Map<String, dynamic>;
          print('DEBUG kondisi_pasien: ${data['kondisi_pasien']}');
          print('DEBUG foto_hadir   : ${data['foto_hadir']}');
          print('DEBUG foto_selesai : ${data['foto_selesai']}');

          setState(() {
            _order = data;
            _isLoading = false;
          });
        } else {
          setState(() {
            _error =
                jsonBody['message']?.toString() ??
                'Gagal mengambil detail order.';
            _isLoading = false;
          });
        }
      } else if (response.statusCode == 401) {
        setState(() {
          _error = 'Sesi login berakhir. Silakan login ulang.';
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Gagal mengambil detail order. Kode: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
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
      // kalau backend kirim "HH:mm:ss" atau "HH:mm"
      if (raw.length == 5) {
        return raw; // sudah HH:mm
      }
      final t = DateFormat('HH:mm:ss').parse(raw);
      return DateFormat('HH:mm').format(t);
    } catch (_) {
      return raw;
    }
  }

  String _formatDateTime(String? raw) {
    if (raw == null || raw.isEmpty) return '-';
    try {
      final d = DateTime.parse(raw);
      return DateFormat('dd MMM yyyy HH:mm', 'id_ID').format(d);
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

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'menunggu_penugasan':
      case 'mendapatkan_perawat':
        return Colors.deepOrange;
      case 'sedang_dalam_perjalanan':
        return Colors.blueAccent;
      case 'sampai_ditempat':
        return Colors.indigo;
      case 'mendapatkan_perawat':
        return Colors.teal;
      case 'selesai':
        return Colors.green;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu verifikasi';
      case 'menunggu_penugasan':
        return 'Menunggu penugasan perawat';
      case 'mendapatkan_perawat':
        return 'Perawat sudah ditentukan';
      case 'sedang_dalam_perjalanan':
        return 'Perawat dalam perjalanan';
      case 'sampai_ditempat':
        return 'Perawat sudah di lokasi';
      case 'mendapatkan_perawat':
        return 'Perawatan sedang berjalan';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String? _resolveImageUrl(String? raw) {
    if (raw == null || raw.isEmpty) return null;

    // Kalau suatu saat backend kirim full URL (http/https), langsung pakai
    if (raw.startsWith('http')) return raw;

    // Sekarang backend kirim path relatif: "kondisi_pasien/xxx.png"
    // Karena kBaseUrl = http://192.168.1.6:8000/api
    // dan route kamu ada di /api/media/{path}
    return '$kBaseUrl/media/$raw'; // -> http://192.168.1.6:8000/api/media/kondisi_pasien/xxx.png
  }

  Widget _buildImageSection(String title, String? rawPath) {
    final url = _resolveImageUrl(rawPath);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 8),
            if (url == null)
              const Text(
                'Belum ada foto.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Image.network(
                    url,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[200],
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Pemesanan')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(_error!, textAlign: TextAlign.center),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _fetchDetail,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ),
            )
          : _order == null
          ? const Center(child: Text('Data order tidak ditemukan.'))
          : RefreshIndicator(
              onRefresh: _fetchDetail,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    // ===== HEADER ORDER & STATUS =====
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _order!['kode_order']?.toString() ?? '-',
                                    style: theme.textTheme.titleMedium!
                                        .copyWith(fontWeight: FontWeight.w700),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _statusColor(
                                      _order!['status_order']?.toString() ?? '',
                                    ).withOpacity(.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _statusLabel(
                                      _order!['status_order']?.toString() ?? '',
                                    ),
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: _statusColor(
                                        _order!['status_order']?.toString() ??
                                            '',
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Dibuat pada: ${_formatDateTime(_order!['created_at']?.toString())}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    // ===== INFO LAYANAN =====
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Layanan',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _order!['nama_layanan']?.toString() ?? '-',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Tipe: ${_order!['tipe_layanan'] ?? '-'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Durasi: ${_order!['durasi_menit_per_visit'] ?? '-'} menit/visit',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Text(
                                  'Qty: ${_order!['qty'] ?? 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Text(
                                  'Total visit dipesan: ${_order!['jumlah_visit_dipesan'] ?? '-'}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    // ===== JADWAL & LOKASI =====
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Jadwal & Lokasi',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.calendar_today, size: 16),
                                const SizedBox(width: 6),
                                Text(
                                  _formatTanggal(
                                    _order!['tanggal_mulai']?.toString(),
                                  ),
                                  style: const TextStyle(fontSize: 13),
                                ),
                                const SizedBox(width: 12),
                                const Icon(Icons.access_time, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  _formatJam(_order!['jam_mulai']?.toString()),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 18,
                                  color: Colors.redAccent,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _order!['alamat_lengkap']?.toString() ??
                                        '-',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [_order!['kecamatan'], _order!['kota']]
                                  .where(
                                    (e) => e != null && e.toString().isNotEmpty,
                                  )
                                  .join(', ')
                                  .toString(),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 4),
                            if ((_order!['latitude']?.toString() ?? '')
                                    .isNotEmpty ||
                                (_order!['longitude']?.toString() ?? '')
                                    .isNotEmpty)
                              Text(
                                'Koordinat: ${_order!['latitude'] ?? '-'}, ${_order!['longitude'] ?? '-'}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    // ===== PETUGAS (KOORDINATOR & PERAWAT) =====
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Petugas',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.supervisor_account, size: 18),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    // sesuaikan key kalau API kamu pakai nested (misal: order['koordinator']['nama_lengkap'])
                                    _order!['koordinator_nama']?.toString() ??
                                        _order!['koordinator_name']
                                            ?.toString() ??
                                        '-',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.medical_services, size: 18),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    _order!['perawat_nama']?.toString() ??
                                        _order!['perawat_name']?.toString() ??
                                        '-',
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    // ===== CATATAN PASIEN =====
                    if ((_order!['catatan_pasien']?.toString() ?? '')
                        .isNotEmpty)
                      Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Catatan dari Pasien',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _order!['catatan_pasien'].toString(),
                                style: const TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 8),
                    // ===== PEMBAYARAN =====
                    Card(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Pembayaran',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Harga satuan'),
                                Text(
                                  _formatRupiah(
                                    num.tryParse(
                                      _order!['harga_satuan']?.toString() ??
                                          '0',
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Qty'),
                                Text(
                                  '${_order!['qty'] ?? 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Subtotal'),
                                Text(
                                  _formatRupiah(
                                    num.tryParse(
                                      _order!['subtotal']?.toString() ?? '0',
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Diskon'),
                                Text(
                                  _formatRupiah(
                                    num.tryParse(
                                      _order!['diskon']?.toString() ?? '0',
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.red,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Biaya tambahan'),
                                Text(
                                  _formatRupiah(
                                    num.tryParse(
                                      _order!['biaya_tambahan']?.toString() ??
                                          '0',
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total bayar',
                                  style: TextStyle(fontWeight: FontWeight.w700),
                                ),
                                Text(
                                  _formatRupiah(
                                    num.tryParse(
                                      _order!['total_bayar']?.toString() ?? '0',
                                    ),
                                  ),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Chip(
                                  label: Text(
                                    'Metode: ${_order!['metode_pembayaran'] ?? '-'}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Chip(
                                  label: Text(
                                    'Status: ${_order!['status_pembayaran'] ?? '-'}',
                                    style: const TextStyle(fontSize: 11),
                                  ),
                                ),
                              ],
                            ),
                            if ((_order!['dibayar_pada']?.toString() ?? '')
                                    .isNotEmpty ==
                                true)
                              Text(
                                'Dibayar pada: ${_formatDateTime(_order!['dibayar_pada']?.toString())}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 8),
                    // ===== FOTO-FOTO =====
                    _buildImageSection(
                      'Kondisi pasien sebelum perawat datang',
                      _order!['kondisi_pasien']?.toString(),
                    ),
                    _buildImageSection(
                      'Bukti foto hadir di lokasi',
                      _order!['foto_hadir']?.toString(),
                    ),
                    _buildImageSection(
                      'Foto setelah tindakan selesai',
                      _order!['foto_selesai']?.toString(),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
    );
  }
}

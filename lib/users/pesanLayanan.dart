import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:home_care/chat.dart' show ChatRoomPage;
import 'package:home_care/users/layananPage.dart' show Layanan, kBaseUrl;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PesanLayananPage extends StatefulWidget {
  final Layanan layanan;
  // ❌ koordinatorId dihapus, backend yang pilih random & reuse

  const PesanLayananPage({
    Key? key,
    required this.layanan,
  }) : super(key: key);

  @override
  State<PesanLayananPage> createState() => _PesanLayananPageState();
}

class _PesanLayananPageState extends State<PesanLayananPage> {
  bool _isSubmitting = false;

  Future<void> _goToChatFirst() async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sesi login berakhir, silakan login ulang.'),
          ),
        );
        return;
      }

      // 1️⃣ START / FIND ROOM (unik per pasien + layanan + status PROSES)
      final startRes = await http.post(
        Uri.parse('$kBaseUrl/pasien/chat-rooms/start'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          // ⬅ sekarang cuma kirim layanan_id
          'layanan_id': widget.layanan.id.toString(),
          // 'order_layanan_id': '...', // opsional nanti kalau mau di-relate ke order tertentu
        },
      );

      if (startRes.statusCode != 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Gagal membuat / mengambil ruang chat (${startRes.statusCode})',
            ),
          ),
        );
        return;
      }

      final startBody = json.decode(startRes.body) as Map<String, dynamic>;
      if (startBody['success'] != true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              startBody['message']?.toString() ??
                  'Gagal membuat / mengambil ruang chat.',
            ),
          ),
        );
        return;
      }

      final roomData = startBody['data'] as Map<String, dynamic>;
      final int roomId = roomData['id'] as int;
      final String roomTitle =
          (roomData['title'] ?? 'Chat Layanan') as String;

      // 2️⃣ KIRIM ETALASE SEKALI (biar di chat langsung muncul kartu layanan)
      final etalaseRes = await http.post(
        Uri.parse('$kBaseUrl/pasien/chat-rooms/$roomId/etalase'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: {
          'layanan_id': widget.layanan.id.toString(),
        },
      );

      // Gagal kirim etalase tidak memblok user masuk chat
      if (etalaseRes.statusCode != 201) {
        debugPrint(
          'Gagal mengirim etalase (status: ${etalaseRes.statusCode})',
        );
      }

      if (!mounted) return;

      // 3️⃣ MASUK KE HALAMAN CHAT UNTUK NEGOSIASI HARGA
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatRoomPage(
            roomId: roomId,
            roomTitle: roomTitle,
            role: 'pasien',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Terjadi kesalahan: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final layanan = widget.layanan;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Layanan'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🖼 FOTO BESAR (ALA PRODUK TOKPED)
                    _buildBigImage(layanan),
                    const SizedBox(height: 16),

                    // 🏷 NAMA + KATEGORI
                    Text(
                      layanan.namaLayanan,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (layanan.kategori != null &&
                        layanan.kategori!.trim().isNotEmpty)
                      Text(
                        layanan.kategori!,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
                        ),
                      ),

                    const SizedBox(height: 12),

                    // 🔖 CHIP INFO (tipe, durasi, visit, syarat perawat, lokasi)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(
                          label: Text(
                            layanan.tipeLayanan == 'paket'
                                ? 'Paket Layanan'
                                : 'Single Visit',
                            style: const TextStyle(fontSize: 12),
                          ),
                          backgroundColor:
                              Colors.blueAccent.withOpacity(0.08),
                        ),
                        if (layanan.durasiMenit != null)
                          Chip(
                            label: Text(
                              '${layanan.durasiMenit} menit / visit',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor:
                                Colors.orangeAccent.withOpacity(0.08),
                          ),
                        if (layanan.tipeLayanan == 'paket' &&
                            layanan.jumlahVisit != null)
                          Chip(
                            label: Text(
                              '${layanan.jumlahVisit}x visit',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor:
                                Colors.green.withOpacity(0.08),
                          ),
                        if (layanan.syaratPerawat != null)
                          Chip(
                            label: Text(
                              'Perawat: ${layanan.syaratPerawat}',
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor:
                                Colors.purple.withOpacity(0.08),
                          ),
                        if (layanan.lokasiTersedia != null)
                          Chip(
                            label: Text(
                              layanan.lokasiTersedia == 'keduanya'
                                  ? 'Rumah & RS'
                                  : (layanan.lokasiTersedia == 'rumah'
                                      ? 'Home Care'
                                      : 'Rumah Sakit'),
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor:
                                Colors.teal.withOpacity(0.08),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // 📄 DESKRIPSI LENGKAP
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Deskripsi Layanan',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            (layanan.deskripsi != null &&
                                    layanan.deskripsi!.trim().isNotEmpty)
                                ? layanan.deskripsi!
                                : 'Belum ada deskripsi detail untuk layanan ini.',
                            style: const TextStyle(fontSize: 13, height: 1.4),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ℹ️ INFO TAMBAHAN
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.2),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Informasi Lainnya',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildInfoRow(
                            icon: Icons.medical_services_outlined,
                            label: 'Tipe Layanan',
                            value: layanan.tipeLayanan == 'paket'
                                ? 'Paket visit berkala'
                                : 'Satu kali kunjungan',
                          ),
                          if (layanan.jumlahVisit != null)
                            _buildInfoRow(
                              icon: Icons.repeat,
                              label: 'Jumlah Visit',
                              value:
                                  '${layanan.jumlahVisit}x kedatangan perawat',
                            ),
                          if (layanan.durasiMenit != null)
                            _buildInfoRow(
                              icon: Icons.access_time,
                              label: 'Estimasi Durasi',
                              value:
                                  '${layanan.durasiMenit} menit tiap visit (estimasi)',
                            ),
                          if (layanan.syaratPerawat != null)
                            _buildInfoRow(
                              icon: Icons.person_search_outlined,
                              label: 'Kualifikasi Perawat',
                              value: layanan.syaratPerawat!,
                            ),
                          if (layanan.lokasiTersedia != null)
                            _buildInfoRow(
                              icon: Icons.location_on_outlined,
                              label: 'Lokasi Tersedia',
                              value: layanan.lokasiTersedia == 'keduanya'
                                  ? 'Home Care & Rumah Sakit'
                                  : (layanan.lokasiTersedia == 'rumah'
                                      ? 'Home Care (kunjungan ke rumah)'
                                      : 'Pelayanan di Rumah Sakit'),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // BOTTOM BAR: CHAT & NEGO
            Container(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _goToChatFirst,
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.chat_outlined),
                  label: Text(
                    _isSubmitting
                        ? 'Menghubungkan ke koordinator...'
                        : 'Chat & Negosiasi Harga',
                  ),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBigImage(Layanan layanan) {
    if (layanan.gambarUrl == null || layanan.gambarUrl!.isEmpty) {
      return Container(
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(
          Icons.medical_services,
          size: 48,
          color: Colors.grey,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Image.network(
          layanan.gambarUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) {
            return Container(
              color: Colors.grey[200],
              child: const Center(
                child: Icon(Icons.broken_image, size: 40),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

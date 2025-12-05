import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

// Warna (HCColor) dari HomePage
import 'package:home_care/users/HomePage.dart';

// Model Perawat dari kelolaPerawat.dart
import 'package:home_care/kordinator/kelolaPerawat.dart';

class DetailPerawatPage extends StatefulWidget {
  final Perawat perawat;

  const DetailPerawatPage({super.key, required this.perawat});

  @override
  State<DetailPerawatPage> createState() => _DetailPerawatPageState();
}

class _DetailPerawatPageState extends State<DetailPerawatPage> {
  static const String baseUrl = 'http://192.168.1.6:8000/api';

  final TextEditingController _passwordC = TextEditingController();
  bool _obscurePwd = true;
  bool _isSavingPassword = false;

  @override
  void dispose() {
    _passwordC.dispose();
    super.dispose();
  }

  String _disp(String? v) {
    if (v == null) return '-';
    if (v.trim().isEmpty) return '-';
    return v;
  }

  String _dispInt(int? v) {
    if (v == null) return '-';
    return v.toString();
  }

  /// Ubah path dari API (biasanya "/storage/perawat/....jpg")
  /// menjadi URL yang lewat proxy CORS: /api/media/...
  String? _resolveMediaUrl(String? raw) {
    if (raw == null) return null;
    String path = raw.trim();
    if (path.isEmpty) return null;

    // Kalau sudah full URL, biarin saja (buat jaga-jaga)
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    // Buang leading slash, mis: "/storage/perawat/foto/xxx.jpg" -> "storage/perawat/foto/xxx.jpg"
    if (path.startsWith('/')) {
      path = path.substring(1);
    }

    // Base API (bukan root web)
    const String baseApi = 'http://192.168.1.6:8000/api';

    // Route Laravel: /api/media/{path}
    // Di backend sudah handle kalau path diawali "storage/..."
    return '$baseApi/media/$path';
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _updatePassword() async {
    final pwd = _passwordC.text.trim();

    if (pwd.length < 6) {
      _showSnack('Password minimal 6 karakter', error: true);
      return;
    }

    setState(() => _isSavingPassword = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        _showSnack('Token tidak ditemukan. Silakan login ulang.', error: true);
        return;
      }

      // Endpoint: PUT /api/koordinator/perawat/{id}/password
      final url = Uri.parse(
        '$baseUrl/koordinator/perawat/${widget.perawat.id}/password',
      );

      final res = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'password': pwd}),
      );

      if (res.statusCode != 200 && res.statusCode != 201) {
        String msg = 'Gagal mengubah password (${res.statusCode})';
        try {
          final body = jsonDecode(res.body);
          if (body['message'] != null) msg = body['message'];
        } catch (_) {}
        _showSnack(msg, error: true);
        return;
      }

      final body = jsonDecode(res.body);
      if (body['success'] != true) {
        _showSnack(body['message'] ?? 'Gagal mengubah password', error: true);
        return;
      }

      _passwordC.clear();
      _showSnack('Password perawat berhasil diubah');
    } catch (e) {
      _showSnack('Terjadi kesalahan: $e', error: true);
    } finally {
      if (mounted) setState(() => _isSavingPassword = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final perawat = widget.perawat;

    return Scaffold(
      backgroundColor: HCColor.bg,
      appBar: AppBar(
        backgroundColor: HCColor.primary,
        foregroundColor: Colors.white,
        title: const Text('Detail Perawat'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // ================== HEADER ==================
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: HCColor.primary.withOpacity(.1),
                      backgroundImage: (() {
                        final url = _resolveMediaUrl(perawat.foto);
                        return (url != null && url.isNotEmpty)
                            ? NetworkImage(url)
                            : null;
                      })(),
                      child: (() {
                        final url = _resolveMediaUrl(perawat.foto);
                        if (url != null && url.isNotEmpty) return null;
                        return Text(
                          perawat.inisial ?? '?',
                          style: TextStyle(
                            color: HCColor.primaryDark,
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                          ),
                        );
                      })(),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _disp(perawat.namaLengkap),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Kode: ${_disp(perawat.kodePerawat)}',
                            style: theme.textTheme.bodySmall,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Chip(
                                label: Text(
                                  perawat.labelJenisKelamin,
                                  style: const TextStyle(fontSize: 12),
                                ),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(
                                  (perawat.isActive ?? true)
                                      ? 'Aktif'
                                      : 'Tidak Aktif',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                backgroundColor: (perawat.isActive ?? true)
                                    ? Colors.green.withOpacity(.15)
                                    : Colors.red.withOpacity(.15),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ================== FOTO & DOKUMEN ==================
            _SectionCard(
              title: 'Foto & Dokumen',
              children: [
                _DocImageTile(
                  label: 'Foto Perawat',
                  url: _resolveMediaUrl(perawat.foto),
                ),
                _DocImageTile(
                  label: 'Foto KTP',
                  url: _resolveMediaUrl(perawat.fotoKtp),
                ),
                _DocImageTile(
                  label: 'Ijazah',
                  url: _resolveMediaUrl(perawat.ijazah),
                ),
                _DocImageTile(
                  label: 'STR',
                  url: _resolveMediaUrl(perawat.strFile),
                ),
                _DocImageTile(
                  label: 'SIP',
                  url: _resolveMediaUrl(perawat.sipFile),
                ),
                _DocImageTile(
                  label: 'Sertifikat BTCLS',
                  url: _resolveMediaUrl(perawat.sertifikatBtcls),
                ),
                _DocImageTile(
                  label: 'Sertifikat PPRA',
                  url: _resolveMediaUrl(perawat.sertifikatPpra),
                ),
                _DocImageTile(
                  label: 'Sertifikat Lainnya',
                  url: _resolveMediaUrl(perawat.sertifikatLainnya),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ================== DATA PRIBADI ==================
            _SectionCard(
              title: 'Data Pribadi',
              children: [
                _DetailRow(
                  label: 'Nama Lengkap',
                  value: _disp(perawat.namaLengkap),
                ),
                _DetailRow(label: 'NIK', value: _disp(perawat.nik)),
                _DetailRow(
                  label: 'Jenis Kelamin',
                  value: perawat.labelJenisKelamin,
                ),
                _DetailRow(
                  label: 'Tempat Lahir',
                  value: _disp(perawat.tempatLahir),
                ),
                _DetailRow(
                  label: 'Tanggal Lahir',
                  value: _disp(perawat.tanggalLahir),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ================== KONTAK ==================
            _SectionCard(
              title: 'Kontak',
              children: [
                _DetailRow(label: 'No HP', value: _disp(perawat.noHp)),
                _DetailRow(label: 'Email', value: _disp(perawat.email)),
              ],
            ),

            const SizedBox(height: 12),

            // ================== PROFESIONAL ==================
            _SectionCard(
              title: 'Profesional',
              children: [
                _DetailRow(label: 'Profesi', value: _disp(perawat.profesi)),
                _DetailRow(label: 'Keahlian', value: _disp(perawat.keahlian)),
                _DetailRow(label: 'No STR', value: _disp(perawat.noStr)),
                _DetailRow(label: 'No SIP', value: _disp(perawat.noSip)),
              ],
            ),

            const SizedBox(height: 12),

            // ================== PENGALAMAN & AREA ==================
            _SectionCard(
              title: 'Pengalaman & Area Kerja',
              children: [
                _DetailRow(
                  label: 'Tahun Pengalaman',
                  value: _dispInt(perawat.tahunPengalaman),
                ),
                _DetailRow(
                  label: 'Tempat Kerja Terakhir',
                  value: _disp(perawat.tempatKerjaTerakhir),
                ),
                _DetailRow(
                  label: 'Wilayah Kerja',
                  value: _disp(perawat.wilayah),
                ),
                _DetailRow(
                  label: 'Alamat',
                  value: _disp(perawat.alamat),
                  isMultiline: true,
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ================== KONTAK DARURAT ==================
            _SectionCard(
              title: 'Kontak Darurat',
              children: [
                _DetailRow(
                  label: 'Nama',
                  value: _disp(perawat.kontakDaruratNama),
                ),
                _DetailRow(
                  label: 'No HP',
                  value: _disp(perawat.kontakDaruratNoHp),
                ),
                _DetailRow(
                  label: 'Hubungan',
                  value: _disp(perawat.kontakDaruratHubungan),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // ================== AKUN LOGIN (PASSWORD) ==================
            _SectionCard(
              title: 'Akun Login Perawat',
              children: [
                const Text(
                  'Atur / reset password untuk akun perawat ini. '
                  'Berikan password ke perawat agar bisa login ke aplikasi.',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordC,
                  obscureText: _obscurePwd,
                  decoration: InputDecoration(
                    labelText: 'Password baru',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePwd
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() => _obscurePwd = !_obscurePwd);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 42,
                  child: ElevatedButton.icon(
                    onPressed: _isSavingPassword ? null : _updatePassword,
                    icon: _isSavingPassword
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: Text(
                      _isSavingPassword
                          ? 'Menyimpan...'
                          : 'Setel / Ubah Password',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: HCColor.primary,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ===================================================
//  WIDGET BANTUAN
// ===================================================

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 8),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isMultiline;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isMultiline = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: Colors.grey[700]);
    final valueStyle = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(fontWeight: FontWeight.w500);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: isMultiline
            ? CrossAxisAlignment.start
            : CrossAxisAlignment.center,
        children: [
          SizedBox(width: 140, child: Text(label, style: labelStyle)),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
              maxLines: isMultiline ? null : 2,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocImageTile extends StatelessWidget {
  final String label;
  final String? url;

  const _DocImageTile({required this.label, this.url});

  @override
  Widget build(BuildContext context) {
    final String imageUrl = url ?? '';
    final bool hasImage = imageUrl.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: hasImage
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: Text('Gagal memuat gambar'),
                        ),
                      ),
                    )
                  : Container(
                      color: Colors.grey[200],
                      child: const Center(
                        child: Text(
                          'Belum ada file',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

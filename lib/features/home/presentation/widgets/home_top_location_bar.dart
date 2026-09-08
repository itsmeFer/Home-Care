import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/core/services/storage_service.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';
import 'package:home_care/users/home_page.dart';
import 'package:home_care/users/layanan_page.dart';
import 'package:home_care/users/notifikasi_page.dart';
import 'package:home_care/users/profile.dart';
import 'package:home_care/users/search_page.dart';
import 'package:home_care/utils/app_cached_image.dart';

class TopLocationBar extends StatefulWidget {
  const TopLocationBar();

  @override
  State<TopLocationBar> createState() => _TopLocationBarState();
}

class _TopLocationBarState extends State<TopLocationBar> {
  String? _fotoProfilUrl;
  String? _nama;
  String? _lokasi;
  bool _isLoadingFoto = false;

  int _notifUnreadCount = 0;
  Timer? _notifTimer;

  static String get baseUrl => ApiConstants.apiBase;

  @override
  void initState() {
    super.initState();
    _loadProfileFoto();
    _loadNotifUnread();
    _startNotifPolling();
  }

  @override
  void dispose() {
    _notifTimer?.cancel();
    super.dispose();
  }

  void _startNotifPolling() {
    _notifTimer?.cancel();
    _notifTimer = Timer.periodic(const Duration(seconds: 8), (_) {
      _loadNotifUnread();
    });
  }

  String? _resolveMediaUrl(String? raw) => ApiConstants.resolveMediaUrl(raw);

  Future<void> _openProfilePage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfilePage()),
    );

    if (!mounted) return;
    _loadProfileFoto();
  }

  Future<void> _loadNotifUnread() async {
    try {
      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) return;

      final res = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode != 200) return;

      final body = json.decode(res.body);
      if (body is! Map || body['success'] != true) return;

      int unreadCount = 0;

      if (body['meta'] is Map && body['meta']['unread_count'] != null) {
        final raw = body['meta']['unread_count'];
        unreadCount = raw is int ? raw : int.tryParse(raw.toString()) ?? 0;
      } else {
        final List data = (body['data'] ?? []) as List;
        unreadCount =
            data.where((e) => e is Map && e['is_read'] != true).length;
      }

      if (!mounted) return;
      setState(() {
        _notifUnreadCount = unreadCount;
      });
    } catch (_) {}
  }

  Future<void> _loadProfileFoto() async {
    try {
      setState(() => _isLoadingFoto = true);

      final token = await StorageService.getToken();
      if (token == null || token.isEmpty) return;

      final res = await http.get(
        Uri.parse('$baseUrl/me'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode != 200) return;

      final body = json.decode(res.body);
      if (body is! Map || body['success'] != true) return;

      final data = body['data'] ?? {};
      final pasien = data['pasien'] as Map<String, dynamic>?;
      final user = data['user'] as Map<String, dynamic>?;

      final rawFoto = pasien?['foto_profil_url'] ?? pasien?['foto_profil'];
      final kota = (pasien?['kota'] ?? '').toString().trim();

      String lokasi = 'Lokasi belum tersedia';
      if (kota.isNotEmpty) {
        lokasi = kota;
      }

      setState(() {
        _fotoProfilUrl = _resolveMediaUrl(rawFoto?.toString());
        _nama = (pasien?['nama_lengkap'] ?? user?['name'])?.toString();
        _lokasi = lokasi;
      });
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingFoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sapaanNama =
        (_nama != null && _nama!.trim().isNotEmpty) ? _nama!.trim() : 'Sahabat';

    return Container(
      color: HCColor.bg,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: _openProfilePage,
            child: Padding(
              padding: const EdgeInsets.all(2),
              child:
                  (_fotoProfilUrl != null && _fotoProfilUrl!.isNotEmpty)
                      ? CircleAvatar(
                        radius: 18,
                        backgroundColor: HCColor.primary.withOpacity(0.12),
                        backgroundImage: NetworkImage(_fotoProfilUrl!),
                      )
                      : CircleAvatar(
                        radius: 18,
                        backgroundColor: HCColor.primary.withOpacity(0.12),
                        child: const Icon(
                          Icons.person_outline,
                          color: HCColor.primary,
                          size: 18,
                        ),
                      ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: _openProfilePage,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isLoadingFoto
                          ? 'Halo, sebentar ya...'
                          : 'Halo, $sapaanNama',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: HCColor.primary,
                          size: 14,
                        ),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            _isLoadingFoto
                                ? 'Sedang memuat lokasi...'
                                : (_lokasi ?? 'Lokasi belum tersedia'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Colors.black54,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotifikasiPage()),
              );
              _loadNotifUnread();
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                        color: Colors.black.withValues(alpha: 0.06),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.notifications_outlined,
                    color: Colors.black87,
                    size: 20,
                  ),
                ),
                if (_notifUnreadCount > 0)
                  Positioned(
                    right: -4,
                    top: -4,
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: Colors.white, width: 1.2),
                      ),
                      child: Text(
                        _notifUnreadCount > 99 ? '99+' : '$_notifUnreadCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          height: 1.1,
                        ),
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
}


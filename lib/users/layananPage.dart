import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:home_care/users/pesanLayanan.dart';
import 'package:home_care/users/profile.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

const String kBaseUrl = 'http://192.168.1.5:8000/api';

/// Palet warna home care (teal/medical)
class HCColor {
  static const primary = Color(0xFF0BA5A7);
  static const primaryDark = Color(0xFF088088);
  static const bg = Color(0xFFF5F7FA);
  static const card = Colors.white;
  static const textMuted = Colors.black54;
  static const lightTeal = Color(0xFFE0F7F7);
}

class Layanan {
  final int id;
  final String kodeLayanan;
  final String namaLayanan;
  final String? deskripsi;
  final String? kategori;
  final String tipeLayanan;
  final int? jumlahVisit;
  final double hargaFix;
  final int? durasiMenit;
  final String? syaratPerawat;
  final String? lokasiTersedia;
  final bool aktif;
  final String? gambarUrl;

  Layanan({
    required this.id,
    required this.kodeLayanan,
    required this.namaLayanan,
    this.deskripsi,
    this.kategori,
    required this.tipeLayanan,
    this.jumlahVisit,
    required this.hargaFix,
    this.durasiMenit,
    this.syaratPerawat,
    this.lokasiTersedia,
    required this.aktif,
    this.gambarUrl,
  });

  factory Layanan.fromJson(Map<String, dynamic> json) {
    return Layanan(
      id: json['id'] as int,
      kodeLayanan: json['kode_layanan'] ?? '',
      namaLayanan: json['nama_layanan'] ?? '',
      deskripsi: json['deskripsi'],
      kategori: json['kategori'],
      tipeLayanan: json['tipe_layanan'] ?? 'single',
      jumlahVisit: json['jumlah_visit'],
      hargaFix: _parseHarga(json['harga_fix'] ?? json['harga_dasar']),
      durasiMenit: json['durasi_menit'],
      syaratPerawat: json['syarat_perawat'],
      lokasiTersedia: json['lokasi_tersedia'],
      aktif: (json['aktif'] == 1 || json['aktif'] == true),
      gambarUrl: json['gambar_url'],
    );
  }

  static double _parseHarga(dynamic value) {
    if (value == null) return 0.0;
    if (value is int || value is double) return (value as num).toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }
}

class PilihLayananPage extends StatefulWidget {
  final String? kategori;

  const PilihLayananPage({Key? key, this.kategori}) : super(key: key);

  @override
  State<PilihLayananPage> createState() => _PilihLayananPageState();
}

class _PilihLayananPageState extends State<PilihLayananPage> {
  bool _isLoading = true;
  bool _isLoadingKategori = true;
  String? _error;
  List<Layanan> _layananList = [];
  List<Layanan> _filteredList = [];
  List<String> _kategoriList = [];
  String? _selectedKategori;
  final List<String> _searchHints = [
    'Cari layanan kesehatan...',
    'Perawat profesional...',
    'Fisioterapi di rumah...',
    'Medical check-up...',
    'Konsultasi dokter...',
  ];

  int _currentHintIndex = 0;
  String _animatedHintText = '';
  Timer? _typingTimer;
  bool _isTypingForward = true;
  final TextEditingController _searchController = TextEditingController();

  // ✅ Profile data untuk validasi
  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    _selectedKategori = widget.kategori;
    _fetchKategori();
    _fetchLayanan();
    _fetchProfileData();
    _startSearchHintAnimation();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _applyFilters();
  }

  void _startSearchHintAnimation() {
    _typingTimer?.cancel();

    final currentText = _searchHints[_currentHintIndex];
    int charIndex = 0;
    _isTypingForward = true;

    _typingTimer = Timer.periodic(const Duration(milliseconds: 90), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_isTypingForward) {
          if (charIndex <= currentText.length) {
            _animatedHintText = currentText.substring(0, charIndex);
            charIndex++;
          } else {
            timer.cancel();
            Future.delayed(const Duration(seconds: 1), () {
              if (!mounted) return;
              _startDeletingHintAnimation();
            });
          }
        }
      });
    });
  }

  void _startDeletingHintAnimation() {
    _typingTimer?.cancel();

    final currentText = _searchHints[_currentHintIndex];
    int charIndex = currentText.length;

    _typingTimer = Timer.periodic(const Duration(milliseconds: 45), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (charIndex >= 0) {
          _animatedHintText = currentText.substring(0, charIndex);
          charIndex--;
        } else {
          timer.cancel();
          _currentHintIndex = (_currentHintIndex + 1) % _searchHints.length;

          Future.delayed(const Duration(milliseconds: 300), () {
            if (!mounted) return;
            _startSearchHintAnimation();
          });
        }
      });
    });
  }

  Widget _buildBodyAnimated() {
    if (_isLoading) {
      return const Center(
        key: ValueKey('loading'),
        child: CircularProgressIndicator(),
      );
    }

    if (_error != null) {
      return Center(
        key: const ValueKey('error'),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchLayanan,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredList.isEmpty) {
      return Center(
        key: ValueKey(
          'empty_${_searchController.text}_${_selectedKategori ?? 'all'}',
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Tidak ada layanan yang cocok'
                  : 'Belum ada layanan tersedia',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      key: ValueKey(
        'list_${_searchController.text}_${_selectedKategori ?? 'all'}_${_filteredList.length}',
      ),
      onRefresh: _fetchLayanan,
      color: HCColor.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredList.length,
        itemBuilder: (context, index) {
          final layanan = _filteredList[index];
          return TweenAnimationBuilder<double>(
            duration: Duration(milliseconds: 180 + (index * 40)),
            tween: Tween(begin: 0, end: 1),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 16 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: _buildLayananCard(layanan),
          );
        },
      ),
    );
  }

  void _applyFilters() {
    final keyword = _searchController.text.trim().toLowerCase();

    setState(() {
      _filteredList = _layananList.where((layanan) {
        final searchMatch =
            keyword.isEmpty ||
            layanan.namaLayanan.toLowerCase().contains(keyword) ||
            (layanan.deskripsi ?? '').toLowerCase().contains(keyword) ||
            (layanan.kategori ?? '').toLowerCase().contains(keyword);

        final kategoriMatch =
            _selectedKategori == null ||
            _selectedKategori == 'Semua' ||
            layanan.kategori == _selectedKategori;

        return searchMatch && kategoriMatch;
      }).toList();
    });
  }

  // ===== FETCH PROFILE DATA (untuk validasi) =====
  Future<void> _fetchProfileData() async {
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

          if (mounted) {
            setState(() {
              _profileData = pasien;
            });
          }
        }
      }
    } catch (e) {
      print('Error fetching profile: $e');
    }
  }

  // ===== VALIDASI PROFIL LENGKAP =====
  bool _isProfileComplete() {
    if (_profileData == null) return false;

    // Field yang wajib diisi
    final requiredFields = [
      'nama_lengkap',
      'no_hp',
      'jenis_kelamin',
      'tanggal_lahir',
      'alamat',
      'kecamatan',
      'kota',
      'kode_pos',
    ];

    for (final field in requiredFields) {
      final value = _profileData![field];
      if (value == null || value.toString().trim().isEmpty) {
        return false;
      }
    }

    return true;
  }

  // ===== GET MISSING FIELDS =====
  List<String> _getMissingFields() {
    if (_profileData == null) return ['Semua data profil'];

    final missingFields = <String>[];

    final fieldLabels = {
      'nama_lengkap': 'Nama Lengkap',
      'no_hp': 'No. HP',
      'jenis_kelamin': 'Jenis Kelamin',
      'tanggal_lahir': 'Tanggal Lahir',
      'alamat': 'Alamat',
      'kecamatan': 'Kecamatan',
      'kota': 'Kota',
      'kode_pos': 'Kode Pos',
    };

    fieldLabels.forEach((key, label) {
      final value = _profileData![key];
      if (value == null || value.toString().trim().isEmpty) {
        missingFields.add(label);
      }
    });

    return missingFields;
  }

  // ===== SHOW INCOMPLETE PROFILE DIALOG =====
  void _showIncompleteProfileDialog() {
    final missingFields = _getMissingFields();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.warning_rounded,
                color: Colors.orange[700],
                size: 28,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Profil Belum Lengkap',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Untuk memesan layanan, Anda harus melengkapi profil terlebih dahulu.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: HCColor.lightTeal,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: HCColor.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16,
                        color: HCColor.primary,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        'Data yang belum diisi:',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: HCColor.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ...missingFields.map(
                    (field) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Icon(
                            Icons.circle,
                            size: 6,
                            color: HCColor.primaryDark,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            field,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Nanti',
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // ✅ Navigate ke ProfilePage
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfilePage()),
              ).then((_) {
                // Refresh profile setelah kembali dari ProfilePage
                _fetchProfileData();
              });
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Lengkapi Profil'),
            style: ElevatedButton.styleFrom(
              backgroundColor: HCColor.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===== HANDLE LAYANAN TAP (WITH VALIDATION) =====
  Future<void> _handleLayananTap(Layanan layanan) async {
    // ✅ Validasi profil lengkap
    if (!_isProfileComplete()) {
      _showIncompleteProfileDialog();
      return;
    }

    // ✅ Jika profil lengkap, lanjut ke PesanLayananPage
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PesanLayananPage(layanan: layanan)),
    );

    if (result != null && mounted) {
      Navigator.pop(context, result);
    }
  }

  Future<void> _fetchKategori() async {
    setState(() => _isLoadingKategori = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) return;

      final uri = Uri.parse('$kBaseUrl/layanan/kategori');

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
          final List<dynamic> data = body['kategori'] ?? [];
          setState(() {
            _kategoriList = ['Semua', ...data.map((e) => e.toString())];
            _isLoadingKategori = false;
          });
        }
      }
    } catch (e) {
      print('Error fetching kategori: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingKategori = false);
      }
    }
  }

  Future<void> _fetchLayanan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');

      if (token == null) {
        setState(() {
          _isLoading = false;
          _error = 'Token tidak ditemukan. Silakan login ulang.';
        });
        return;
      }

      final queryParams = <String, String>{'aktif': '1'};

      if (_selectedKategori != null &&
          _selectedKategori != 'Semua' &&
          _selectedKategori!.trim().isNotEmpty) {
        queryParams['kategori'] = _selectedKategori!.trim();
      }

      final uri = Uri.parse(
        '$kBaseUrl/layanan',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = json.decode(response.body) as Map<String, dynamic>;

        if (body['success'] != true) {
          setState(() {
            _isLoading = false;
            _error = body['message']?.toString() ?? 'Gagal memuat layanan.';
          });
          return;
        }

        final List<dynamic> data = body['data'] ?? [];
        final list = data.map((e) => Layanan.fromJson(e)).toList();

        setState(() {
          _isLoading = false;
          _layananList = list;
        });
        _applyFilters();
      } else if (response.statusCode == 401) {
        setState(() {
          _isLoading = false;
          _error = 'Sesi login berakhir. Silakan login ulang.';
        });
      } else {
        setState(() {
          _isLoading = false;
          _error = 'Gagal memuat layanan. Kode: ${response.statusCode}';
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

  String _formatRupiah(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColor.bg,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Pilih Layanan',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // ===== SEARCH BAR =====
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: HCColor.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _applyFilters(),
                decoration: InputDecoration(
                  hintText: 'Cari layanan kesehatan...',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.search, color: HCColor.primary),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, size: 20, color: Colors.grey),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilters();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),

          // ===== KATEGORI HORIZONTAL SCROLL =====
          if (!_isLoadingKategori && _kategoriList.isNotEmpty)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                height: 42,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _kategoriList.length,
                  itemBuilder: (context, index) {
                    final kategori = _kategoriList[index];
                    final isSelected =
                        _selectedKategori == kategori ||
                        (_selectedKategori == null && kategori == 'Semua');

                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildKategoriChip(kategori, isSelected),
                    );
                  },
                ),
              ),
            ),

          const SizedBox(height: 8),

          // ===== LIST LAYANAN =====
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.03),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _buildBodyAnimated(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKategoriChip(String kategori, bool isSelected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedKategori = kategori == 'Semua' ? null : kategori;
        });
        _fetchLayanan();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? HCColor.primary : HCColor.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? HCColor.primary : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Text(
          kategori,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchLayanan,
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HCColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredList.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Tidak ada layanan yang cocok'
                  : 'Belum ada layanan tersedia',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchLayanan,
      color: HCColor.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _filteredList.length,
        itemBuilder: (context, index) {
          final layanan = _filteredList[index];
          return _buildLayananCard(layanan);
        },
      ),
    );
  }

  Widget _buildLayananCard(Layanan layanan) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _handleLayananTap(layanan), // ✅ GUNAKAN METHOD BARU
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== GAMBAR LAYANAN =====
              Stack(
                children: [
                  _buildImageHeader(layanan),

                  // Kategori Badge
                  if (layanan.kategori != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: HCColor.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          layanan.kategori!,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // ===== DETAIL LAYANAN =====
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nama Layanan
                    Text(
                      layanan.namaLayanan,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Deskripsi
                    if (layanan.deskripsi != null &&
                        layanan.deskripsi!.trim().isNotEmpty)
                      Text(
                        layanan.deskripsi!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: HCColor.textMuted,
                          height: 1.4,
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Info Badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (layanan.tipeLayanan == 'paket')
                          _buildInfoBadge(
                            icon: Icons.inventory_2_outlined,
                            label: '${layanan.jumlahVisit}x Visit',
                            color: HCColor.primary,
                          ),
                        if (layanan.durasiMenit != null)
                          _buildInfoBadge(
                            icon: Icons.access_time_outlined,
                            label: '${layanan.durasiMenit} menit',
                            color: HCColor.primaryDark,
                          ),
                        if (layanan.syaratPerawat != null)
                          _buildInfoBadge(
                            icon: Icons.medical_services_outlined,
                            label: layanan.syaratPerawat!.toUpperCase(),
                            color: const Color(0xFF43A047),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    // Harga & Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Harga
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mulai dari',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: HCColor.textMuted,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _formatRupiah(layanan.hargaFix),
                                style: const TextStyle(
                                  fontSize: 19,
                                  fontWeight: FontWeight.w800,
                                  color: HCColor.primary,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Button Pesan
                        Container(
                          decoration: BoxDecoration(
                            color: HCColor.primary,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: HCColor.primary.withOpacity(0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => _handleLayananTap(
                                layanan,
                              ), // ✅ GUNAKAN METHOD BARU
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                child: Row(
                                  children: const [
                                    Text(
                                      'Pesan',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(width: 6),
                                    Icon(
                                      Icons.arrow_forward,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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
    );
  }

  Widget _buildImageHeader(Layanan layanan) {
    if (layanan.gambarUrl == null || layanan.gambarUrl!.isEmpty) {
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: HCColor.lightTeal,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
          ),
        ),
        child: Center(
          child: Icon(
            Icons.medical_services_rounded,
            size: 64,
            color: HCColor.primary,
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(16),
        topRight: Radius.circular(16),
      ),
      child: Image.network(
        layanan.gambarUrl!,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) {
          return Container(
            height: 180,
            decoration: BoxDecoration(
              color: HCColor.lightTeal,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.broken_image_rounded,
                size: 64,
                color: HCColor.primary,
              ),
            ),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            height: 180,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
                color: HCColor.primary,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoBadge({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

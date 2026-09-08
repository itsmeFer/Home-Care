import 'dart:convert';
import 'package:home_care/core/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:home_care/users/pesan_layanan.dart';
import 'package:home_care/users/profile.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';

import 'package:home_care/features/services_catalog/domain/service_model.dart';
import 'package:home_care/core/widgets/skeletons/skeletons.dart';
import 'package:home_care/core/widgets/patient_app_bar.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

export 'package:home_care/features/services_catalog/domain/service_model.dart';

String get kBaseUrl => ApiConstants.apiBase;


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
  List<KategoriLayananItem> _kategoriList = [];
  KategoriLayananItem? _selectedKategori;
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

  Map<String, dynamic>? _profileData;

  @override
  void initState() {
    super.initState();
    if (widget.kategori != null && widget.kategori!.trim().isNotEmpty) {
      _selectedKategori = KategoriLayananItem(
        id: 0,
        namaKategori: widget.kategori!,
        slug: widget.kategori!,
      );
    }
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
      return const ServiceCatalogSkeleton(
        key: ValueKey('loading'),
        showCategoryChips: false,
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
              Icon(IconlyLight.dangerCircle, size: 64, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _fetchLayanan,
                icon: const Icon(IconlyLight.swap),
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
            Icon(IconlyLight.search, size: 80, color: Colors.grey[300]),
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
      _filteredList =
          _layananList.where((layanan) {
            final searchMatch =
                keyword.isEmpty ||
                layanan.namaLayanan.toLowerCase().contains(keyword) ||
                (layanan.deskripsi ?? '').toLowerCase().contains(keyword) ||
                (layanan.kategori ?? '').toLowerCase().contains(keyword);

            final kategoriMatch =
                _selectedKategori == null ||
                (layanan.kategori ?? '').toLowerCase() ==
                    _selectedKategori!.namaKategori.toLowerCase();

            return searchMatch && kategoriMatch;
          }).toList();
    });
  }

  Future<void> _fetchProfileData() async {
    try {
      final token = await StorageService.getToken();

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

  bool _isProfileComplete() {
    if (_profileData == null) return false;

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

  void _showIncompleteProfileDialog() {
    final missingFields = _getMissingFields();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    IconlyLight.dangerCircle,
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
                            IconlyLight.infoSquare,
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
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: HCColor.primaryDark,
                                  shape: BoxShape.circle,
                                ),
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
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfilePage()),
                  ).then((_) {

                    _fetchProfileData();
                  });
                },
                icon: const Icon(IconlyLight.edit, size: 18),
                label: const Text('Lengkapi Profil'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: HCColor.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _handleLayananTap(Layanan layanan) async {

    if (!_isProfileComplete()) {
      _showIncompleteProfileDialog();
      return;
    }

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
      final uri = Uri.parse('$kBaseUrl/kategori-layanan');

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        if (body['success'] == true) {
          final List<dynamic> data = body['data'] ?? [];

          final kategori =
              data
                  .map(
                    (e) =>
                        KategoriLayananItem.fromJson(e as Map<String, dynamic>),
                  )
                  .toList();

          KategoriLayananItem? selected = _selectedKategori;

          if (_selectedKategori != null) {
            try {
              selected = kategori.firstWhere(
                (k) =>
                    k.namaKategori.toLowerCase() ==
                        _selectedKategori!.namaKategori.toLowerCase() ||
                    k.slug.toLowerCase() ==
                        _selectedKategori!.slug.toLowerCase(),
              );
            } catch (_) {}
          }

          setState(() {
            _kategoriList = kategori;
            _selectedKategori = selected;
            _isLoadingKategori = false;
          });
        } else {
          setState(() => _isLoadingKategori = false);
        }
      } else {
        setState(() => _isLoadingKategori = false);
      }
    } catch (e) {
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
      final token = await StorageService.getToken();

      if (token == null) {
        setState(() {
          _isLoading = false;
          _error = 'Token tidak ditemukan. Silakan login ulang.';
        });
        return;
      }

      final queryParams = <String, String>{'aktif': '1'};

      if (_selectedKategori != null &&
          _selectedKategori!.namaKategori.trim().isNotEmpty) {
        queryParams['kategori'] = _selectedKategori!.namaKategori.trim();
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

  String _formatRupiah(double amount) => AppFormatters.currency(amount);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColor.bg,
      appBar: const PatientAppBar(
        title: 'Pilih Layanan',
      ),
      body: Column(
        children: [

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
                  prefixIcon: Icon(IconlyLight.search, color: HCColor.primary),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: Icon(
                              IconlyLight.closeSquare,
                              size: 20,
                              color: Colors.grey,
                            ),
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

          if (_isLoadingKategori)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: 5,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, index) => AppSkeleton(
                    width: index == 0 ? 70 : 100,
                    height: 36,
                    borderRadius: 20,
                  ),
                ),
              ),
            )
          else
            Container(
              color: Colors.white,
              padding: const EdgeInsets.only(bottom: 12),
              child: SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _buildKategoriChip(
                        label: 'Semua',
                        isSelected: _selectedKategori == null,
                        onTap: () {
                          setState(() {
                            _selectedKategori = null;
                          });
                          _fetchLayanan();
                        },
                      ),
                    ),
                    ..._kategoriList.map((kategori) {
                      final isSelected =
                          _selectedKategori?.id == kategori.id ||
                          (_selectedKategori != null &&
                              _selectedKategori!.namaKategori.toLowerCase() ==
                                  kategori.namaKategori.toLowerCase());

                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _buildKategoriChip(
                          label: kategori.namaKategori,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() {
                              _selectedKategori = kategori;
                            });
                            _fetchLayanan();
                          },
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),

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

  Widget _buildKategoriChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
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
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
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
          onTap: () => _handleLayananTap(layanan),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              Stack(
                children: [
                  _buildImageHeader(layanan),

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

              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      layanan.namaLayanan,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),

                    const SizedBox(height: 6),

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

                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (layanan.tipeLayanan == 'paket')
                          _buildInfoBadge(
                            icon: IconlyLight.bag2,
                            label: '${layanan.jumlahVisit}x Visit',
                            color: HCColor.primary,
                          ),
                        if (layanan.durasiMenit != null)
                          _buildInfoBadge(
                            icon: IconlyLight.timeCircle,
                            label: '${layanan.durasiMenit} menit',
                            color: HCColor.primaryDark,
                          ),
                        if (layanan.syaratPerawat != null)
                          _buildInfoBadge(
                            icon: IconlyLight.activity,
                            label: layanan.syaratPerawat!.toUpperCase(),
                            color: const Color(0xFF43A047),
                          ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [

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
                              onTap:
                                  () => _handleLayananTap(
                                    layanan,
                                  ),
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
                                      IconlyLight.arrowRight2,
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
            IconlyLight.activity,
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
                IconlyLight.image,
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
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: const AppSkeleton(
              width: double.infinity,
              height: double.infinity,
              borderRadius: 16,
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

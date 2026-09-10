import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/widgets/patient_app_bar.dart';
import 'package:home_care/core/widgets/skeletons/skeletons.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';
import 'package:home_care/users/pesan_layanan.dart';
import 'services/layanan_service.dart';
import 'widgets/incomplete_profile_dialog.dart';
import 'widgets/layanan_card.dart';
import 'widgets/layanan_category_chips.dart';

export 'package:home_care/features/services_catalog/domain/service_model.dart';
export 'services/layanan_service.dart';
export 'widgets/layanan_card.dart';
export 'widgets/layanan_category_chips.dart';

class PilihLayananPage extends StatefulWidget {
  final String? kategori;

  const PilihLayananPage({super.key, this.kategori});

  @override
  State<PilihLayananPage> createState() => _PilihLayananPageState();
}

class _PilihLayananPageState extends State<PilihLayananPage> {
  final LayananService _service = const LayananService();
  final TextEditingController _searchController = TextEditingController();

  bool _isLoading = true;
  bool _isLoadingKategori = true;
  String? _error;

  List<Layanan> _layananList = [];
  List<Layanan> _filteredList = [];
  List<KategoriLayananItem> _kategoriList = [];
  KategoriLayananItem? _selectedKategori;
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
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    _fetchKategori();
    _fetchLayanan();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final pasien = await _service.fetchPatientProfile();
    if (!mounted) return;
    setState(() => _profileData = pasien);
  }

  Future<void> _fetchKategori() async {
    setState(() => _isLoadingKategori = true);
    final kategori = await _service.fetchKategori();
    if (!mounted) return;

    KategoriLayananItem? selected = _selectedKategori;
    if (_selectedKategori != null) {
      try {
        selected = kategori.firstWhere(
          (k) =>
              k.namaKategori.toLowerCase() ==
                  _selectedKategori!.namaKategori.toLowerCase() ||
              k.slug.toLowerCase() == _selectedKategori!.slug.toLowerCase(),
        );
      } catch (_) {}
    }

    setState(() {
      _kategoriList = kategori;
      _selectedKategori = selected;
      _isLoadingKategori = false;
    });
  }

  Future<void> _fetchLayanan() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await _service.fetchLayanan();
      if (!mounted) return;
      setState(() {
        _layananList = list;
        _isLoading = false;
      });
      _applyFilters();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Gagal memuat layanan: $e';
      });
    }
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

  Future<void> _handleLayananTap(Layanan layanan) async {
    if (!IncompleteProfileDialog.isProfileComplete(_profileData)) {
      IncompleteProfileDialog.show(
        context,
        profileData: _profileData,
        onComplete: _fetchProfile,
      );
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColor.bg,
      appBar: const PatientAppBar(title: 'Pilih Layanan'),
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
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  prefixIcon: const Icon(IconlyLight.search, color: HCColor.primary),
                  suffixIcon:
                      _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(
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
          LayananCategoryChips(
            isLoading: _isLoadingKategori,
            kategoriList: _kategoriList,
            selectedKategori: _selectedKategori,
            onSelect: (kategori) {
              setState(() => _selectedKategori = kategori);
              _applyFilters();
            },
          ),
          const SizedBox(height: 8),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const ServiceCatalogSkeleton(showCategoryChips: false);
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(IconlyLight.dangerCircle, size: 64, color: Colors.red.shade300),
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(IconlyLight.search, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isNotEmpty
                  ? 'Tidak ada layanan yang cocok'
                  : 'Belum ada layanan tersedia',
              style: TextStyle(
                color: Colors.grey.shade600,
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
          return LayananCard(
            layanan: layanan,
            onTap: () => _handleLayananTap(layanan),
          );
        },
      ),
    );
  }
}

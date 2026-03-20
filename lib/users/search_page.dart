import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:home_care/users/layananPage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// ========================================
/// SEARCH PAGE - Pencarian Layanan + History
/// ========================================

class SearchPage extends StatefulWidget {
  const SearchPage({Key? key}) : super(key: key);

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  List<LayananSearchResult> _searchResults = [];
  List<SearchHistoryItem> _searchHistory = [];
  List<RecentViewedLayananItem> _recentViewedLayanan = [];

  bool _isLoading = false;
  bool _isLoadingHistory = false;
  bool _isLoadingRecentViewed = false;
  bool _hasSearched = false;

  static const String baseUrl = 'http://147.93.81.243/api';

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    _loadRecentViewedLayanan();
    _searchController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) {
      _debounce!.cancel();
    }

    _debounce = Timer(const Duration(milliseconds: 500), () {
      final keyword = query.trim();

      if (keyword.isEmpty) {
        setState(() {
          _searchResults = [];
          _hasSearched = false;
        });
        _loadSearchHistory();
        _loadRecentViewedLayanan();
        return;
      }

      _performSearch(keyword);
    });
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }

  Future<void> _performSearch(String keyword) async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    try {
      final token = await _getToken();

      final res = await http.get(
        Uri.parse('$baseUrl/layanan/search?q=${Uri.encodeComponent(keyword)}'),
        headers: {
          'Accept': 'application/json',
          if (token != null && token.isNotEmpty)
            'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final body = json.decode(res.body);

        if (body['success'] == true) {
          final List data = body['data'] ?? [];

          setState(() {
            _searchResults = data
                .map((e) => LayananSearchResult.fromJson(e))
                .toList();
            _isLoading = false;
          });

          await _loadSearchHistory();
        } else {
          setState(() {
            _searchResults = [];
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error searching: $e');
      setState(() {
        _searchResults = [];
        _isLoading = false;
      });
    }
  }

  Future<void> _loadSearchHistory() async {
    setState(() {
      _isLoadingHistory = true;
    });

    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        setState(() {
          _searchHistory = [];
          _isLoadingHistory = false;
        });
        return;
      }

      final res = await http.get(
        Uri.parse('$baseUrl/pasien/search-history'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final body = json.decode(res.body);

        if (body['success'] == true) {
          final List data = body['data'] ?? [];

          setState(() {
            _searchHistory = data
                .map((e) => SearchHistoryItem.fromJson(e))
                .toList();
            _isLoadingHistory = false;
          });
        } else {
          setState(() {
            _searchHistory = [];
            _isLoadingHistory = false;
          });
        }
      } else {
        setState(() {
          _searchHistory = [];
          _isLoadingHistory = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading search history: $e');
      setState(() {
        _searchHistory = [];
        _isLoadingHistory = false;
      });
    }
  }

  Future<void> _loadRecentViewedLayanan() async {
    setState(() {
      _isLoadingRecentViewed = true;
    });

    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) {
        setState(() {
          _recentViewedLayanan = [];
          _isLoadingRecentViewed = false;
        });
        return;
      }

      final res = await http.get(
        Uri.parse('$baseUrl/pasien/recent-viewed-layanan'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        final body = json.decode(res.body);

        if (body['success'] == true) {
          final List data = body['data'] ?? [];

          setState(() {
            _recentViewedLayanan = data
                .map((e) => RecentViewedLayananItem.fromJson(e))
                .toList();
            _isLoadingRecentViewed = false;
          });
        } else {
          setState(() {
            _recentViewedLayanan = [];
            _isLoadingRecentViewed = false;
          });
        }
      } else {
        setState(() {
          _recentViewedLayanan = [];
          _isLoadingRecentViewed = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading recent viewed layanan: $e');
      setState(() {
        _recentViewedLayanan = [];
        _isLoadingRecentViewed = false;
      });
    }
  }

  Future<void> _saveRecentViewedLayanan(int layananId) async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) return;

      final res = await http.post(
        Uri.parse('$baseUrl/pasien/recent-viewed-layanan'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'layanan_id': layananId}),
      );

      debugPrint('save recent viewed status: ${res.statusCode}');
      debugPrint('save recent viewed body: ${res.body}');
    } catch (e) {
      debugPrint('Error saving recent viewed layanan: $e');
    }
  }

  Future<void> _deleteHistory(int id) async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) return;

      final res = await http.delete(
        Uri.parse('$baseUrl/pasien/search-history/$id'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        await _loadSearchHistory();
      }
    } catch (e) {
      debugPrint('Error deleting history: $e');
    }
  }

  Future<void> _clearAllHistory() async {
    try {
      final token = await _getToken();

      if (token == null || token.isEmpty) return;

      final res = await http.delete(
        Uri.parse('$baseUrl/pasien/search-history'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (res.statusCode == 200) {
        setState(() {
          _searchHistory = [];
        });
      }
    } catch (e) {
      debugPrint('Error clearing history: $e');
    }
  }

  void _useHistoryKeyword(String keyword) {
    _searchController.text = keyword;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: keyword.length),
    );
    _performSearch(keyword);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _hasSearched = false;
    });
    _loadSearchHistory();
    _loadRecentViewedLayanan();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0BA5A7),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Cari Layanan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: const Color(0xFF0BA5A7),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                autofocus: true,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Cari layanan kesehatan...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF0BA5A7),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: _clearSearch,
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
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0BA5A7)),
      );
    }

    if (!_hasSearched) {
      return _buildInitialState();
    }

    if (_searchResults.isEmpty) {
      return _buildEmptyState();
    }

    return _buildResultsList();
  }

  Widget _buildInitialState() {
    if (_isLoadingHistory || _isLoadingRecentViewed) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF0BA5A7)),
      );
    }

    if (_searchHistory.isEmpty && _recentViewedLayanan.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'Cari layanan kesehatan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Ketik kata kunci untuk mulai mencari',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      children: [
        if (_searchHistory.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Pencarian Terakhir',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              TextButton(
                onPressed: _clearAllHistory,
                child: const Text(
                  'Hapus semua',
                  style: TextStyle(
                    color: Color(0xFF0BA5A7),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._searchHistory.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SearchHistoryTile(
                item: item,
                onTap: () => _useHistoryKeyword(item.keyword),
                onDelete: () => _deleteHistory(item.id),
              ),
            ),
          ),
          const SizedBox(height: 20),
        ],
        if (_recentViewedLayanan.isNotEmpty) ...[
          const Text(
            'Layanan Terakhir Dilihat',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          ..._recentViewedLayanan.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _RecentViewedLayananTile(item: item),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 80, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Tidak ada hasil',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba kata kunci lain',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsList() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _searchResults.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = _searchResults[index];
        return _LayananSearchCard(
          layanan: item,
          onTap: () async {
            await _saveRecentViewedLayanan(item.id);
            await _loadRecentViewedLayanan();

            if (!mounted) return;

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => PilihLayananPage(
                  kategori: item.kategori,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

/// ========================================
/// MODEL SEARCH RESULT
/// ========================================

class LayananSearchResult {
  final int id;
  final String kodeLayanan;
  final String namaLayanan;
  final String? deskripsi;
  final String? kategori;
  final String? tipeLayanan;
  final double hargaFix;
  final String? gambarUrl;

  LayananSearchResult({
    required this.id,
    required this.kodeLayanan,
    required this.namaLayanan,
    this.deskripsi,
    this.kategori,
    this.tipeLayanan,
    required this.hargaFix,
    this.gambarUrl,
  });

  factory LayananSearchResult.fromJson(Map<String, dynamic> json) {
    return LayananSearchResult(
      id: json['id'] ?? 0,
      kodeLayanan: json['kode_layanan']?.toString() ?? '',
      namaLayanan: json['nama_layanan']?.toString() ?? '',
      deskripsi: json['deskripsi']?.toString(),
      kategori: json['kategori']?.toString(),
      tipeLayanan: json['tipe_layanan']?.toString(),
      hargaFix: double.tryParse(json['harga_fix']?.toString() ?? '0') ?? 0,
      gambarUrl: json['gambar_url']?.toString(),
    );
  }
}

/// ========================================
/// MODEL HISTORY
/// ========================================

class SearchHistoryItem {
  final int id;
  final String keyword;
  final int searchCount;
  final String? lastSearchedAt;

  SearchHistoryItem({
    required this.id,
    required this.keyword,
    required this.searchCount,
    this.lastSearchedAt,
  });

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      id: json['id'] ?? 0,
      keyword: json['keyword']?.toString() ?? '',
      searchCount: json['search_count'] is int
          ? json['search_count']
          : int.tryParse(json['search_count']?.toString() ?? '0') ?? 0,
      lastSearchedAt: json['last_searched_at']?.toString(),
    );
  }
}

class RecentViewedLayananItem {
  final int id;
  final int layananId;
  final String namaLayanan;
  final String? kategori;
  final String? deskripsi;
  final double hargaFix;
  final String? gambarUrl;
  final int viewCount;
  final String? lastViewedAt;

  RecentViewedLayananItem({
    required this.id,
    required this.layananId,
    required this.namaLayanan,
    this.kategori,
    this.deskripsi,
    required this.hargaFix,
    this.gambarUrl,
    required this.viewCount,
    this.lastViewedAt,
  });

  factory RecentViewedLayananItem.fromJson(Map<String, dynamic> json) {
    return RecentViewedLayananItem(
      id: json['id'] ?? 0,
      layananId: json['layanan_id'] ?? 0,
      namaLayanan: json['nama_layanan']?.toString() ?? '',
      kategori: json['kategori']?.toString(),
      deskripsi: json['deskripsi']?.toString(),
      hargaFix: double.tryParse(json['harga_fix']?.toString() ?? '0') ?? 0,
      gambarUrl: json['gambar_url']?.toString(),
      viewCount: json['view_count'] ?? 0,
      lastViewedAt: json['last_viewed_at']?.toString(),
    );
  }
}

/// ========================================
/// HISTORY TILE
/// ========================================

class _SearchHistoryTile extends StatelessWidget {
  final SearchHistoryItem item;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _SearchHistoryTile({
    required this.item,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(Icons.history, color: Colors.grey.shade600, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.keyword,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 18),
                color: Colors.grey,
                onPressed: onDelete,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentViewedLayananTile extends StatelessWidget {
  final RecentViewedLayananItem item;

  const _RecentViewedLayananTile({required this.item});

  String _formatRupiah(double value) {
    final intValue = value.round();
    final reversed = intValue.toString().split('').reversed.join('');
    final chunks = <String>[];

    for (int i = 0; i < reversed.length; i += 3) {
      chunks.add(
        reversed.substring(
          i,
          i + 3 > reversed.length ? reversed.length : i + 3,
        ),
      );
    }

    return 'Rp ${chunks.join('.').split('').reversed.join('')}';
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PilihLayananPage(
                kategori: item.kategori,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: item.gambarUrl != null && item.gambarUrl!.isNotEmpty
                    ? Image.network(
                        item.gambarUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            Icons.medical_services,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey.shade200,
                        child: const Icon(
                          Icons.medical_services,
                          color: Colors.grey,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.namaLayanan,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.kategori != null && item.kategori!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.kategori!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      _formatRupiah(item.hargaFix),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0BA5A7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

/// ========================================
/// WIDGET CARD HASIL SEARCH
/// ========================================

class _LayananSearchCard extends StatelessWidget {
  final LayananSearchResult layanan;
  final VoidCallback onTap;

  const _LayananSearchCard({
    required this.layanan,
    required this.onTap,
  });

  String _formatRupiah(double value) {
    final intValue = value.round();
    final reversed = intValue.toString().split('').reversed.join('');
    final chunks = <String>[];

    for (int i = 0; i < reversed.length; i += 3) {
      chunks.add(
        reversed.substring(
          i,
          i + 3 > reversed.length ? reversed.length : i + 3,
        ),
      );
    }

    return 'Rp ${chunks.join('.').split('').reversed.join('')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            blurRadius: 4,
            offset: const Offset(0, 2),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: layanan.gambarUrl != null && layanan.gambarUrl!.isNotEmpty
                    ? Image.network(
                        layanan.gambarUrl!,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (layanan.kategori != null &&
                        layanan.kategori!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0BA5A7).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          layanan.kategori!,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0BA5A7),
                          ),
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      layanan.namaLayanan,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (layanan.deskripsi != null &&
                        layanan.deskripsi!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        layanan.deskripsi!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black.withOpacity(0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      _formatRupiah(layanan.hargaFix),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0BA5A7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 80,
      height: 80,
      color: Colors.grey.shade200,
      child: const Icon(Icons.medical_services, color: Colors.grey, size: 32),
    );
  }
}
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/widgets/patient_app_bar.dart';
import 'package:home_care/core/widgets/skeletons/skeletons.dart';
import 'package:home_care/users/layanan_page.dart';
import 'models/search_models.dart';
import 'services/user_search_service.dart';
import 'widgets/widgets.dart';

export 'models/search_models.dart';
export 'services/user_search_service.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  final UserSearchService _service = const UserSearchService();
  Timer? _debounce;

  List<LayananSearchResult> _searchResults = [];
  List<SearchHistoryItem> _searchHistory = [];
  List<RecentViewedLayananItem> _recentViewedLayanan = [];

  bool _isLoading = false;
  bool _isLoadingHistory = false;
  bool _isLoadingRecentViewed = false;
  bool _hasSearched = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    _loadSearchHistory();
    _loadRecentViewed();
  }

  Future<void> _loadSearchHistory() async {
    setState(() => _isLoadingHistory = true);
    final history = await _service.fetchSearchHistory();
    if (!mounted) return;
    setState(() {
      _searchHistory = history;
      _isLoadingHistory = false;
    });
  }

  Future<void> _loadRecentViewed() async {
    setState(() => _isLoadingRecentViewed = true);
    final recent = await _service.fetchRecentViewed();
    if (!mounted) return;
    setState(() {
      _recentViewedLayanan = recent;
      _isLoadingRecentViewed = false;
    });
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
        _loadInitialData();
        return;
      }
      _performSearch(keyword);
    });
  }

  Future<void> _performSearch(String keyword) async {
    setState(() {
      _isLoading = true;
      _hasSearched = true;
    });

    final results = await _service.searchLayanan(keyword);
    if (!mounted) return;
    setState(() {
      _searchResults = results;
      _isLoading = false;
    });
  }

  void _useHistoryKeyword(String keyword) {
    _searchController.text = keyword;
    _searchController.selection = TextSelection.fromPosition(
      TextPosition(offset: keyword.length),
    );
    _service.saveSearchHistory(keyword);
    _performSearch(keyword);
  }

  void _clearSearch() {
    _searchController.clear();
    setState(() {
      _searchResults = [];
      _hasSearched = false;
    });
    _loadInitialData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const PatientAppBar(title: 'Cari Layanan'),
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
                focusNode: _searchFocus,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: _onSearchChanged,
                onSubmitted: (value) {
                  final kw = value.trim();
                  if (kw.isNotEmpty) {
                    _debounce?.cancel();
                    _service.saveSearchHistory(kw);
                    _performSearch(kw);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'Cari layanan kesehatan...',
                  prefixIcon: const Icon(
                    IconlyLight.search,
                    color: Color(0xFF0BA5A7),
                  ),
                  suffixIcon: ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _searchController,
                    builder: (context, textValue, _) {
                      if (textValue.text.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return IconButton(
                        icon: const Icon(IconlyLight.closeSquare),
                        onPressed: _clearSearch,
                      );
                    },
                  ),
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
      return const SearchResultSkeleton();
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
      return const SearchResultSkeleton(itemCount: 4);
    }

    if (_searchHistory.isEmpty && _recentViewedLayanan.isEmpty) {
      return RefreshIndicator(
        onRefresh: _loadInitialData,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          children: [
            SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.45,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      IconlyLight.search,
                      size: 72,
                      color: Colors.grey.shade300,
                    ),
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
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade500,
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

    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
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
                  onPressed: () async {
                    await _service.clearAllHistory();
                    _loadSearchHistory();
                  },
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
            ..._searchHistory.take(5).map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: SearchHistoryTile(
                  item: item,
                  onTap: () => _useHistoryKeyword(item.keyword),
                  onDelete: () async {
                    await _service.deleteHistory(item.id);
                    _loadSearchHistory();
                  },
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
              (item) => RecentViewedCard(
                item: item,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PilihLayananPage(kategori: item.kategori),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return RefreshIndicator(
      onRefresh: () => _performSearch(_searchController.text.trim()),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          SizedBox(
            height: MediaQuery.sizeOf(context).height * 0.45,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    IconlyLight.search,
                    size: 72,
                    color: Colors.grey.shade300,
                  ),
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
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
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

  Widget _buildResultsList() {
    return RefreshIndicator(
      onRefresh: () => _performSearch(_searchController.text.trim()),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _searchResults.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = _searchResults[index];
          return LayananSearchCard(
            layanan: item,
            margin: EdgeInsets.zero,
            onTap: () async {
              final query = _searchController.text.trim();
              if (query.length >= 2) {
                _service.saveSearchHistory(query);
              }
              final nav = Navigator.of(context);
              await _service.saveRecentViewed(item.id);
              _loadRecentViewed();

              if (!mounted) return;
              nav.push(
                MaterialPageRoute(
                  builder: (_) => PilihLayananPage(kategori: item.kategori),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

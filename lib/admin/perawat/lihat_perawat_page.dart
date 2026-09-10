import 'package:flutter/material.dart';
import 'package:home_care/admin/perawat/services/perawat_admin_service.dart';
import 'package:home_care/admin/perawat/widgets/lihat_perawat_card.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/nurses/domain/nurse_model.dart';

class LihatPerawatPage extends StatefulWidget {
  const LihatPerawatPage({super.key});

  @override
  State<LihatPerawatPage> createState() => _LihatPerawatPageState();
}

class _LihatPerawatPageState extends State<LihatPerawatPage> {
  bool _isLoading = true;
  bool _isError = false;
  String? _errorMessage;

  List<PerawatModel> _list = [];
  final TextEditingController _searchC = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchPerawat();
  }

  @override
  void dispose() {
    _searchC.dispose();
    super.dispose();
  }

  Future<void> _fetchPerawat({String? search}) async {
    setState(() {
      _isLoading = true;
      _isError = false;
      _errorMessage = null;
    });

    try {
      final list = await PerawatAdminService.fetchPerawat(
        search: search,
      );

      if (mounted) {
        setState(() {
          _list = list;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isError = true;
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  void _onSearch() {
    _fetchPerawat(search: _searchC.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HCColor.bg,
      appBar: AppBar(
        backgroundColor: HCColor.primary,
        foregroundColor: Colors.white,
        title: const Text('Data Perawat'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchC,
                    decoration: InputDecoration(
                      hintText:
                          'Cari nama perawat / kode / koordinator / email...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    onSubmitted: (_) => _onSearch(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _onSearch,
                  icon: const Icon(Icons.search),
                  tooltip: 'Cari',
                ),
                IconButton(
                  onPressed: () {
                    _searchC.clear();
                    _fetchPerawat();
                  },
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Segarkan',
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => _fetchPerawat(search: _searchC.text),
              child: _buildBody(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_isError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Terjadi kesalahan saat memuat data.',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _fetchPerawat(search: _searchC.text),
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (_list.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: const [
          SizedBox(height: 80),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.people_outline, size: 56, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'Belum ada data perawat.',
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      itemCount: _list.length,
      itemBuilder: (ctx, i) {
        return LihatPerawatCard(perawat: _list[i]);
      },
    );
  }
}

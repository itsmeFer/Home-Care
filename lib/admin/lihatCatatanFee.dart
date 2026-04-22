import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:fl_chart/fl_chart.dart';

/* ===========================================================
   THEME (PUTIH)
=========================================================== */

const Color kBg = Color(0xFFF7F8FA);
const Color kCard = Colors.white;
const Color kBorder = Color(0xFFE5E7EB);
const Color kPrimary = Color(0xFF2563EB);
const Color kText = Color(0xFF111827);
const Color kTextSub = Color(0xFF6B7280);
const Color kDanger = Color(0xFFDC2626);
const Color kSuccess = Color(0xFF16A34A);

/* ===========================================================
   CONFIG
=========================================================== */

/// Base URL tanpa /api
const String kBaseUrl = 'http://192.168.1.5:8000';

String get apiBaseUrl => '$kBaseUrl/api';

/* ===========================================================
   MODEL DATA
=========================================================== */

class FeeTimelinePoint {
  final DateTime date;
  final double amount;

  FeeTimelinePoint({required this.date, required this.amount});
}

class FeeByLayanan {
  final int layananId;
  final String layananNama;
  final double totalFee;

  FeeByLayanan({
    required this.layananId,
    required this.layananNama,
    required this.totalFee,
  });
}

class LeaderboardItem {
  final int userId;
  final String nama;
  final double totalFee;

  LeaderboardItem({
    required this.userId,
    required this.nama,
    required this.totalFee,
  });
}

class SimpleUserOption {
  final int id;
  final String name;
  final String? email;
  final String? role;

  SimpleUserOption({
    required this.id,
    required this.name,
    this.email,
    this.role,
  });
}

/* ===========================================================
   HELPER FORMAT
=========================================================== */

String formatRupiah(num value) {
  final s = value.toStringAsFixed(0);
  final buffer = StringBuffer();
  int count = 0;
  for (int i = s.length - 1; i >= 0; i--) {
    buffer.write(s[i]);
    count++;
    if (count == 3 && i != 0) {
      buffer.write('.');
      count = 0;
    }
  }
  final result = buffer.toString().split('').reversed.join();
  return 'Rp $result';
}

/* ===========================================================
   PAGE: ADMIN LIHAT CATATAN FEE USER
=========================================================== */

class LihatCatatanFeePage extends StatefulWidget {
  const LihatCatatanFeePage({Key? key}) : super(key: key);

  @override
  State<LihatCatatanFeePage> createState() => _LihatCatatanFeePageState();
}

class _LihatCatatanFeePageState extends State<LihatCatatanFeePage> {
  // user yang dipilih admin
  SimpleUserOption? _selectedUser;

  // list hasil search user
  List<SimpleUserOption> _userSearchResults = [];
  String _userSearchQuery = '';
  bool _isSearchingUser = false;

  // filter fee
  String _selectedRange = '30_hari_terakhir';
  String _selectedStatus = 'semua';
  int? _selectedLayananId; // null = semua

  // data fee
  bool _isLoadingData = false;
  String? _errorMessage;

  double _totalSemuaLayanan = 0;
  List<FeeByLayanan> _byLayanan = [];
  List<FeeTimelinePoint> _timeline = [];
  List<LeaderboardItem> _leaderboard = [];

  final TextEditingController _userSearchController = TextEditingController();

  @override
  void dispose() {
    _userSearchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // auto load daftar user pertama kali
    _searchUsers();
  }

  /* ===========================================================
     API: SEARCH USER
  ============================================================ */

  Future<void> _searchUsers() async {
    setState(() {
      _isSearchingUser = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // ❗ pakai key yang sama dengan halaman lain
      final token = prefs.getString('auth_token');
      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login ulang.');
      }

      final uri = Uri.parse(
        '$apiBaseUrl/admin/fee/searchable-users?per_page=20&search=${Uri.encodeQueryComponent(_userSearchQuery)}',
      );

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        debugPrint('searchable-users status: ${response.statusCode}');
        debugPrint('body: ${response.body}');
        throw Exception(
          'Gagal memuat daftar user (code ${response.statusCode}).',
        );
      }

      final jsonRes = jsonDecode(response.body);
      if (jsonRes is! Map || jsonRes['success'] != true) {
        throw Exception(jsonRes['message'] ?? 'Response tidak valid.');
      }

      final data = jsonRes['data'] ?? {};
      final list = (data['data'] ?? []) as List;

      _userSearchResults = list.map((e) {
        return SimpleUserOption(
          id: e['id'] ?? 0,
          name: e['display_name'] ?? e['name'] ?? 'User',
          email: e['email']?.toString(),
          role: e['role']?.toString(),
        );
      }).toList();

      // 🔥 AUTO PILIH USER PERTAMA (TERBARU) KALAU BELUM ADA YANG TERPILIH
      if (_selectedUser == null && _userSearchResults.isNotEmpty) {
        _selectedUser = _userSearchResults.first;
        _selectedLayananId = null;
        await _loadFeeData();
      }
    } catch (e) {
      debugPrint('Error search users: $e');
    }

    setState(() {
      _isSearchingUser = false;
    });
  }

  /* ===========================================================
     API: LOAD DATA FEE UNTUK USER TERPILIH
  ============================================================ */

  Future<void> _loadFeeData() async {
    if (_selectedUser == null) return;

    setState(() {
      _isLoadingData = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      // ❗ sama: pakai 'auth_token'
      final token = prefs.getString('auth_token');
      if (token == null) {
        throw Exception('Token tidak ditemukan. Silakan login ulang.');
      }

      final params = <String, String>{
        'user_id': _selectedUser!.id.toString(),
        'range': _selectedRange,
        'status': _selectedStatus,
      };

      if (_selectedLayananId != null) {
        params['layanan_id'] = _selectedLayananId.toString();
      }

      final uri = Uri.parse(
        '$apiBaseUrl/admin/fee/catatan-user',
      ).replace(queryParameters: params);

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        debugPrint('catatan-user status: ${response.statusCode}');
        debugPrint('body: ${response.body}');
        throw Exception(
          'Gagal memuat catatan fee (code ${response.statusCode}).',
        );
      }

      final jsonRes = jsonDecode(response.body);
      if (jsonRes is! Map || jsonRes['success'] != true) {
        throw Exception(jsonRes['message'] ?? 'Response tidak valid.');
      }

      final data = jsonRes['data'] ?? {};

      // total semua
      _totalSemuaLayanan = (data['total_semua_layanan'] ?? 0).toDouble();

      // per layanan
      final byLayananRaw = (data['total_per_layanan'] ?? []) as List;
      _byLayanan = byLayananRaw.map((e) {
        return FeeByLayanan(
          layananId: e['layanan_id'] ?? 0,
          layananNama: e['layanan_nama'] ?? '-',
          totalFee: (e['total_fee'] ?? 0).toDouble(),
        );
      }).toList();

      // timeline
      final timelineRaw = (data['timeline'] ?? []) as List;
      _timeline = timelineRaw.map((e) {
        final tanggalStr = e['tanggal'] ?? '';
        DateTime date;
        try {
          date = DateTime.parse(tanggalStr);
        } catch (_) {
          date = DateTime.now();
        }
        return FeeTimelinePoint(
          date: date,
          amount: (e['total_fee'] ?? 0).toDouble(),
        );
      }).toList();

      // leaderboard
      final leaderboardRaw = (data['leaderboard'] ?? []) as List;
      _leaderboard = leaderboardRaw.map((e) {
        return LeaderboardItem(
          userId: e['user_id'] ?? 0,
          nama: e['nama'] ?? '-',
          totalFee: (e['total_fee'] ?? 0).toDouble(),
        );
      }).toList();
    } catch (e) {
      _errorMessage = e.toString();
    }

    setState(() {
      _isLoadingData = false;
    });
  }

  FeeByLayanan? get _selectedLayanan {
    if (_selectedLayananId == null) return null;
    if (_byLayanan.isEmpty) return null;
    return _byLayanan.firstWhere(
      (e) => e.layananId == _selectedLayananId,
      orElse: () => _byLayanan.first,
    );
  }

  /* ===========================================================
     BUILD
  ============================================================ */

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        iconTheme: const IconThemeData(color: kText),
        title: const Text(
          'Catatan Fee User (Admin)',
          style: TextStyle(
            color: kText,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          if (_selectedUser != null) {
            await _loadFeeData();
          } else {
            await _searchUsers();
          }
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildUserPickerCard(),
            const SizedBox(height: 12),
            if (_selectedUser != null) _buildFilterRow(),
            const SizedBox(height: 12),
            if (_selectedUser != null)
              _buildMainContent()
            else
              _buildEmptyState(),
          ],
        ),
      ),
    );
  }

  /* ===========================================================
     USER PICKER (ADMIN PILIH USER)
  ============================================================ */

  Widget _buildUserPickerCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih User Penerima Fee',
            style: TextStyle(
              color: kText,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Admin bisa mencari dan memilih user, lalu melihat catatan fee yang diterima user tersebut.',
            style: TextStyle(
              color: kTextSub,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _userSearchController,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Cari nama / email user...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: kBorder),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onChanged: (value) {
                    _userSearchQuery = value;
                  },
                  onSubmitted: (_) {
                    _searchUsers();
                  },
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: _isSearchingUser ? null : _searchUsers,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isSearchingUser
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Cari',
                          style: TextStyle(fontSize: 13),
                        ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_isSearchingUser)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            _buildUserSearchResultList(),
          if (_selectedUser != null) ...[
            const Divider(height: 16),
            _buildSelectedUserInfo(),
          ],
        ],
      ),
    );
  }

  Widget _buildUserSearchResultList() {
    if (_userSearchResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 6),
        child: Text(
          'Tidak ada hasil. Coba kata kunci lain.',
          style: TextStyle(
            color: kTextSub,
            fontSize: 12,
          ),
        ),
      );
    }

    return Column(
      children: _userSearchResults.map((u) {
        final selected = _selectedUser?.id == u.id;
        return InkWell(
          onTap: () async {
            setState(() {
              _selectedUser = u;
              _selectedLayananId = null; // reset filter layanan
            });
            await _loadFeeData();
          },
          child: Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? kBg : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? kPrimary.withOpacity(0.6) : kBorder,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: kPrimary.withOpacity(0.1),
                  child: Text(
                    u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: kPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.name,
                        style: const TextStyle(
                          color: kText,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (u.email != null)
                        Text(
                          u.email!,
                          style: const TextStyle(
                            color: kTextSub,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                if (u.role != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: kBg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      u.role!,
                      style: const TextStyle(
                        color: kTextSub,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectedUserInfo() {
    final u = _selectedUser!;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 18, color: kPrimary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Sedang melihat catatan fee untuk: ${u.name}${u.email != null ? ' (${u.email})' : ''}',
            style: const TextStyle(
              color: kTextSub,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  /* ===========================================================
     MAIN CONTENT
  ============================================================ */

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: const Text(
        'Pilih user terlebih dahulu untuk melihat catatan fee.',
        style: TextStyle(
          color: kTextSub,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _buildMainContent() {
    if (_isLoadingData) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kDanger.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gagal memuat catatan fee',
              style: TextStyle(
                color: kDanger,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: kTextSub,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: _loadFeeData,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Coba lagi'),
                style: TextButton.styleFrom(
                  foregroundColor: kPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 16),
        _buildLineChartCard(),
        const SizedBox(height: 16),
        _buildPieChartCard(),
        const SizedBox(height: 16),
        _buildLeaderboardCard(),
      ],
    );
  }

  /* ===========================================================
     FILTER ROW (RANGE, STATUS, LAYANAN)
  ============================================================ */

  Widget _buildFilterRow() {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: _buildRangeDropdown(),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: _buildStatusDropdown(),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 1,
          child: _buildLayananDropdown(),
        ),
      ],
    );
  }

  Widget _buildRangeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedRange,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedRange = value;
            });
            _loadFeeData();
          },
          items: const [
            DropdownMenuItem(
              value: '7_hari_terakhir',
              child: Text('7 Hari'),
            ),
            DropdownMenuItem(
              value: '30_hari_terakhir',
              child: Text('30 Hari'),
            ),
            DropdownMenuItem(
              value: 'semua',
              child: Text('Semua'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedStatus,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          onChanged: (value) {
            if (value == null) return;
            setState(() {
              _selectedStatus = value;
            });
            _loadFeeData();
          },
          items: const [
            DropdownMenuItem(
              value: 'semua',
              child: Text('Semua Status'),
            ),
            DropdownMenuItem(
              value: 'pending',
              child: Text('Pending'),
            ),
            DropdownMenuItem(
              value: 'siap_dibayar',
              child: Text('Siap Dibayar'),
            ),
            DropdownMenuItem(
              value: 'dibayar',
              child: Text('Dibayar'),
            ),
            DropdownMenuItem(
              value: 'batal',
              child: Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayananDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: kBorder),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: _selectedLayananId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          onChanged: (value) {
            setState(() {
              _selectedLayananId = value;
            });
            _loadFeeData();
          },
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Semua Layanan'),
            ),
            ..._byLayanan.map(
              (l) => DropdownMenuItem<int?>(
                value: l.layananId,
                child: Text(l.layananNama),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /* ===========================================================
     SUMMARY CARD
  ============================================================ */

  Widget _buildSummaryCard() {
    final selected = _selectedLayanan;
    final totalSelected = selected?.totalFee ?? _totalSemuaLayanan;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            selected == null
                ? 'Total Fee Diterima (Semua Layanan)'
                : 'Total Fee Diterima dari ${selected.layananNama}',
            style: const TextStyle(
              color: kTextSub,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatRupiah(totalSelected),
            style: const TextStyle(
              color: kText,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                Icons.check_circle,
                color: kSuccess,
                size: 18,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  selected == null
                      ? 'Akumulasi semua fee yang diterima user pada periode & status ini.'
                      : 'Akumulasi fee hanya dari layanan ini pada periode & status ini.',
                  style: const TextStyle(
                    color: kTextSub,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /* ===========================================================
     GRAFIK GUNUNG (LINE/AREA)
  ============================================================ */

  Widget _buildLineChartCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pergerakan Fee (Timeline)',
            style: TextStyle(
              color: kText,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Grafik fee diterima per tanggal selesai order.',
            style: TextStyle(
              color: kTextSub,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: _timeline.isEmpty
                ? const Center(
                    child: Text(
                      'Belum ada data timeline.',
                      style: TextStyle(color: kTextSub, fontSize: 12),
                    ),
                  )
                : LineChart(_buildLineChartData()),
          ),
        ],
      ),
    );
  }

  LineChartData _buildLineChartData() {
    final spots = <FlSpot>[];
    _timeline.asMap().forEach((index, point) {
      spots.add(FlSpot(index.toDouble(), point.amount));
    });

    double maxY = 0;
    for (final s in spots) {
      if (s.y > maxY) maxY = s.y;
    }

    return LineChartData(
      gridData: FlGridData(
        show: true,
        horizontalInterval: maxY == 0 ? 1 : maxY / 4,
        drawVerticalLine: false,
      ),
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (_timeline.length / 4).clamp(1, 999).toDouble(),
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= _timeline.length) {
                return const SizedBox.shrink();
              }
              final date = _timeline[index].date;
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '${date.day}/${date.month}',
                  style: const TextStyle(
                    color: kTextSub,
                    fontSize: 10,
                  ),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 38,
            getTitlesWidget: (value, meta) {
              if (value <= 0) return const SizedBox.shrink();
              return Text(
                (value / 1000).toStringAsFixed(0) + 'k',
                style: const TextStyle(
                  color: kTextSub,
                  fontSize: 10,
                ),
              );
            },
          ),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: kBorder),
      ),
      minX: 0,
      maxX: spots.isEmpty ? 0 : spots.length.toDouble() - 1,
      minY: 0,
      maxY: maxY == 0 ? 1 : maxY * 1.2,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: kPrimary,
          barWidth: 2.8,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                kPrimary.withOpacity(0.25),
                kPrimary.withOpacity(0.03),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }

  /* ===========================================================
     PIE CHART
  ============================================================ */

  Widget _buildPieChartCard() {
    final totalAll = _byLayanan.fold<double>(
      0,
      (prev, item) => prev + item.totalFee,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Distribusi Fee per Layanan',
            style: TextStyle(
              color: kText,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Komposisi fee yang diterima user berdasarkan layanan.',
            style: TextStyle(
              color: kTextSub,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          if (_byLayanan.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Belum ada data fee per layanan.',
                  style: TextStyle(
                    color: kTextSub,
                    fontSize: 12,
                  ),
                ),
              ),
            )
          else
            Row(
              children: [
                SizedBox(
                  width: 180,
                  height: 180,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: _buildPieSections(totalAll),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _byLayanan.map((l) {
                        final percentage =
                            totalAll == 0 ? 0 : (l.totalFee / totalAll * 100);
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: _colorForLayanan(l.layananId),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  l.layananNama,
                                  style: const TextStyle(
                                    color: kText,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${percentage.toStringAsFixed(1)}%',
                                style: const TextStyle(
                                  color: kTextSub,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  List<PieChartSectionData> _buildPieSections(double total) {
    final list = <PieChartSectionData>[];

    for (final item in _byLayanan) {
      final value = item.totalFee;
      if (value <= 0) continue;

      final percentage = total == 0 ? 0 : (value / total * 100);
      list.add(
        PieChartSectionData(
          value: value,
          title: '${percentage.toStringAsFixed(0)}%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          color: _colorForLayanan(item.layananId),
        ),
      );
    }

    if (list.isEmpty) {
      list.add(
        PieChartSectionData(
          value: 1,
          title: '0%',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
          color: kBorder,
        ),
      );
    }

    return list;
  }

  Color _colorForLayanan(int layananId) {
    const colors = [
      Color(0xFF2563EB),
      Color(0xFF10B981),
      Color(0xFFF59E0B),
      Color(0xFFEC4899),
      Color(0xFF6366F1),
      Color(0xFF14B8A6),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
    ];
    if (layananId <= 0) return colors[0];
    return colors[layananId % colors.length];
  }

  /* ===========================================================
     LEADERBOARD
  ============================================================ */

  Widget _buildLeaderboardCard() {
    if (_leaderboard.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: kCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: kBorder),
        ),
        child: const Text(
          'Belum ada leaderboard penerima fee pada filter ini.',
          style: TextStyle(
            color: kTextSub,
            fontSize: 12,
          ),
        ),
      );
    }

    final top3 = _leaderboard.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Leaderboard Penerima Fee (Global)',
            style: TextStyle(
              color: kText,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Top penerima fee terbesar pada periode & filter yang sama.',
            style: TextStyle(
              color: kTextSub,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          ...top3.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            final isCurrent =
                _selectedUser != null && _selectedUser!.id == item.userId;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding:
                  const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                color: isCurrent ? kPrimary.withOpacity(0.07) : kBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCurrent
                      ? kPrimary.withOpacity(0.5)
                      : Colors.transparent,
                ),
              ),
              child: Row(
                children: [
                  _buildRankBadge(index + 1),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.nama,
                      style: TextStyle(
                        color: kText,
                        fontSize: 13,
                        fontWeight:
                            isCurrent ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formatRupiah(item.totalFee),
                    style: const TextStyle(
                      color: kText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRankBadge(int rank) {
    Color bg;
    Color textColor = Colors.white;

    switch (rank) {
      case 1:
        bg = const Color(0xFFFACC15);
        break;
      case 2:
        bg = const Color(0xFFE5E7EB);
        textColor = kText;
        break;
      case 3:
        bg = const Color(0xFF9CA3AF);
        break;
      default:
        bg = kBorder;
        textColor = kText;
    }

    return Container(
      width: 28,
      height: 28,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
      ),
      child: Text(
        '$rank',
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 13,
        ),
      ),
    );
  }
}

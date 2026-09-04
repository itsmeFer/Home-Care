import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/orders/domain/order_models.dart';
import 'package:home_care/perawat/lihat_detail_orderan_masuk.dart';

export 'package:home_care/features/orders/domain/order_models.dart';

String get kBaseUrl => ApiConstants.apiBase;

class LihatOrderanMasukPerawatPage extends StatefulWidget {
  const LihatOrderanMasukPerawatPage({super.key});

  @override
  State<LihatOrderanMasukPerawatPage> createState() =>
      _LihatOrderanMasukPerawatPageState();
}

class _LihatOrderanMasukPerawatPageState
    extends State<LihatOrderanMasukPerawatPage> {
  bool _isLoading = true;
  String? _error;
  List<OrderLayananPerawat> _orders = [];

  String? _selectedStatus;
  final TextEditingController _searchController = TextEditingController();
  DateTime? _tanggalDari;
  DateTime? _tanggalSampai;

  Timer? _debounceTimer;

  final List<String> _statusOptions = const [
    'pending',
    'menunggu_penugasan',
    'mendapatkan_perawat',
    'sedang_dalam_perjalanan',
    'sampai_ditempat',
    'sedang_berjalan',
    'selesai',
    'dibatalkan',
  ];

  @override
  void initState() {
    super.initState();
    _fetchOrders();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {});
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _fetchOrders();
      }
    });
  }

  Future<void> _fetchOrders() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final Map<String, dynamic> queryParams = {};

      if (_selectedStatus != null && _selectedStatus!.isNotEmpty) {
        queryParams['status'] = _selectedStatus!;
      }

      final keyword = _searchController.text.trim();
      if (keyword.isNotEmpty) {
        queryParams['search'] = keyword;
      }

      if (_tanggalDari != null) {
        queryParams['tanggal_mulai_dari'] =
            DateFormat('yyyy-MM-dd').format(_tanggalDari!);
      }
      if (_tanggalSampai != null) {
        queryParams['tanggal_mulai_sampai'] =
            DateFormat('yyyy-MM-dd').format(_tanggalSampai!);
      }

      final res = await ApiClient.get(
        '/perawat/order-layanan',
        queryParams: queryParams.isEmpty ? null : queryParams,
      );

      if (!mounted) return;

      if (res is Map && res['data'] is List) {
        final List list = res['data'] as List;
        setState(() {
          _orders = list
              .map((e) => OrderLayananPerawat.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _orders = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  String _formatTanggal(String? iso) {
    if (iso == null || iso.isEmpty) return '-';
    try {
      final date = DateTime.parse(iso);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (_) {
      return iso;
    }
  }

  String _formatJam(String? jam) {
    if (jam == null || jam.isEmpty) return '-';
    if (jam.length >= 5) return jam.substring(0, 5);
    return jam;
  }

  String _getNama(Map<String, dynamic>? obj) {
    if (obj == null) return '-';
    return obj['nama_lengkap']?.toString() ??
        obj['nama']?.toString() ??
        obj['full_name']?.toString() ??
        '-';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'menunggu_penugasan':
        return Colors.deepOrange;
      case 'mendapatkan_perawat':
        return Colors.blue;
      case 'sedang_dalam_perjalanan':
        return Colors.teal;
      case 'sampai_ditempat':
        return Colors.indigo;
      case 'sedang_berjalan':
        return Colors.purple;
      case 'selesai':
        return Colors.green;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'Menunggu Konfirmasi';
      case 'menunggu_penugasan':
        return 'Menunggu Penugasan';
      case 'mendapatkan_perawat':
        return 'Menunggu Respon';
      case 'sedang_dalam_perjalanan':
        return 'Dalam Perjalanan';
      case 'sampai_ditempat':
        return 'Sudah Sampai';
      case 'sedang_berjalan':
        return 'Sedang Berjalan';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status;
    }
  }

  String _tanggalFilterLabel() {
    if (_tanggalDari == null && _tanggalSampai == null) {
      return 'Semua tanggal';
    }
    final fmt = DateFormat('dd MMM yyyy');
    if (_tanggalDari != null && _tanggalSampai != null) {
      return '${fmt.format(_tanggalDari!)} - ${fmt.format(_tanggalSampai!)}';
    }
    if (_tanggalDari != null) {
      return 'Mulai ${fmt.format(_tanggalDari!)}';
    }
    return 'Sampai ${fmt.format(_tanggalSampai!)}';
  }

  Future<void> _pickTanggalRange() async {
    final now = DateTime.now();
    final initialStart = _tanggalDari ?? now.subtract(const Duration(days: 7));
    final initialEnd = _tanggalSampai ?? now;

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
      helpText: 'Pilih rentang tanggal order',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: HCColor.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _tanggalDari = picked.start;
        _tanggalSampai = picked.end;
      });
      _fetchOrders();
    }
  }

  void _clearTanggalFilter() {
    setState(() {
      _tanggalDari = null;
      _tanggalSampai = null;
    });
    _fetchOrders();
  }

  void _clearSearch() {
    _searchController.clear();

  }

  int get _totalAktif =>
      _orders
          .where(
            (e) =>
                e.statusOrder == 'mendapatkan_perawat' ||
                e.statusOrder == 'sedang_dalam_perjalanan' ||
                e.statusOrder == 'sampai_ditempat' ||
                e.statusOrder == 'sedang_berjalan',
          )
          .length;

  int get _totalSelesai =>
      _orders.where((e) => e.statusOrder == 'selesai').length;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final horizontalPadding = size.width >= 900 ? 28.0 : 16.0;

    return Scaffold(
      backgroundColor: HCColor.bg,
      appBar: AppBar(
        title: const Text('Orderan Masuk'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _fetchOrders,
        color: HCColor.primary,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            16,
            horizontalPadding,
            20,
          ),
          children: [
            _buildStatsSection(),
            const SizedBox(height: 14),
            _buildFilterSection(),
            const SizedBox(height: 14),
            _buildBody(),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 640;

        final cards = [
          _MiniStatCard(
            title: 'Orderan Aktif',
            value: _totalAktif.toString(),
            icon: Icons.assignment_turned_in_outlined,
            color: Colors.blue,
          ),
          _MiniStatCard(
            title: 'Selesai',
            value: _totalSelesai.toString(),
            icon: Icons.check_circle_outline,
            color: Colors.green,
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                Expanded(child: cards[i]),
                if (i != cards.length - 1) const SizedBox(width: 12),
              ],
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ],
        );
      },
    );
  }

  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 760;

          final searchField = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  isDense: true,
                  prefixIcon: const Icon(Icons.search, color: HCColor.primary),
                  suffixIcon:
                      _isLoading && _searchController.text.isNotEmpty
                          ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: HCColor.primary,
                              ),
                            ),
                          )
                          : _searchController.text.isNotEmpty
                          ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: _clearSearch,
                            tooltip: 'Hapus pencarian',
                          )
                          : null,
                  filled: true,
                  fillColor: HCColor.lightTeal.withOpacity(0.3),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                      color: HCColor.primary,
                      width: 2,
                    ),
                  ),
                  hintText: 'Ketik untuk mencari...',
                  hintStyle: TextStyle(color: HCColor.textMuted, fontSize: 13),
                ),
              ),
              if (_searchController.text.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 12),
                  child: Text(
                    'Mencari: "${_searchController.text}"',
                    style: const TextStyle(
                      fontSize: 11,
                      color: HCColor.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          );

          final dateButton = OutlinedButton.icon(
            onPressed: _pickTanggalRange,
            icon: const Icon(Icons.calendar_today, size: 18),
            label: Text(_tanggalFilterLabel(), overflow: TextOverflow.ellipsis),
            style: OutlinedButton.styleFrom(
              foregroundColor: HCColor.primary,
              side: BorderSide(color: HCColor.primary.withOpacity(0.3)),
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );

          final statusDropdown = DropdownButtonFormField<String>(
            value: _selectedStatus,
            isExpanded: true,
            decoration: InputDecoration(
              filled: true,
              fillColor: HCColor.lightTeal.withOpacity(0.3),
              isDense: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 14,
              ),
            ),
            hint: const Text('Semua status'),
            items: [
              const DropdownMenuItem<String>(
                value: null,
                child: Text('Semua status'),
              ),
              ..._statusOptions.map(
                (s) => DropdownMenuItem<String>(
                  value: s,
                  child: Text(_statusLabel(s)),
                ),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedStatus = value;
              });
              _fetchOrders();
            },
          );

          if (isWide) {
            return Column(
              children: [
                Row(
                  children: [
                    Expanded(flex: 2, child: searchField),
                    const SizedBox(width: 12),
                    Expanded(child: dateButton),
                    if (_tanggalDari != null || _tanggalSampai != null) ...[
                      const SizedBox(width: 8),
                      IconButton(
                        tooltip: 'Hapus filter tanggal',
                        onPressed: _clearTanggalFilter,
                        icon: const Icon(Icons.close),
                        color: Colors.red,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: statusDropdown),
                    const SizedBox(width: 10),
                    SizedBox(
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _fetchOrders,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: HCColor.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            );
          }

          return Column(
            children: [
              searchField,
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: dateButton),
                  if (_tanggalDari != null || _tanggalSampai != null)
                    IconButton(
                      tooltip: 'Hapus filter tanggal',
                      onPressed: _clearTanggalFilter,
                      icon: const Icon(Icons.close),
                      color: Colors.red,
                    ),
                ],
              ),
              const SizedBox(height: 10),
              statusDropdown,
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  onPressed: _fetchOrders,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh Data'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HCColor.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 60),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircularProgressIndicator(color: HCColor.primary),
            SizedBox(height: 16),
            Text(
              'Memuat data orderan...',
              style: TextStyle(color: HCColor.textMuted),
            ),
          ],
        ),
      );
    }

    if (_error != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent, size: 48),
            const SizedBox(height: 12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _fetchOrders,
              icon: const Icon(Icons.refresh),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: HCColor.primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
          ],
        ),
      );
    }

    if (_orders.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'Belum ada orderan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Orderan yang ditugaskan ke Anda akan muncul di sini',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: HCColor.textMuted),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isGrid = constraints.maxWidth >= 900;

        if (isGrid) {
          return GridView.builder(
            itemCount: _orders.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.5,
            ),
            itemBuilder: (context, index) {
              return _buildOrderCard(_orders[index]);
            },
          );
        }

        return ListView.builder(
          itemCount: _orders.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildOrderCard(_orders[index]),
            );
          },
        );
      },
    );
  }

  Widget _buildOrderCard(OrderLayananPerawat order) {
    final tanggal = _formatTanggal(order.tanggalMulai);
    final jam = _formatJam(order.jamMulai);
    final pasienNama = _getNama(order.pasien);
    final koordinatorNama = _getNama(order.koordinator);
    final statusColor = _statusColor(order.statusOrder);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          final needRefresh = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => DetailOrderanMasukPerawatPage(orderId: order.id),
            ),
          );
          if (needRefresh == true) {
            _fetchOrders();
          }
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.kodeOrder,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      _statusLabel(order.statusOrder),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                order.namaLayanan,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 14,
                runSpacing: 8,
                children: [
                  _metaChip(Icons.calendar_today_outlined, tanggal),
                  _metaChip(Icons.access_time_outlined, jam),
                ],
              ),
              const SizedBox(height: 14),
              Container(height: 1, color: Colors.black.withOpacity(0.06)),
              const SizedBox(height: 12),
              _buildInfoRow('Pasien', pasienNama),
              const SizedBox(height: 6),
              _buildInfoRow('Koordinator', koordinatorNama),
            ],
          ),
        ),
      ),
    );
  }

  Widget _metaChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: HCColor.lightTeal.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: HCColor.primary),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(': ', style: TextStyle(fontSize: 12, color: Colors.grey)),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13.5,
              color: Colors.black87,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MiniStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _MiniStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
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

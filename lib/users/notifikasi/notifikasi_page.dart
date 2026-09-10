import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:intl/intl.dart';
import 'package:home_care/core/widgets/patient_app_bar.dart';
import 'package:home_care/core/widgets/skeletons/skeletons.dart';
import 'models/notifikasi_model.dart';
import 'services/notifikasi_service.dart';
import 'widgets/notifikasi_card.dart';
import 'widgets/notifikasi_detail_sheet.dart';
import 'widgets/notifikasi_summary_card.dart';

export 'models/notifikasi_model.dart';
export 'services/notifikasi_service.dart';

class NotifikasiPage extends StatefulWidget {
  const NotifikasiPage({super.key});

  @override
  State<NotifikasiPage> createState() => _NotifikasiPageState();
}

class _NotifikasiPageState extends State<NotifikasiPage> {
  final NotifikasiService _service = const NotifikasiService();
  bool _isLoading = true;
  bool _isMarkingAll = false;
  String? _error;
  List<AppNotificationItem> _items = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _service.fetchNotifications();
      if (!mounted) return;
      setState(() {
        _items = items;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Gagal memuat notifikasi: $e';
      });
    }
  }

  Future<void> _markAsRead(int id) async {
    final success = await _service.markAsRead(id);
    if (!success) return;

    if (!mounted) return;
    setState(() {
      final idx = _items.indexWhere((e) => e.id == id);
      if (idx != -1) {
        _items[idx] = _items[idx].copyWith(isRead: true);
      }
    });
  }

  Future<void> _markAllAsRead() async {
    if (_isMarkingAll) return;
    setState(() => _isMarkingAll = true);

    try {
      final success = await _service.markAllAsRead();
      if (!mounted) return;

      if (success) {
        setState(() {
          _items = _items.map((e) => e.copyWith(isRead: true)).toList();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Semua notifikasi ditandai sudah dibaca.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menandai semua notifikasi.')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Terjadi kesalahan: $e')));
    } finally {
      if (mounted) {
        setState(() => _isMarkingAll = false);
      }
    }
  }

  int get _unreadCount => _items.where((e) => !e.isRead).length;

  String _formatDate(DateTime? dt) {
    if (dt == null) return '-';
    return DateFormat('dd MMM yyyy • HH:mm', 'id_ID').format(dt.toLocal());
  }

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '-';
    final now = DateTime.now();
    final diff = now.difference(dt.toLocal());
    if (diff.inMinutes < 1) return 'Baru saja';
    if (diff.inHours < 1) return '${diff.inMinutes} menit lalu';
    if (diff.inDays < 1) return '${diff.inHours} jam lalu';
    if (diff.inDays < 7) return '${diff.inDays} hari lalu';
    return DateFormat('dd MMM yyyy', 'id_ID').format(dt.toLocal());
  }

  static IconData iconForType(String type) {
    switch (type) {
      case 'chat_message':
        return IconlyLight.chat;
      case 'new_order':
      case 'assigned_to_order':
      case 'order_created':
        return IconlyLight.document;
      case 'payment_success':
        return IconlyLight.wallet;
      case 'payment_failed':
      case 'payment_expired':
      case 'order_cancelled':
        return IconlyLight.dangerCircle;
      case 'perawat_assigned':
      case 'koordinator_assigned':
        return IconlyLight.profile;
      default:
        return IconlyLight.notification;
    }
  }

  static Color colorForType(String type) {
    switch (type) {
      case 'chat_message':
        return const Color(0xFF0EA5A4);
      case 'new_order':
      case 'assigned_to_order':
      case 'order_created':
        return const Color(0xFFF59E0B);
      case 'payment_success':
        return const Color(0xFF22C55E);
      case 'payment_failed':
      case 'payment_expired':
      case 'order_cancelled':
        return const Color(0xFFEF4444);
      case 'perawat_assigned':
      case 'koordinator_assigned':
        return const Color(0xFF6366F1);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = _unreadCount > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PatientAppBar(
        title: 'Notifikasi',
        actions: [
          if (!_isLoading && _items.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: TextButton(
                onPressed:
                    (!hasUnread || _isMarkingAll) ? null : _markAllAsRead,
                style: TextButton.styleFrom(
                  backgroundColor:
                      hasUnread
                          ? Colors.white.withValues(alpha: 0.22)
                          : Colors.white.withValues(alpha: 0.1),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child:
                    _isMarkingAll
                        ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : const Text(
                          'Tandai semua',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child:
            _isLoading
                ? const SingleChildScrollView(child: NotificationListSkeleton())
                : _error != null
                ? _buildErrorView()
                : _items.isEmpty
                ? _buildEmptyView()
                : _buildListView(),
      ),
    );
  }

  Widget _buildErrorView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                IconlyLight.dangerCircle,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Color(0xFF475569), fontSize: 14),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadNotifications,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Coba lagi'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyView() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Column(
            children: [
              Icon(
                IconlyLight.notification,
                size: 56,
                color: Color(0xFF94A3B8),
              ),
              SizedBox(height: 14),
              Text(
                'Belum ada notifikasi',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Semua pemberitahuan akan muncul di sini.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        NotificationSummaryCard(unreadCount: _unreadCount),
        const SizedBox(height: 16),
        ..._items.map((item) {
          final color = colorForType(item.type);
          final icon = iconForType(item.type);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: NotificationCard(
              item: item,
              color: color,
              icon: icon,
              timeAgo: _timeAgo(item.createdAt),
              fullDate: _formatDate(item.createdAt),
              onTap: () async {
                if (!item.isRead) {
                  _markAsRead(item.id);
                }
                NotificationDetailSheet.show(
                  context,
                  item: item,
                  color: color,
                  icon: icon,
                );
              },
            ),
          );
        }),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';

class TicketFilterResult {
  final String? status;
  final String? priority;

  const TicketFilterResult({this.status, this.priority});
}

class TicketFilterDialog extends StatefulWidget {
  final String? initialStatus;
  final String? initialPriority;

  const TicketFilterDialog({
    super.key,
    this.initialStatus,
    this.initialPriority,
  });

  static Future<TicketFilterResult?> show(
    BuildContext context, {
    String? initialStatus,
    String? initialPriority,
  }) {
    return showDialog<TicketFilterResult>(
      context: context,
      builder:
          (context) => TicketFilterDialog(
            initialStatus: initialStatus,
            initialPriority: initialPriority,
          ),
    );
  }

  @override
  State<TicketFilterDialog> createState() => _TicketFilterDialogState();
}

class _TicketFilterDialogState extends State<TicketFilterDialog> {
  static const Color _primary = Color(0xFF0EA5E9);
  static const Color _border = AppColors.border;
  static const Color _muted = AppColors.textSecondary;

  String? _status;
  String? _priority;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _priority = widget.initialPriority;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        'Filter Laporan',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Status',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('Semua', null, _status, (val) {
                setState(() => _status = val);
              }),
              _buildFilterChip('Terbuka', 'open', _status, (val) {
                setState(() => _status = val);
              }),
              _buildFilterChip('Diproses', 'in_progress', _status, (val) {
                setState(() => _status = val);
              }),
              _buildFilterChip('Selesai', 'solved', _status, (val) {
                setState(() => _status = val);
              }),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Prioritas',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              _buildFilterChip('Semua', null, _priority, (val) {
                setState(() => _priority = val);
              }),
              _buildFilterChip('Rendah', 'low', _priority, (val) {
                setState(() => _priority = val);
              }),
              _buildFilterChip('Sedang', 'medium', _priority, (val) {
                setState(() => _priority = val);
              }),
              _buildFilterChip('Tinggi', 'high', _priority, (val) {
                setState(() => _priority = val);
              }),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context, const TicketFilterResult(status: null, priority: null));
          },
          child: const Text('Reset'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(
              context,
              TicketFilterResult(status: _status, priority: _priority),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: _primary,
            foregroundColor: Colors.white,
          ),
          child: const Text('Terapkan'),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    String label,
    String? value,
    String? currentValue,
    ValueChanged<String?> onSelected,
  ) {
    final isSelected = currentValue == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(value),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w900,
        color: isSelected ? _primary : _muted,
      ),
      backgroundColor: Colors.transparent,
      selectedColor: _primary.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: isSelected ? _primary : _border),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/admin/fee/models/fee_models.dart';

class UserFeeFilterRow extends StatelessWidget {
  final String selectedRange;
  final ValueChanged<String> onRangeChanged;
  final String selectedStatus;
  final ValueChanged<String> onStatusChanged;
  final int? selectedLayananId;
  final List<FeeByLayanan> byLayanan;
  final ValueChanged<int?> onLayananChanged;

  const UserFeeFilterRow({
    super.key,
    required this.selectedRange,
    required this.onRangeChanged,
    required this.selectedStatus,
    required this.onStatusChanged,
    required this.selectedLayananId,
    required this.byLayanan,
    required this.onLayananChanged,
  });

  static const Color _card = AppColors.card;
  static const Color _border = AppColors.border;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _buildRangeDropdown()),
        const SizedBox(width: 8),
        Expanded(child: _buildStatusDropdown()),
        const SizedBox(width: 8),
        Expanded(child: _buildLayananDropdown()),
      ],
    );
  }

  Widget _buildRangeDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedRange,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          onChanged: (value) {
            if (value != null) onRangeChanged(value);
          },
          items: const [
            DropdownMenuItem(value: '7_hari_terakhir', child: Text('7 Hari')),
            DropdownMenuItem(value: '30_hari_terakhir', child: Text('30 Hari')),
            DropdownMenuItem(value: 'semua', child: Text('Semua')),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedStatus,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          onChanged: (value) {
            if (value != null) onStatusChanged(value);
          },
          items: const [
            DropdownMenuItem(value: 'semua', child: Text('Semua Status')),
            DropdownMenuItem(value: 'pending', child: Text('Pending')),
            DropdownMenuItem(
              value: 'siap_dibayar',
              child: Text('Siap Dibayar'),
            ),
            DropdownMenuItem(value: 'dibayar', child: Text('Dibayar')),
            DropdownMenuItem(value: 'batal', child: Text('Batal')),
          ],
        ),
      ),
    );
  }

  Widget _buildLayananDropdown() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int?>(
          value: selectedLayananId,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          onChanged: onLayananChanged,
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text('Semua Layanan'),
            ),
            ...byLayanan.map(
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
}

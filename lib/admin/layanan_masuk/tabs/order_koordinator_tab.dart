import 'package:flutter/material.dart';
import 'package:home_care/admin/layanan_masuk/models/order_detail_admin_model.dart';
import 'package:home_care/admin/layanan_masuk/widgets/order_info_row.dart';
import 'package:home_care/core/theme/app_colors.dart';

class OrderKoordinatorTab extends StatelessWidget {
  final OrderLayananDetailAdmin order;
  final List<KoordinatorOption> koordinators;
  final bool isAssigning;
  final int? selectedKoordinatorId;
  final ValueChanged<int?> onKoordinatorSelected;
  final VoidCallback onAssignKoordinator;

  const OrderKoordinatorTab({
    super.key,
    required this.order,
    required this.koordinators,
    required this.isAssigning,
    required this.selectedKoordinatorId,
    required this.onKoordinatorSelected,
    required this.onAssignKoordinator,
  });

  static const Color _primary = AppColors.primary;
  static const Color _lightTeal = AppColors.lightTeal;
  static const Color _warning = AppColors.warning;
  static const Color _error = AppColors.error;

  @override
  Widget build(BuildContext context) {
    final koordinator = order.koordinator;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        OrderInfoRow(label: 'Nama Koordinator', value: koordinator?.nama),
        OrderInfoRow(label: 'ID Koordinator', value: koordinator?.id),
        OrderInfoRow(label: 'Wilayah', value: koordinator?.wilayah),
        OrderInfoRow(label: 'No HP', value: koordinator?.noHp),
        const SizedBox(height: 24),
        _buildAssignSection(context),
      ],
    );
  }

  Widget _buildAssignSection(BuildContext context) {

    if (koordinators.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _error.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: _error, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Belum ada data koordinator aktif.',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final status = order.statusOrder.toLowerCase();
    final isOrderFinished = status == 'selesai' || status == 'dibatalkan';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isOrderFinished
            ? Colors.grey.withValues(alpha: 0.1)
            : _lightTeal.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isOrderFinished
              ? Colors.grey.withValues(alpha: 0.3)
              : _primary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.assignment_ind,
                color: isOrderFinished ? Colors.grey : _primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                'Ubah / Pilih Koordinator',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          if (isOrderFinished) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _warning.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.lock, color: _warning, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      status == 'selesai'
                          ? 'Order sudah selesai. Tidak dapat mengubah penugasan.'
                          : 'Order dibatalkan. Tidak dapat mengubah penugasan.',
                      style: const TextStyle(
                        fontSize: 12,
                        color: _warning,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            initialValue: selectedKoordinatorId,
            isExpanded: true,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: isOrderFinished ? Colors.grey[200] : Colors.white,
              isDense: true,
            ),
            items: koordinators.map((k) {
              return DropdownMenuItem<int>(
                value: k.id,
                child: Text(
                  k.displayName,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              );
            }).toList(),
            onChanged: isOrderFinished ? null : onKoordinatorSelected,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed:
                  (isOrderFinished || isAssigning) ? null : onAssignKoordinator,
              icon: isAssigning
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      isOrderFinished
                          ? Icons.lock
                          : Icons.assignment_turned_in,
                      size: 18,
                    ),
              label: Text(
                isAssigning
                    ? 'Menyimpan...'
                    : isOrderFinished
                        ? 'Tidak Dapat Diubah'
                        : 'Simpan Penugasan',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: isOrderFinished ? Colors.grey : _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

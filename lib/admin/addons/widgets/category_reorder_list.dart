import 'package:flutter/material.dart';
import 'package:home_care/admin/addons/models/addon_admin_model.dart';
import 'package:home_care/core/theme/app_colors.dart';

class CategoryReorderList extends StatelessWidget {
  final List<AddonCategoryItem> items;
  final bool isSavingOrder;
  final Function(int oldIndex, int newIndex) onReorderItem;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  const CategoryReorderList({
    super.key,
    required this.items,
    required this.isSavingOrder,
    required this.onReorderItem,
    required this.onSave,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: const Color(0xFFFEF3C7),
          child: const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: Color(0xFF92400E)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Tahan & geser kategori untuk mengatur urutan tampilan.",
                  style: TextStyle(fontSize: 12, color: Color(0xFF92400E), fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ReorderableListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            onReorderItem: onReorderItem,
            itemBuilder: (context, index) {
              final cat = items[index];
              return Container(
                key: ValueKey(cat.id),
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      "#${index + 1}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  subtitle: Text("${cat.addonsCount} add-on terkait", style: const TextStyle(fontSize: 11)),
                  trailing: const Icon(Icons.drag_handle_rounded, color: Colors.grey),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.shade200)),
          ),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isSavingOrder ? null : onCancel,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text("Batal"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isSavingOrder ? null : onSave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: isSavingOrder
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Simpan Urutan"),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

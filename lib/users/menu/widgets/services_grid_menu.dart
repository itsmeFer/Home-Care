import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class SvcItemData {
  final String title;
  final IconData icon;
  final bool isMore;

  const SvcItemData(this.title, this.icon) : isMore = false;
  const SvcItemData.more(this.title, this.icon) : isMore = true;
}

class ServicesGridMenu extends StatelessWidget {
  const ServicesGridMenu({super.key});

  static const List<SvcItemData> items = [
    SvcItemData('Rekam Medis', IconlyLight.folder),
    SvcItemData('Tanda Vital', IconlyLight.activity),
    SvcItemData('SOAP Notes', IconlyLight.document),
    SvcItemData('Perawatan Luka', IconlyLight.shieldDone),
    SvcItemData('Care Plan', IconlyLight.tickSquare),
    SvcItemData('Obat & Reminder', IconlyLight.timeCircle),
    SvcItemData('Hasil Lab/Radio', IconlyLight.discovery),
    SvcItemData.more('More', IconlyLight.category),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 6),
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisExtent: 100,
          crossAxisSpacing: 8,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (_, i) => _SvcItem(item: items[i]),
      ),
    );
  }
}

class _SvcItem extends StatelessWidget {
  final SvcItemData item;
  const _SvcItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        if (item.isMore) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kamu sudah di halaman More')),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Buka: ${item.title}')));
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE6FAFA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: const Color(0xFF088088)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              item.title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

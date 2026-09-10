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
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            blurRadius: 10,
            offset: Offset(0, 4),
            color: Color(0x0A000000),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _SvcItem(item: items[0])),
              Expanded(child: _SvcItem(item: items[1])),
              Expanded(child: _SvcItem(item: items[2])),
              Expanded(child: _SvcItem(item: items[3])),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _SvcItem(item: items[4])),
              Expanded(child: _SvcItem(item: items[5])),
              Expanded(child: _SvcItem(item: items[6])),
              Expanded(child: _SvcItem(item: items[7])),
            ],
          ),
        ],
      ),
    );
  }
}

class _SvcItem extends StatelessWidget {
  final SvcItemData item;
  const _SvcItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (item.isMore) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Kamu sudah di halaman More')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Buka: ${item.title}')),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
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
                child: Icon(item.icon, color: const Color(0xFF088088), size: 22),
              ),
              const SizedBox(height: 6),
              Text(
                item.title,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  height: 1.2,
                  color: Color(0xFF334155),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

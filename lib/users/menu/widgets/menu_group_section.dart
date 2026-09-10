import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class MenuGroupSection extends StatelessWidget {
  final String title;
  final List<String> items;

  const MenuGroupSection({
    super.key,
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFF1F5F9)),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            ...items.map(
              (e) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  IconlyLight.arrowRight2,
                  size: 16,
                  color: Color(0xFF088088),
                ),
                title: Text(
                  e,
                  style: const TextStyle(fontSize: 14, color: Color(0xFF334155)),
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Buka: $e')),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

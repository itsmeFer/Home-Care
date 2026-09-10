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
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            ...items.map(
              (e) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(IconlyLight.arrowRight2, size: 18),
                title: Text(e),
                onTap: () {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Buka: $e')));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

class TableCard extends StatelessWidget {
  final List<String> columns;
  final List<List<String>> rows;

  const TableCard({super.key, required this.columns, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          children: [
            Container(
              color: const Color(0xFFF8FAFC),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                children:
                    columns
                        .map(
                          (c) => Expanded(
                            child: Text(
                              c,
                              style: const TextStyle(
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w900,
                                fontSize: 12.2,
                              ),
                            ),
                          ),
                        )
                        .toList(),
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            ...rows.map(
              (r) => Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    child: Row(
                      children:
                          r
                              .asMap()
                              .entries
                              .map(
                                (entry) => Expanded(
                                  child: Text(
                                    entry.value,
                                    style: TextStyle(
                                      color:
                                          entry.key == 0
                                              ? const Color(0xFF0F172A)
                                              : const Color(0xFF334155),
                                      fontWeight:
                                          entry.key == 0
                                              ? FontWeight.w900
                                              : FontWeight.w700,
                                      fontSize: 12.8,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ),
                  const Divider(height: 1, color: Color(0xFFF1F5F9)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BulletList extends StatelessWidget {
  final List<String> items;
  const BulletList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children:
          items
              .map(
                (t) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 4),
                        child: Icon(
                          Icons.circle,
                          size: 8,
                          color: Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          t,
                          style: const TextStyle(
                            color: Color(0xFF334155),
                            fontWeight: FontWeight.w700,
                            fontSize: 12.8,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
    );
  }
}

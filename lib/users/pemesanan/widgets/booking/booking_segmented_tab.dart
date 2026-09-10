import 'package:flutter/material.dart';

/// Animated segmented pill switcher ("Formulir Pemesanan" vs "Tata Cara & SOP").
class BookingSegmentedTab extends StatelessWidget {
  final int selectedSegmentTab;
  final ValueChanged<int> onTabChanged;

  const BookingSegmentedTab({
    super.key,
    required this.selectedSegmentTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF3F5),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(0),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedSegmentTab == 0
                      ? const Color(0xFF0F3E3E)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: selectedSegmentTab == 0
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0F3E3E).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Formulir Pemesanan',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selectedSegmentTab == 0
                          ? Colors.white
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => onTabChanged(1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: selectedSegmentTab == 1
                      ? const Color(0xFF0F3E3E)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: selectedSegmentTab == 1
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0F3E3E).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    'Tata Cara & SOP',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selectedSegmentTab == 1
                          ? Colors.white
                          : Colors.grey.shade600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

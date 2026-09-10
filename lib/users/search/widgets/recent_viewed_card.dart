import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/core/utils/app_formatters.dart';
import '../models/search_models.dart';

class RecentViewedCard extends StatelessWidget {
  final RecentViewedLayananItem item;
  final VoidCallback onTap;

  const RecentViewedCard({super.key, required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child:
                    item.gambarUrl != null && item.gambarUrl!.isNotEmpty
                        ? Image.network(
                          item.gambarUrl!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey.shade200,
                                child: const Icon(
                                  IconlyLight.activity,
                                  color: Colors.grey,
                                ),
                              ),
                        )
                        : Container(
                          width: 60,
                          height: 60,
                          color: Colors.grey.shade200,
                          child: const Icon(
                            IconlyLight.activity,
                            color: Colors.grey,
                          ),
                        ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.namaLayanan,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.kategori != null && item.kategori!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.kategori!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      AppFormatters.formatRupiah(item.hargaFix),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0BA5A7),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(IconlyLight.arrowRight2, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}

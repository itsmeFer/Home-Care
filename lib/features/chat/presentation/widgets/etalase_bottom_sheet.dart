import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:home_care/features/chat/data/models/chat_models.dart';
import 'package:home_care/features/chat/presentation/widgets/chat_input_composer.dart';

class EtalaseBottomSheet extends StatelessWidget {
  final bool isLoading;
  final String? error;
  final List<EtalaseData> items;
  final ValueChanged<EtalaseData> onItemSelected;

  const EtalaseBottomSheet({
    super.key,
    required this.isLoading,
    required this.error,
    required this.items,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const GlassBottomSheet(
        child: SizedBox(
          height: 180,
          child: Center(child: CupertinoActivityIndicator(radius: 14)),
        ),
      );
    }

    if (error != null) {
      return GlassBottomSheet(
        child: SizedBox(
          height: 180,
          child: Center(child: Text(error!, textAlign: TextAlign.center)),
        ),
      );
    }

    return GlassBottomSheet(
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.72,
          ),
          child: ListView.separated(
            padding: const EdgeInsets.all(14),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final item = items[i];
              final image = item.gambar;
              return InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () {
                  Navigator.pop(context);
                  onItemSelected(item);
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: SizedBox(
                          width: 58,
                          height: 58,
                          child:
                              image != null && image.isNotEmpty
                                  ? Image.network(
                                    image,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => _imageFallback(),
                                  )
                                  : _imageFallback(),
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
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item.durasiMenit != null
                                  ? 'Durasi ${item.durasiMenit} menit'
                                  : (item.kategori ?? '-'),
                              style: const TextStyle(
                                color: Color(0xFF636366),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(CupertinoIcons.chevron_right, size: 18),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: const Color(0xFFF2F2F7),
      child: const Icon(CupertinoIcons.photo, color: Color(0xFF8E8E93)),
    );
  }
}

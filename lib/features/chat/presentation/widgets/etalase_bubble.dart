import 'package:flutter/material.dart';
import 'package:home_care/features/chat/data/models/chat_models.dart';
import 'package:home_care/features/chat/presentation/widgets/chat_bubble.dart';

class EtalaseBubble extends StatelessWidget {
  final ChatMessage msg;
  final String timeText;

  const EtalaseBubble({super.key, required this.msg, required this.timeText});

  @override
  Widget build(BuildContext context) {
    final e = msg.etalaseData ?? {};
    final nama = (e['nama'] ?? e['nama_layanan'] ?? 'Layanan').toString();
    final gambar = e['gambar']?.toString();

    return Align(
      alignment: msg.isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        width: 280,
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (gambar != null && gambar.isNotEmpty)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: Image.network(
                  gambar,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Container(
                        height: 150,
                        color: const Color(0xFFF2F2F7),
                      ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  MetaText(
                    label: 'Durasi',
                    value:
                        e['durasi_menit'] != null
                            ? '${e['durasi_menit']} menit'
                            : null,
                  ),
                  MetaText(label: 'Kategori', value: e['kategori']?.toString()),
                  MetaText(
                    label: 'Perawat',
                    value: e['syarat_perawat']?.toString(),
                  ),
                  MetaText(
                    label: 'Lokasi',
                    value: e['lokasi_tersedia']?.toString(),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    timeText,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF8E8E93),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

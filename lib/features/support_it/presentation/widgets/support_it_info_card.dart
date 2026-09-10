import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';

class SupportItHeaderCard extends StatelessWidget {
  const SupportItHeaderCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0EA5E9), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x200EA5E9),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.support_agent_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pusat Bantuan & Tiket IT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Laporkan kendala teknis atau bug sistem',
                  style: TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SupportItWorkflowCard extends StatelessWidget {
  const SupportItWorkflowCard({super.key});

  static const Color _card = AppColors.card;
  static const Color _border = AppColors.border;
  static const Color _text = AppColors.textPrimary;
  static const Color _muted = AppColors.textSecondary;
  static const Color _primary = Color(0xFF0EA5E9);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, color: _primary, size: 20),
              SizedBox(width: 8),
              Text(
                'Alur Penanganan Tiket',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStep(
            '1',
            'Tiket Terkirim',
            'Laporan masuk ke antrian dashboard IT Developer.',
          ),
          const SizedBox(height: 8),
          _buildStep(
            '2',
            'Investigasi',
            'Tim IT memeriksa log sistem dan mereproduksi kendala.',
          ),
          const SizedBox(height: 8),
          _buildStep(
            '3',
            'Penyelesaian',
            'Solusi diaplikasikan dan status tiket diubah menjadi Selesai.',
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String num, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: _primary.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            num,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: _primary,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: _text,
                ),
              ),
              Text(
                desc,
                style: const TextStyle(
                  fontSize: 11,
                  color: _muted,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

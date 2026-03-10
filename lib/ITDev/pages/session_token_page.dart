import 'package:flutter/material.dart';
import '../widgets/ui_components.dart';

class SessionTokenPage extends StatelessWidget {
  final bool isDesktop;
  final bool isTablet;
  final String range;

  const SessionTokenPage({super.key, required this.isDesktop, required this.isTablet, required this.range});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Session & Token',
          subtitle: 'Monitor sesi login, revoke token (dummy).',
        ),
        const SizedBox(height: 12),

        XCard(
          title: 'Sesi Aktif (Dummy)',
          subtitle: 'User • IP • Device • Last Seen',
          child: Column(
            children: [
              _row('direktur', '192.168.1.7', 'Chrome Desktop', '09:10'),
              _row('koordinator_a', '180.xxx', 'Android', '09:03'),
              _row('perawat_b', '180.xxx', 'Android', '08:44'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  OutlineButtonX(icon: Icons.logout_rounded, label: 'Force Logout', onTap: () {}),
                  OutlineButtonX(icon: Icons.vpn_key_off_outlined, label: 'Revoke Token', onTap: () {}),
                  OutlineButtonX(icon: Icons.warning_amber_outlined, label: 'Flag Suspicious', onTap: () {}),
                ],
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String user, String ip, String device, String last) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Row(
        children: [
          Expanded(child: Text(user, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A)))),
          Expanded(child: Text(ip, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B)))),
          Expanded(child: Text(device, style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF64748B)))),
          Text(last, style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        ],
      ),
    );
  }
}

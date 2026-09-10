import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:url_launcher/url_launcher.dart';
import 'delete_account_dialog.dart';

class SettingsGroupSection extends StatelessWidget {
  const SettingsGroupSection({super.key});

  Future<void> _openPrivacyPolicy() async {
    final url = Uri.parse('https://royal-klinik.cloud/privacy-homecare.html');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
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
            const Text(
              'Informasi & Pengaturan',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6FAFA),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  IconlyLight.shieldDone,
                  color: Color(0xFF088088),
                  size: 20,
                ),
              ),
              title: const Text(
                'Kebijakan Privasi (Privacy Policy)',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
              trailing: const Icon(IconlyLight.arrowRight2, size: 16, color: Color(0xFF94A3B8)),
              onTap: _openPrivacyPolicy,
            ),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  IconlyLight.delete,
                  color: Color(0xFFEF4444),
                  size: 20,
                ),
              ),
              title: const Text(
                'Hapus Akun',
                style: TextStyle(
                  color: Color(0xFFEF4444),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              trailing: const Icon(IconlyLight.arrowRight2, size: 16, color: Color(0xFF94A3B8)),
              onTap: () => DeleteAccountDialog.show(context),
            ),
          ],
        ),
      ),
    );
  }
}

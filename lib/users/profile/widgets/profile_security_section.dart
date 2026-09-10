import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:home_care/core/constants/api_constants.dart';

class ProfileSecuritySection extends StatelessWidget {
  final VoidCallback onLogout;

  const ProfileSecuritySection({
    super.key,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(IconlyLight.setting, color: Color(0xFF0BA5A7), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Pengaturan & Keamanan',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                leading: const Icon(IconlyLight.shieldDone, color: Color(0xFF0BA5A7)),
                title: const Text(
                  'Kebijakan Privasi (Privacy Policy)',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.8,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1F2937),
                  ),
                ),
                trailing: const Icon(IconlyLight.arrowRight2, size: 16, color: Colors.black54),
                onTap: () async {
                  final url = Uri.parse('https://royal-klinik.cloud/privacy-homecare.html');
                  if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Tidak dapat membuka link Kebijakan Privasi')),
                      );
                    }
                  }
                },
              ),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 4),
                leading: const Icon(IconlyLight.delete, color: Colors.redAccent),
                title: const Text(
                  'Hapus Akun',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.8,
                    fontWeight: FontWeight.w600,
                    color: Colors.redAccent,
                  ),
                ),
                trailing: const Icon(IconlyLight.arrowRight2, size: 16, color: Colors.black54),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Hapus Akun', style: TextStyle(fontWeight: FontWeight.bold)),
                      content: const Text(
                        'Apakah Anda yakin ingin menghapus akun secara permanen? Semua data medis, riwayat pemesanan, dan profil Anda akan dihapus dan tidak dapat dipulihkan kembali.',
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Batal', style: TextStyle(color: Colors.black54)),
                        ),
                        ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            final Uri url = Uri.parse('${ApiConstants.baseUrl}/delete-account');
                            if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Tidak dapat membuka halaman penghapusan akun')),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Ya, Hapus'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            icon: const Icon(IconlyLight.logout, color: Color(0xFFE53935)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFEBEE),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: onLogout,
            label: const Text(
              'Logout',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Color(0xFFE53935),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

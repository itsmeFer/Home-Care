import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Semua Menu'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _ServicesGridMenu(),
            SizedBox(height: 16),
            _MenuGroup(
              title: 'Fitur Medis',
              items: [
                'Pendaftaran Pasien & Rekam Medis',
                'Pencatatan Tanda Vital',
                'SOAP Notes',
                'Perawatan Luka / Home Nursing',
                'Rencana Perawatan (Care Plan)',
                'Manajemen Obat & Pengingat',
                'Hasil Lab & Radiologi',
                'Jadwal Kunjungan',
                'Edukasi Kesehatan',
              ],
            ),
            const SizedBox(height: 16),
            const _SettingsGroup(),
          ],
        ),
      ),
    );
  }
}

class _ServicesGridMenu extends StatelessWidget {
  const _ServicesGridMenu();

  @override
  Widget build(BuildContext context) {
    final items = <_Svc>[
      _Svc('Rekam Medis', Icons.folder_shared),
      _Svc('Tanda Vital', Icons.monitor_heart),
      _Svc('SOAP Notes', Icons.description),
      _Svc('Perawatan Luka', Icons.healing),
      _Svc('Care Plan', Icons.checklist),
      _Svc('Obat & Reminder', Icons.medication),
      _Svc('Hasil Lab/Radio', Icons.science),
      _Svc.more('More', Icons.apps),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            blurRadius: 10,
            offset: const Offset(0, 6),
            color: Colors.black.withOpacity(0.05),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 4,
          mainAxisExtent: 100,
          crossAxisSpacing: 8,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (_, i) => _SvcItem(item: items[i]),
      ),
    );
  }
}

class _Svc {
  final String title;
  final IconData icon;
  final bool isMore;
  _Svc(this.title, this.icon) : isMore = false;
  _Svc.more(this.title, this.icon) : isMore = true;
}

class _SvcItem extends StatelessWidget {
  final _Svc item;
  const _SvcItem({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (item.isMore) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kamu sudah di halaman More')),
          );
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Buka: ${item.title}')));
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE6FAFA),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(item.icon, color: const Color(0xFF088088)),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: Text(
              item.title,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  final String title;
  final List<String> items;
  const _MenuGroup({required this.title, required this.items});

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
                leading: const Icon(Icons.chevron_right),
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

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup();

  Future<void> _openPrivacyPolicy() async {
    final url = Uri.parse('https://royal-klinik.cloud/privacy-homecare.html');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $url');
    }
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text(
              'Hapus Akun',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Apakah Anda yakin ingin menghapus akun secara permanen? Semua data medis, riwayat pemesanan, dan profil Anda akan dihapus dan tidak dapat dipulihkan kembali.',
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.black54),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Permintaan hapus akun telah dikirim ke sistem. Tim kami akan memprosesnya dalam 2x24 jam.',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
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
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 24),
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Informasi & Pengaturan',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
            ),
            const SizedBox(height: 6),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.privacy_tip_outlined,
                color: Color(0xFF088088),
              ),
              title: const Text('Kebijakan Privasi (Privacy Policy)'),
              trailing: const Icon(Icons.open_in_new, size: 16),
              onTap: _openPrivacyPolicy,
            ),
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const Icon(
                Icons.delete_forever_outlined,
                color: Colors.red,
              ),
              title: const Text(
                'Hapus Akun',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () => _showDeleteAccountDialog(context),
            ),
          ],
        ),
      ),
    );
  }
}

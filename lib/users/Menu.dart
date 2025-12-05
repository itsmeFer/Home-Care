import 'package:flutter/material.dart';

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
            // === Grid yang sama seperti di HomePage (7 + More) ===
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
          ],
        ),
      ),
    );
  }
}

/// ========== Services Grid (clone dari HomePage: 7 + More) ==========
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
      _Svc.more('More', Icons.apps), // item ke-8
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
          mainAxisExtent: 88,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
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
          // Sudah di halaman More; kasih info saja
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kamu sudah di halaman More')),
          );
        } else {
          // TODO: ganti dengan navigasi ke screen fitur terkait
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Buka: ${item.title}')),
          );
        }
      },
      child: Column(
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
          const SizedBox(height: 6),
          Text(
            item.title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

/// ========== List group deskriptif ==========
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
            Text(title,
                style: const TextStyle(
                    fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6),
            ...items.map(
              (e) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.chevron_right),
                title: Text(e),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Buka: $e')));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

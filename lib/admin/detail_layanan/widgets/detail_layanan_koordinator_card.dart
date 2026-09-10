import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';

class DetailLayananKoordinatorCard extends StatelessWidget {
  final List<KoordinatorItem> koordinatorLayanan;
  final bool isLoading;
  final bool isSaving;
  final VoidCallback onManageKoordinator;
  final void Function(int koordinatorId, bool aktif, String? catatan)
      onTogglePivot;

  const DetailLayananKoordinatorCard({
    super.key,
    required this.koordinatorLayanan,
    required this.isLoading,
    required this.isSaving,
    required this.onManageKoordinator,
    required this.onTogglePivot,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Koordinator Penanggung Jawab',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: isSaving ? null : onManageKoordinator,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: HCColor.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: isSaving
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.people_alt, size: 18),
                  label: Text(
                    isSaving ? 'Memproses...' : 'Kelola',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: HCColor.primary),
                ),
              )
            else if (koordinatorLayanan.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Text(
                  'Belum ada koordinator yang ditugaskan ke layanan ini.',
                  style: TextStyle(color: Colors.orange.shade900, fontSize: 13),
                ),
              )
            else
              Column(
                children: koordinatorLayanan.map((k) {
                  final pivotAktif = k.pivotAktif ?? true;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor:
                              HCColor.primary.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.person,
                            color: HCColor.primaryDark,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                k.namaLengkap,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                              if ((k.kodeKoordinator ?? '').isNotEmpty)
                                Text(
                                  'Kode: ${k.kodeKoordinator}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              if ((k.wilayah ?? '').isNotEmpty)
                                Text(
                                  'Wilayah: ${k.wilayah}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: k.isActive
                                          ? Colors.green.shade50
                                          : Colors.red.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      k.isActive
                                          ? 'Akun aktif'
                                          : 'Akun nonaktif',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: k.isActive
                                            ? Colors.green.shade800
                                            : Colors.red.shade800,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: pivotAktif
                                          ? Colors.blue.shade50
                                          : Colors.grey.shade200,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      pivotAktif
                                          ? 'Ditugaskan aktif'
                                          : 'Ditugaskan nonaktif',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: pivotAktif
                                            ? Colors.blue.shade800
                                            : Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if ((k.pivotCatatan ?? '').trim().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Catatan: ${k.pivotCatatan}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Switch(
                          value: pivotAktif,
                          onChanged: (val) {
                            onTogglePivot(k.id, val, k.pivotCatatan);
                          },
                          activeThumbColor: HCColor.primary,
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

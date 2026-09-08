import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class BookingDetailsStep extends StatelessWidget {
  final TextEditingController catatanController;
  final int qty;
  final VoidCallback onIncrementQty;
  final VoidCallback onDecrementQty;
  final Uint8List? kondisiPasienBytes;
  final VoidCallback onPickImage;
  final InputDecoration Function({
    required String labelText,
    String? hintText,
    Widget? prefixIcon,
    bool alignLabelWithHint,
  }) inputDecoration;

  const BookingDetailsStep({
    super.key,
    required this.catatanController,
    required this.qty,
    required this.onIncrementQty,
    required this.onDecrementQty,
    required this.kondisiPasienBytes,
    required this.onPickImage,
    required this.inputDecoration,
  });

  Widget _buildCardSection({required BuildContext context, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildQuantitySection(bool small) {
    if (small) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Jumlah Pasien / Sesi',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 10),
          _buildStepper(),
        ],
      );
    }

    return Row(
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jumlah Pasien / Sesi',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 2),
            Text(
              'Kelipatan tindakan per sesi',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
        const Spacer(),
        _buildStepper(),
      ],
    );
  }

  Widget _buildStepper() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: qty > 1 ? onDecrementQty : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: qty > 1
                    ? HCColor.primary.withValues(alpha: 0.5)
                    : Colors.grey.shade300,
              ),
              color: Colors.white,
            ),
            child: Center(
              child: Icon(
                Icons.remove,
                size: 16,
                color: qty > 1 ? HCColor.primary : Colors.grey.shade400,
              ),
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 44),
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            '$qty',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
        ),
        InkWell(
          onTap: onIncrementQty,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: HCColor.primary,
            ),
            child: const Center(
              child: Icon(
                IconlyLight.plus,
                size: 16,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final small = MediaQuery.of(context).size.width < 380;

    return _buildCardSection(
      context: context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Tambahan',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          _buildQuantitySection(small),
          const SizedBox(height: 16),
          TextFormField(
            controller: catatanController,
            maxLines: 3,
            decoration: inputDecoration(
              labelText: 'Catatan (opsional)',
              hintText: 'Tambahkan catatan khusus...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              Text(
                'Foto Kondisi Pasien',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              SizedBox(width: 4),
              Text(
                '*',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(IconlyLight.infoSquare, size: 16, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ambil foto terkini kondisi pasien untuk membantu tenaga medis.',
                    style: TextStyle(fontSize: 11, color: Colors.blue[900]),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onPickImage,
            child: Container(
              width: double.infinity,
              constraints: BoxConstraints(
                minHeight: 180,
                maxHeight: kondisiPasienBytes != null ? 420 : 180,
              ),
              decoration: BoxDecoration(
                color:
                    kondisiPasienBytes == null
                        ? HCColor.lightTeal
                        : Colors.grey[100],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color:
                      kondisiPasienBytes == null
                          ? HCColor.primary.withValues(alpha: 0.3)
                          : HCColor.primary,
                  width: 2,
                ),
              ),
              child:
                  kondisiPasienBytes == null
                      ? Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            IconlyLight.camera,
                            size: 50,
                            color: HCColor.primary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(height: 12),
                          const Text(
                            'Tap untuk ambil foto',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: HCColor.primary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Ukuran maks: 5MB',
                            style: TextStyle(
                              fontSize: 11,
                              color: HCColor.textMuted,
                            ),
                          ),
                        ],
                      )
                      : Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              kondisiPasienBytes!,
                              fit: BoxFit.contain,
                              width: double.infinity,
                            ),
                          ),
                          Positioned(
                            top: 12,
                            right: 12,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    IconlyBold.shieldDone,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    'Foto Terupload',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            right: 12,
                            child: Material(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              elevation: 3,
                              child: InkWell(
                                onTap: onPickImage,
                                borderRadius: BorderRadius.circular(8),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 8,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        IconlyLight.edit,
                                        size: 16,
                                        color: HCColor.primary,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        'Ganti Foto',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: HCColor.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
            ),
          ),
          if (kondisiPasienBytes == null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(IconlyLight.dangerCircle, size: 14, color: Colors.red[700]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Foto kondisi pasien wajib diupload',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

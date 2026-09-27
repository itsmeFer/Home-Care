import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/banners/domain/banner_model.dart';

/// Bagian konfigurasi diskon, potongan harga, dan kode promo banner.
class BannerDiscountSection extends StatelessWidget {
  final String tipeDiskon;
  final ValueChanged<String> onTipeDiskonChanged;
  final TextEditingController nilaiDiskonCtrl;
  final TextEditingController maxDiskonCtrl;
  final TextEditingController teksDiskonCtrl;
  final TextEditingController kodePromoCtrl;
  final TextEditingController minTransaksiCtrl;
  final LayananModel? selectedLayanan;
  final VoidCallback onDataChanged;

  const BannerDiscountSection({
    super.key,
    required this.tipeDiskon,
    required this.onTipeDiskonChanged,
    required this.nilaiDiskonCtrl,
    required this.maxDiskonCtrl,
    required this.teksDiskonCtrl,
    required this.kodePromoCtrl,
    required this.minTransaksiCtrl,
    this.selectedLayanan,
    required this.onDataChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.discount_outlined, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Pengaturan Diskon & Promo',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Pilihan Tipe Diskon
        Row(
          children: [
            _buildDiscountTypeChip(type: 'none', label: 'Tanpa Diskon', icon: Icons.block),
            const SizedBox(width: 8),
            _buildDiscountTypeChip(type: 'nominal', label: 'Nominal (Rp)', icon: Icons.attach_money),
            const SizedBox(width: 8),
            _buildDiscountTypeChip(type: 'persen', label: 'Persen (%)', icon: Icons.percent),
          ],
        ),

        if (tipeDiskon != 'none') ...[
          const SizedBox(height: 16),
          _buildFieldLabel(tipeDiskon == 'nominal' ? 'Nilai Diskon (Rupiah) *' : 'Nilai Diskon (Persen) *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: nilaiDiskonCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: tipeDiskon == 'nominal'
                ? [CurrencyFormatter()]
                : [FilteringTextInputFormatter.digitsOnly],
            decoration: _inputDecoration(
              hint: tipeDiskon == 'nominal' ? 'Rp 50.000' : '20',
              prefixText: tipeDiskon == 'nominal' ? '' : '% ',
            ),
            onChanged: (_) => onDataChanged(),
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Nilai diskon wajib diisi';
              if (tipeDiskon == 'nominal') {
                if (parseRupiah(v) <= 0) return 'Nilai harus lebih dari 0';
              } else {
                final p = double.tryParse(v);
                if (p == null || p <= 0 || p > 100) return 'Masukkan persentase 1 - 100';
              }
              return null;
            },
          ),
          const SizedBox(height: 4),
          Text(
            tipeDiskon == 'nominal' ? 'Format otomatis: Rp 50.000' : 'Contoh: 20 untuk diskon 20%',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),

          if (tipeDiskon == 'persen') ...[
            const SizedBox(height: 14),
            _buildFieldLabel('Maksimal Diskon (Rupiah - Opsional)'),
            const SizedBox(height: 6),
            TextFormField(
              controller: maxDiskonCtrl,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyFormatter()],
              decoration: _inputDecoration(hint: 'Rp 100.000'),
              onChanged: (_) => onDataChanged(),
            ),
            const SizedBox(height: 4),
            Text(
              'Batas maksimal potongan diskon persen (kosongkan jika tanpa batas)',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],

          const SizedBox(height: 14),
          _buildFieldLabel('Teks Label Diskon (Ditampilkan di Banner) *'),
          const SizedBox(height: 6),
          TextFormField(
            controller: teksDiskonCtrl,
            decoration: _inputDecoration(hint: 'Misal: Diskon 20%, Hemat Rp 50rb, Flash Sale'),
            onChanged: (_) => onDataChanged(),
            validator: (v) => v == null || v.trim().isEmpty ? 'Teks label diskon wajib diisi' : null,
          ),

          const SizedBox(height: 14),
          _buildFieldLabel('Kode Promo / Voucher (Opsional)'),
          const SizedBox(height: 6),
          TextFormField(
            controller: kodePromoCtrl,
            textCapitalization: TextCapitalization.characters,
            decoration: _inputDecoration(
              hint: 'Misal: HEMAT20, SEHAT50',
              prefixIcon: const Icon(Icons.confirmation_number_outlined, size: 20, color: AppColors.primary),
            ),
            onChanged: (_) => onDataChanged(),
          ),
          const SizedBox(height: 4),
          Text(
            'Kode kupon yang dapat digunakan pasien saat proses pemesanan',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),

          const SizedBox(height: 14),
          _buildFieldLabel('Minimal Nilai Transaksi (Opsional)'),
          const SizedBox(height: 6),
          TextFormField(
            controller: minTransaksiCtrl,
            keyboardType: TextInputType.number,
            inputFormatters: [CurrencyFormatter()],
            decoration: _inputDecoration(hint: 'Rp 0'),
            onChanged: (_) => onDataChanged(),
          ),
          const SizedBox(height: 4),
          Text(
            'Kosongkan atau Rp 0 jika promo berlaku tanpa batas minimal belanja',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ],
    );
  }

  Widget _buildDiscountTypeChip({
    required String type,
    required String label,
    required IconData icon,
  }) {
    final isSelected = tipeDiskon == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          onTipeDiskonChanged(type);
          onDataChanged();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE6FAFA) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? AppColors.primary : Colors.grey.shade600),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? AppColors.primary : Colors.grey.shade800,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary),
    );
  }

  InputDecoration _inputDecoration({String? hint, String? prefixText, Widget? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      prefixText: prefixText,
      prefixIcon: prefixIcon,
      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
  }
}

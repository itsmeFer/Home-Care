import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';
import 'package:home_care/features/profile/presentation/widgets/profile_wilayah_dropdowns.dart';

class ProfileEditForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController namaC;
  final TextEditingController nikC;
  final TextEditingController noHpC;
  final TextEditingController emailC;
  final TextEditingController alamatC;
  final TextEditingController kodePosC;
  final TextEditingController golonganDarahC;
  final TextEditingController alergiC;
  final TextEditingController penyakitMenahunC;

  final String? jenisKelamin;
  final ValueChanged<String?> onJenisKelaminChanged;
  final DateTime? tanggalLahir;
  final VoidCallback onPickTanggalLahir;

  final List<Map<String, String>> provinsiList;
  final List<Map<String, String>> kotaList;
  final List<Map<String, String>> kecamatanList;
  final List<Map<String, String>> kelurahanList;

  final String? selectedProvinsiId;
  final String? selectedKotaId;
  final String? selectedKecamatanId;
  final String? selectedKelurahanId;

  final bool isLoadingProvinsi;
  final bool isLoadingKota;
  final bool isLoadingKecamatan;
  final bool isLoadingKelurahan;

  final ValueChanged<String?> onProvinsiChanged;
  final ValueChanged<String?> onKotaChanged;
  final ValueChanged<String?> onKecamatanChanged;
  final ValueChanged<String?> onKelurahanChanged;

  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  const ProfileEditForm({
    super.key,
    required this.formKey,
    required this.namaC,
    required this.nikC,
    required this.noHpC,
    required this.emailC,
    required this.alamatC,
    required this.kodePosC,
    required this.golonganDarahC,
    required this.alergiC,
    required this.penyakitMenahunC,
    required this.jenisKelamin,
    required this.onJenisKelaminChanged,
    required this.tanggalLahir,
    required this.onPickTanggalLahir,
    required this.provinsiList,
    required this.kotaList,
    required this.kecamatanList,
    required this.kelurahanList,
    required this.selectedProvinsiId,
    required this.selectedKotaId,
    required this.selectedKecamatanId,
    required this.selectedKelurahanId,
    required this.isLoadingProvinsi,
    required this.isLoadingKota,
    required this.isLoadingKecamatan,
    required this.isLoadingKelurahan,
    required this.onProvinsiChanged,
    required this.onKotaChanged,
    required this.onKecamatanChanged,
    required this.onKelurahanChanged,
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
  });

  static const Color _primary = Color(0xFF0BA5A7);
  static const Color _border = Color(0xFFE5E7EB);
  static const Color _textSoft = Color(0xFF6B7280);
  static const Color _textDark = Color(0xFF1F2937);

  InputDecoration _inputDecoration({required String label, String? hint, Widget? suffixIcon}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(color: _textSoft, fontWeight: FontWeight.w500),
      hintStyle: const TextStyle(color: Colors.black38),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primary, width: 1.4),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
      ),
    );
  }

  Widget _buildFieldLoading() {
    return const Padding(
      padding: EdgeInsets.all(14),
      child: SizedBox(
        width: 16,
        height: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }

  String _formatDate(DateTime? dt) {
    if (dt == null) return 'Pilih Tanggal Lahir';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final bool twoColumn = width >= 700;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 8),
            color: Colors.black.withValues(alpha: 0.05),
          ),
        ],
      ),
      child: Form(
        key: formKey,
        child: Column(
          children: [
            if (twoColumn)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: namaC,
                      decoration: _inputDecoration(label: 'Nama Lengkap'),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: nikC,
                      decoration: _inputDecoration(label: 'NIK (opsional)'),
                    ),
                  ),
                ],
              )
            else ...[
              TextFormField(
                controller: namaC,
                decoration: _inputDecoration(label: 'Nama Lengkap'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama tidak boleh kosong' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: nikC,
                decoration: _inputDecoration(label: 'NIK (opsional)'),
              ),
            ],
            const SizedBox(height: 12),
            if (twoColumn)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildGenderField()),
                  const SizedBox(width: 12),
                  Expanded(child: _buildBirthDateField()),
                ],
              )
            else ...[
              _buildGenderField(),
              const SizedBox(height: 12),
              _buildBirthDateField(),
            ],
            const SizedBox(height: 12),
            if (twoColumn)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: noHpC,
                      decoration: _inputDecoration(label: 'No. HP'),
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'No HP tidak boleh kosong' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: emailC,
                      decoration: _inputDecoration(label: 'Email (opsional)'),
                      keyboardType: TextInputType.emailAddress,
                    ),
                  ),
                ],
              )
            else ...[
              TextFormField(
                controller: noHpC,
                decoration: _inputDecoration(label: 'No. HP'),
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty) ? 'No HP tidak boleh kosong' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: emailC,
                decoration: _inputDecoration(label: 'Email (opsional)'),
                keyboardType: TextInputType.emailAddress,
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
              controller: alamatC,
              maxLines: 2,
              decoration: _inputDecoration(label: 'Alamat Lengkap'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Alamat tidak boleh kosong' : null,
            ),
            const SizedBox(height: 12),
            ProfileWilayahDropdowns(
              provinsiList: provinsiList,
              kotaList: kotaList,
              kecamatanList: kecamatanList,
              kelurahanList: kelurahanList,
              selectedProvinsiId: selectedProvinsiId,
              selectedKotaId: selectedKotaId,
              selectedKecamatanId: selectedKecamatanId,
              selectedKelurahanId: selectedKelurahanId,
              selectedKodePos: kodePosC.text,
              isLoadingProvinsi: isLoadingProvinsi,
              isLoadingKota: isLoadingKota,
              isLoadingKecamatan: isLoadingKecamatan,
              isLoadingKelurahan: isLoadingKelurahan,
              twoColumn: twoColumn,
              inputDecoration: _inputDecoration,
              buildFieldLoading: _buildFieldLoading,
              onProvinsiChanged: onProvinsiChanged,
              onKotaChanged: onKotaChanged,
              onKecamatanChanged: onKecamatanChanged,
              onKelurahanChanged: onKelurahanChanged,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: golonganDarahC,
              decoration: _inputDecoration(label: 'Golongan Darah (A/B/AB/O)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: alergiC,
              decoration: _inputDecoration(label: 'Alergi (Obat/Makanan, jika ada)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: penyakitMenahunC,
              decoration: _inputDecoration(label: 'Riwayat Penyakit Menahun (jika ada)'),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isSaving ? null : onCancel,
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      side: const BorderSide(color: _border),
                    ),
                    child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      elevation: 0,
                      minimumSize: const Size.fromHeight(52),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                    onPressed: isSaving ? null : onSave,
                    child:
                        isSaving
                            ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                            )
                            : const Text(
                              'Simpan Perubahan',
                              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                            ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenderField() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: jenisKelamin,
      decoration: _inputDecoration(label: 'Jenis Kelamin'),
      items: const [
        DropdownMenuItem(value: 'Laki-laki', child: Text('Laki-laki', overflow: TextOverflow.ellipsis)),
        DropdownMenuItem(value: 'Perempuan', child: Text('Perempuan', overflow: TextOverflow.ellipsis)),
      ],
      onChanged: onJenisKelaminChanged,
      validator: (v) => v == null ? 'Pilih jenis kelamin' : null,
    );
  }

  Widget _buildBirthDateField() {
    return InkWell(
      onTap: onPickTanggalLahir,
      borderRadius: BorderRadius.circular(16),
      child: InputDecorator(
        decoration: _inputDecoration(label: 'Tanggal Lahir'),
        child: Row(
          children: [
            const Icon(IconlyLight.calendar, size: 18, color: _textSoft),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _formatDate(tanggalLahir),
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: tanggalLahir == null ? Colors.black45 : _textDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class ProfileWilayahDropdowns extends StatelessWidget {
  final List<dynamic> provinsiList;
  final List<dynamic> kotaList;
  final List<dynamic> kecamatanList;
  final List<dynamic> kelurahanList;
  final String? selectedProvinsiId;
  final String? selectedKotaId;
  final String? selectedKecamatanId;
  final String? selectedKelurahanId;
  final String? selectedKodePos;
  final bool isLoadingProvinsi;
  final bool isLoadingKota;
  final bool isLoadingKecamatan;
  final bool isLoadingKelurahan;
  final ValueChanged<String?> onProvinsiChanged;
  final ValueChanged<String?> onKotaChanged;
  final ValueChanged<String?> onKecamatanChanged;
  final ValueChanged<String?> onKelurahanChanged;
  final InputDecoration Function({required String label, Widget? suffixIcon}) inputDecoration;
  final Widget Function() buildFieldLoading;
  final bool twoColumn;

  const ProfileWilayahDropdowns({
    super.key,
    required this.provinsiList,
    required this.kotaList,
    required this.kecamatanList,
    required this.kelurahanList,
    this.selectedProvinsiId,
    this.selectedKotaId,
    this.selectedKecamatanId,
    this.selectedKelurahanId,
    this.selectedKodePos,
    required this.isLoadingProvinsi,
    required this.isLoadingKota,
    required this.isLoadingKecamatan,
    required this.isLoadingKelurahan,
    required this.onProvinsiChanged,
    required this.onKotaChanged,
    required this.onKecamatanChanged,
    required this.onKelurahanChanged,
    required this.inputDecoration,
    required this.buildFieldLoading,
    this.twoColumn = false,
  });

  Widget _buildProvinsiField() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: provinsiList.any((e) => e['id']?.toString() == selectedProvinsiId)
          ? selectedProvinsiId
          : null,
      decoration: inputDecoration(
        label: 'Provinsi',
        suffixIcon: isLoadingProvinsi ? buildFieldLoading() : null,
      ),
      items: provinsiList
          .map(
            (e) => DropdownMenuItem<String>(
              value: e['id']?.toString(),
              child: Text(
                (e['name'] ?? '').toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onProvinsiChanged,
      validator: (v) => v == null ? 'Pilih provinsi' : null,
    );
  }

  Widget _buildKotaField() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: kotaList.any((e) => e['id']?.toString() == selectedKotaId)
          ? selectedKotaId
          : null,
      decoration: inputDecoration(
        label: 'Kota/Kabupaten',
        suffixIcon: isLoadingKota ? buildFieldLoading() : null,
      ),
      items: kotaList
          .map(
            (e) => DropdownMenuItem<String>(
              value: e['id']?.toString(),
              child: Text(
                (e['name'] ?? '').toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onKotaChanged,
      validator: (v) => v == null ? 'Pilih kota/kabupaten' : null,
    );
  }

  Widget _buildKecamatanField() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: kecamatanList.any((e) => e['id']?.toString() == selectedKecamatanId)
          ? selectedKecamatanId
          : null,
      decoration: inputDecoration(
        label: 'Kecamatan',
        suffixIcon: isLoadingKecamatan ? buildFieldLoading() : null,
      ),
      items: kecamatanList
          .map(
            (e) => DropdownMenuItem<String>(
              value: e['id']?.toString(),
              child: Text(
                (e['name'] ?? '').toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onKecamatanChanged,
      validator: (v) => v == null ? 'Pilih kecamatan' : null,
    );
  }

  Widget _buildKelurahanField() {
    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: kelurahanList.any((e) => e['id']?.toString() == selectedKelurahanId)
          ? selectedKelurahanId
          : null,
      decoration: inputDecoration(
        label: 'Kelurahan/Desa',
        suffixIcon: isLoadingKelurahan ? buildFieldLoading() : null,
      ),
      items: kelurahanList
          .map(
            (e) => DropdownMenuItem<String>(
              value: e['id']?.toString(),
              child: Text(
                (e['name'] ?? '').toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onKelurahanChanged,
      validator: (v) => v == null ? 'Pilih kelurahan' : null,
    );
  }

  Widget _buildKodePosField() {
    return TextFormField(
      key: ValueKey(selectedKodePos),
      initialValue: selectedKodePos ?? '',
      readOnly: true,
      decoration: inputDecoration(
        label: 'Kode Pos',
        suffixIcon: const Icon(IconlyLight.location, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (twoColumn) {
      return Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildProvinsiField()),
              const SizedBox(width: 12),
              Expanded(child: _buildKotaField()),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildKecamatanField()),
              const SizedBox(width: 12),
              Expanded(child: _buildKelurahanField()),
            ],
          ),
          const SizedBox(height: 12),
          _buildKodePosField(),
        ],
      );
    }

    return Column(
      children: [
        _buildProvinsiField(),
        const SizedBox(height: 12),
        _buildKotaField(),
        const SizedBox(height: 12),
        _buildKecamatanField(),
        const SizedBox(height: 12),
        _buildKelurahanField(),
        const SizedBox(height: 12),
        _buildKodePosField(),
      ],
    );
  }
}

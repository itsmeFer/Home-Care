import 'package:flutter/material.dart';
import 'package:home_care/admin/perawat/models/perawat_admin_models.dart';
import 'package:home_care/admin/perawat/widgets/perawat_extra_fields.dart';
import 'package:home_care/core/theme/app_colors.dart';

class PerawatFormDialog extends StatefulWidget {
  final PerawatModel? perawat;
  final List<KoordinatorItem> koordinatorOptions;

  const PerawatFormDialog({
    super.key,
    this.perawat,
    required this.koordinatorOptions,
  });

  @override
  State<PerawatFormDialog> createState() => _PerawatFormDialogState();
}

class _PerawatFormDialogState extends State<PerawatFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaC;
  late TextEditingController _nikC;
  String? _jk;
  DateTime? _tglLahir;
  late TextEditingController _tmpLahirC;

  late TextEditingController _emailC;
  late TextEditingController _hpC;

  int? _selectedKoorId;

  late TextEditingController _profesiC;
  late TextEditingController _keahlianC;
  late TextEditingController _noStrC;
  late TextEditingController _noSipC;

  late TextEditingController _tahunExpC;
  late TextEditingController _tempatKerjaC;

  late TextEditingController _wilayahC;
  late TextEditingController _alamatC;

  late TextEditingController _kdNamaC;
  late TextEditingController _kdHpC;
  late TextEditingController _kdHubunganC;

  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final p = widget.perawat;

    _namaC = TextEditingController(text: p?.namaLengkap ?? '');
    _nikC = TextEditingController(text: p?.nik ?? '');
    _jk = p?.jenisKelamin;
    _tglLahir = _parseDate(p?.tanggalLahir);
    _tmpLahirC = TextEditingController(text: p?.tempatLahir ?? '');

    _emailC = TextEditingController(text: p?.email ?? '');
    _hpC = TextEditingController(text: p?.noHp ?? '');

    _selectedKoorId = p?.koordinatorId;

    _profesiC = TextEditingController(text: p?.profesi ?? '');
    _keahlianC = TextEditingController(text: p?.keahlian ?? '');
    _noStrC = TextEditingController(text: p?.noStr ?? '');
    _noSipC = TextEditingController(text: p?.noSip ?? '');

    _tahunExpC = TextEditingController(text: '${p?.tahunPengalaman ?? 0}');
    _tempatKerjaC = TextEditingController(text: p?.tempatKerjaTerakhir ?? '');

    _wilayahC = TextEditingController(text: p?.wilayah ?? '');
    _alamatC = TextEditingController(text: p?.alamat ?? '');

    _kdNamaC = TextEditingController(text: p?.kontakDaruratNama ?? '');
    _kdHpC = TextEditingController(text: p?.kontakDaruratNoHp ?? '');
    _kdHubunganC = TextEditingController(text: p?.kontakDaruratHubungan ?? '');

    _isActive = p?.isActive ?? true;
  }

  DateTime? _parseDate(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    return DateTime.tryParse(s);
  }

  @override
  void dispose() {
    _namaC.dispose();
    _nikC.dispose();
    _tmpLahirC.dispose();
    _emailC.dispose();
    _hpC.dispose();
    _profesiC.dispose();
    _keahlianC.dispose();
    _noStrC.dispose();
    _noSipC.dispose();
    _tahunExpC.dispose();
    _tempatKerjaC.dispose();
    _wilayahC.dispose();
    _alamatC.dispose();
    _kdNamaC.dispose();
    _kdHpC.dispose();
    _kdHubunganC.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final initial = _tglLahir ?? DateTime(now.year - 25, 1, 1);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1950, 1, 1),
      lastDate: now,
    );
    if (picked != null) setState(() => _tglLahir = picked);
  }

  String _fmtDate(DateTime d) =>
      "${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final payload = <String, dynamic>{
      'koordinator_id': _selectedKoorId,
      'nama_lengkap': _namaC.text.trim(),
      'nik': _nikC.text.trim().isEmpty ? null : _nikC.text.trim(),
      'jenis_kelamin': _jk,
      'tanggal_lahir': _tglLahir == null ? null : _fmtDate(_tglLahir!),
      'tempat_lahir':
          _tmpLahirC.text.trim().isEmpty ? null : _tmpLahirC.text.trim(),
      'email': _emailC.text.trim().isEmpty ? null : _emailC.text.trim(),
      'no_hp': _hpC.text.trim().isEmpty ? null : _hpC.text.trim(),
      'profesi': _profesiC.text.trim().isEmpty ? null : _profesiC.text.trim(),
      'keahlian':
          _keahlianC.text.trim().isEmpty ? null : _keahlianC.text.trim(),
      'no_str': _noStrC.text.trim().isEmpty ? null : _noStrC.text.trim(),
      'no_sip': _noSipC.text.trim().isEmpty ? null : _noSipC.text.trim(),
      'tahun_pengalaman': int.tryParse(_tahunExpC.text.trim()) ?? 0,
      'tempat_kerja_terakhir':
          _tempatKerjaC.text.trim().isEmpty ? null : _tempatKerjaC.text.trim(),
      'wilayah': _wilayahC.text.trim().isEmpty ? null : _wilayahC.text.trim(),
      'alamat': _alamatC.text.trim().isEmpty ? null : _alamatC.text.trim(),
      'kontak_darurat_nama':
          _kdNamaC.text.trim().isEmpty ? null : _kdNamaC.text.trim(),
      'kontak_darurat_no_hp':
          _kdHpC.text.trim().isEmpty ? null : _kdHpC.text.trim(),
      'kontak_darurat_hubungan':
          _kdHubunganC.text.trim().isEmpty ? null : _kdHubunganC.text.trim(),
      'is_active': _isActive,
    };

    Navigator.pop(
      context,
      PerawatFormResult(payload: payload, koordinatorId: _selectedKoorId),
    );
  }

  Widget _section(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: TextStyle(
          color: HCColor.primaryDark,
          fontWeight: FontWeight.w800,
          fontSize: 13.5,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.perawat != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEdit ? 'Edit Perawat' : 'Tambah Perawat',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 560,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _section('Identitas'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _namaC,
                  decoration: const InputDecoration(
                    labelText: 'Nama Lengkap',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Nama wajib diisi'
                      : null,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _nikC,
                        decoration: const InputDecoration(
                          labelText: 'NIK (opsional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Jenis Kelamin',
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          border: OutlineInputBorder(),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String?>(
                            value: _jk,
                            isExpanded: true,
                            items: const [
                              DropdownMenuItem<String?>(
                                value: null,
                                child: Text('Pilih'),
                              ),
                              DropdownMenuItem<String?>(
                                value: 'L',
                                child: Text('Laki-laki'),
                              ),
                              DropdownMenuItem<String?>(
                                value: 'P',
                                child: Text('Perempuan'),
                              ),
                            ],
                            onChanged: (v) => setState(() => _jk = v),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Tanggal Lahir (opsional)',
                            border: OutlineInputBorder(),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _tglLahir == null
                                      ? '-'
                                      : _fmtDate(_tglLahir!),
                                ),
                              ),
                              const Icon(Icons.date_range_outlined),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _tmpLahirC,
                        decoration: const InputDecoration(
                          labelText: 'Tempat Lahir (opsional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _section('Relasi'),
                const SizedBox(height: 8),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Koordinator (opsional)',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int?>(
                      value: _selectedKoorId,
                      isExpanded: true,
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Tanpa Koordinator'),
                        ),
                        ...widget.koordinatorOptions.map(
                          (k) => DropdownMenuItem<int?>(
                            value: k.id,
                            child: Text('${k.nama} • ID ${k.id}'),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _selectedKoorId = v),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                _section('Kontak'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailC,
                        decoration: const InputDecoration(
                          labelText: 'Email (opsional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextFormField(
                        controller: _hpC,
                        decoration: const InputDecoration(
                          labelText: 'No HP (opsional)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                PerawatExtraFields(
                  profesiC: _profesiC,
                  keahlianC: _keahlianC,
                  noStrC: _noStrC,
                  noSipC: _noSipC,
                  tahunExpC: _tahunExpC,
                  tempatKerjaC: _tempatKerjaC,
                  wilayahC: _wilayahC,
                  alamatC: _alamatC,
                  kdNamaC: _kdNamaC,
                  kdHpC: _kdHpC,
                  kdHubunganC: _kdHubunganC,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  value: _isActive,
                  title: const Text('Aktif'),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: HCColor.primary,
            foregroundColor: Colors.white,
          ),
          child: Text(isEdit ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }
}

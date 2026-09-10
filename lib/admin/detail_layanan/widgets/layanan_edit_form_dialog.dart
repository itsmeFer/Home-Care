import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/services_catalog/domain/service_model.dart';

class LayananEditFormDialog extends StatefulWidget {
  final LayananDetail layanan;
  final List<KategoriLayananItem> kategoriList;

  const LayananEditFormDialog({
    super.key,
    required this.layanan,
    required this.kategoriList,
  });

  @override
  State<LayananEditFormDialog> createState() => _LayananEditFormDialogState();
}

class _LayananEditFormDialogState extends State<LayananEditFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaC;
  late TextEditingController _deskripsiC;
  late TextEditingController _jumlahVisitC;
  late TextEditingController _hargaC;
  late TextEditingController _durasiC;

  String? _selectedKategoriSlug;
  String _tipeLayanan = 'single';
  String _syaratPerawat = 'umum';
  String _lokasi = 'rumah';
  bool _aktif = true;

  @override
  void initState() {
    super.initState();
    final l = widget.layanan;

    _namaC = TextEditingController(text: l.namaLayanan);
    _deskripsiC = TextEditingController(text: l.deskripsi ?? '');
    _jumlahVisitC = TextEditingController(
      text: l.jumlahVisit != null ? l.jumlahVisit.toString() : '',
    );
    _hargaC = TextEditingController(
      text: l.hargaDasar > 0 ? l.hargaDasar.toStringAsFixed(0) : '',
    );
    _durasiC = TextEditingController(
      text: l.durasiMenit != null ? l.durasiMenit.toString() : '',
    );

    _tipeLayanan = l.tipeLayanan.isNotEmpty ? l.tipeLayanan : 'single';

    const allowedSyarat = ['umum', 'icu', 'luka', 'fisio', 'anak', 'lainnya'];
    final rawSyarat = l.syaratPerawat ?? 'umum';
    _syaratPerawat = allowedSyarat.contains(rawSyarat) ? rawSyarat : 'umum';

    _lokasi = l.lokasiTersedia ?? 'rumah';
    _aktif = l.aktif;

    final existingSlug = l.kategori?.trim();
    final exists = widget.kategoriList.any((e) => e.slug == existingSlug);
    _selectedKategoriSlug = exists ? existingSlug : null;
  }

  @override
  void dispose() {
    _namaC.dispose();
    _deskripsiC.dispose();
    _jumlahVisitC.dispose();
    _hargaC.dispose();
    _durasiC.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedKategoriSlug == null || _selectedKategoriSlug!.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kategori wajib dipilih')),
      );
      return;
    }

    final harga = double.tryParse(_hargaC.text.replaceAll('.', ''));
    final durasi =
        _durasiC.text.isEmpty ? null : int.tryParse(_durasiC.text.trim());
    final jVisit =
        _jumlahVisitC.text.isEmpty ? null : int.tryParse(_jumlahVisitC.text);

    final payload = {
      'nama_layanan': _namaC.text.trim(),
      'deskripsi':
          _deskripsiC.text.trim().isEmpty ? null : _deskripsiC.text.trim(),
      'kategori': _selectedKategoriSlug,
      'tipe_layanan': _tipeLayanan,
      'jumlah_visit': _tipeLayanan == 'paket' ? jVisit : null,
      'harga_dasar': harga ?? 0,
      'durasi_menit': durasi,
      'syarat_perawat': _syaratPerawat,
      'lokasi_tersedia': _lokasi,
      'aktif': _aktif,
    };

    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text(
        'Edit Layanan',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: 380,
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _namaC,
                  decoration: const InputDecoration(
                    labelText: 'Nama Layanan',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nama layanan wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Kategori Layanan',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedKategoriSlug,
                      isExpanded: true,
                      hint: const Text('Pilih Kategori'),
                      items: widget.kategoriList
                          .where((e) => e.slug.trim().isNotEmpty)
                          .map(
                            (e) => DropdownMenuItem<String>(
                              value: e.slug,
                              child: Text(e.namaKategori),
                            ),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedKategoriSlug = val;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Tipe Layanan',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _tipeLayanan,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(
                          value: 'single',
                          child: Text('Single (per visit)'),
                        ),
                        DropdownMenuItem(
                          value: 'paket',
                          child: Text('Paket (beberapa visit)'),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _tipeLayanan = val ?? 'single';
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                if (_tipeLayanan == 'paket') ...[
                  TextFormField(
                    controller: _jumlahVisitC,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Jumlah Visit (paket)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      if (_tipeLayanan == 'paket') {
                        if (v == null || v.trim().isEmpty) {
                          return 'Jumlah visit wajib untuk paket';
                        }
                        if (int.tryParse(v) == null) {
                          return 'Harus angka';
                        }
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                ],
                TextFormField(
                  controller: _hargaC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Harga Dasar (Rp)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Harga wajib diisi';
                    }
                    if (double.tryParse(v.replaceAll('.', '')) == null) {
                      return 'Format harga tidak valid';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _durasiC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Durasi standar (menit, opsional)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return null;
                    final parsed = int.tryParse(v.trim());
                    if (parsed == null) return 'Durasi harus angka menit';
                    if (parsed < 1) return 'Minimal 1 menit';
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Syarat Perawat',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _syaratPerawat,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'umum', child: Text('Umum')),
                        DropdownMenuItem(value: 'icu', child: Text('ICU')),
                        DropdownMenuItem(
                          value: 'luka',
                          child: Text('Perawat Luka'),
                        ),
                        DropdownMenuItem(
                          value: 'fisio',
                          child: Text('Fisioterapi'),
                        ),
                        DropdownMenuItem(
                          value: 'anak',
                          child: Text('Perawat Anak'),
                        ),
                        DropdownMenuItem(
                            value: 'lainnya', child: Text('Lainnya')),
                      ],
                      onChanged: (val) {
                        setState(() => _syaratPerawat = val ?? 'umum');
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Lokasi Tersedia',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    border: OutlineInputBorder(),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _lokasi,
                      isExpanded: true,
                      items: const [
                        DropdownMenuItem(value: 'rumah', child: Text('Rumah')),
                        DropdownMenuItem(
                          value: 'rumah_sakit',
                          child: Text('Rumah Sakit'),
                        ),
                        DropdownMenuItem(
                          value: 'keduanya',
                          child: Text('Rumah & RS'),
                        ),
                      ],
                      onChanged: (val) {
                        setState(() => _lokasi = val ?? 'rumah');
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _deskripsiC,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Aktif'),
                  value: _aktif,
                  onChanged: (val) {
                    setState(() => _aktif = val);
                  },
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
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

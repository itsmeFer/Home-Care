import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:home_care/admin/addons/models/addon_admin_model.dart';
import 'package:home_care/admin/addons/services/addon_admin_service.dart';
import 'package:home_care/admin/addons/widgets/addon_form_image_picker.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_image_compressor.dart';

class AddonFormSheet extends StatefulWidget {
  final AddonItem? item;
  final List<AddonCategoryItem> categoriesDropdown;
  final VoidCallback onSuccess;

  const AddonFormSheet({
    super.key,
    this.item,
    required this.categoriesDropdown,
    required this.onSuccess,
  });

  @override
  State<AddonFormSheet> createState() => _AddonFormSheetState();
}

class _AddonFormSheetState extends State<AddonFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _namaCtrl;
  late TextEditingController _deskCtrl;
  late TextEditingController _hargaCtrl;

  int? _catId;
  late bool _isQtyEnabled;
  late bool _aktif;
  bool _removeGambar = false;

  XFile? _pickedImage;
  Uint8List? _compressedBytes;
  bool _isCompressing = false;
  bool _isSubmitting = false;

  bool get isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _namaCtrl = TextEditingController(text: item?.namaAddon ?? '');
    _deskCtrl = TextEditingController(text: item?.deskripsi ?? '');

    final double rawHarga = item?.hargaFix ?? 0.0;
    _hargaCtrl = TextEditingController(
      text: isEdit && rawHarga > 0 ? NumberFormat.decimalPattern('id_ID').format(rawHarga.toInt()) : '',
    );

    _catId = item?.addonCategoryId;
    _isQtyEnabled = isEdit ? item!.isQtyEnabled : true;
    _aktif = isEdit ? item!.aktif : true;
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _deskCtrl.dispose();
    _hargaCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? picked = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (picked != null) {
        setState(() => _isCompressing = true);
        final compressed = await AppImageCompressor.compressXFile(picked);

        setState(() {
          _pickedImage = picked;
          _compressedBytes = compressed;
          _removeGambar = false;
          _isCompressing = false;
        });
      }
    } catch (e) {
      setState(() => _isCompressing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memilih gambar: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final String rawCleanHarga = _hargaCtrl.text.replaceAll('.', '').trim();
    final double? parsedHarga = double.tryParse(rawCleanHarga);

    if (parsedHarga == null || parsedHarga < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harga tidak valid'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final fields = <String, String>{
        'nama_addon': _namaCtrl.text.trim(),
        'harga': parsedHarga.toString(),
        'is_qty_enabled': _isQtyEnabled ? '1' : '0',
        'aktif': _aktif ? '1' : '0',
      };
      if (_catId != null) {
        fields['addon_category_id'] = _catId.toString();
      }
      if (_deskCtrl.text.trim().isNotEmpty) {
        fields['deskripsi'] = _deskCtrl.text.trim();
      }

      await AddonAdminService.submitAddon(
        isEdit: isEdit,
        id: widget.item?.id,
        fields: fields,
        removeGambar: _removeGambar,
        compressedImageBytes: _compressedBytes,
        fileName: _pickedImage?.name ?? 'addon.jpg',
        fallbackFile: _pickedImage,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Add-on berhasil diperbarui' : 'Add-on berhasil ditambahkan'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        left: 20,
        right: 20,
        top: 16,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isEdit ? 'Edit Add-on' : 'Tambah Add-on Baru',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AddonFormImagePicker(
                      pickedImage: _pickedImage,
                      compressedBytes: _compressedBytes,
                      existingImageUrl: widget.item?.gambarUrl,
                      removeGambar: _removeGambar,
                      isCompressing: _isCompressing,
                      onPickSource: () {
                        AddonFormImagePicker.showSourceSheet(
                          context: context,
                          onSelect: _pickImage,
                        );
                      },
                      onRemove: () {
                        setState(() {
                          _pickedImage = null;
                          _compressedBytes = null;
                          _removeGambar = true;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int?>(
                      initialValue: _catId,
                      decoration: InputDecoration(
                        labelText: 'Kategori (Opsional)',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: [
                        const DropdownMenuItem<int?>(
                          value: null,
                          child: Text('Tanpa Kategori'),
                        ),
                        ...widget.categoriesDropdown.map(
                          (c) => DropdownMenuItem<int?>(
                            value: c.id,
                            child: Text(c.name),
                          ),
                        ),
                      ],
                      onChanged: (val) => setState(() => _catId = val),
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _namaCtrl,
                      decoration: InputDecoration(
                        labelText: 'Nama Add-on *',
                        hintText: 'Misal: Perban Steril 10cm',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Nama add-on wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _hargaCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          if (newValue.text.isEmpty) return newValue;
                          final int? num = int.tryParse(newValue.text);
                          if (num == null) return oldValue;
                          final newString = NumberFormat.decimalPattern('id_ID').format(num);
                          return TextEditingValue(
                            text: newString,
                            selection: TextSelection.collapsed(offset: newString.length),
                          );
                        }),
                      ],
                      decoration: InputDecoration(
                        labelText: 'Harga Satuan (Rp) *',
                        prefixText: 'Rp ',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Harga add-on wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _deskCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Deskripsi / Catatan Tambahan',
                        hintText: 'Tuliskan deskripsi spesifikasi add-on...',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Bisa Pilih Qty', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Pasien dapat memilih kuantitas lebih dari 1 pada saat memesan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      value: _isQtyEnabled,
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                      onChanged: (v) => setState(() => _isQtyEnabled = v),
                    ),
                    SwitchListTile.adaptive(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Status Aktif', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                      subtitle: const Text('Tampilkan add-on ini di katalog layanan aplikasi pengguna', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      value: _aktif,
                      activeThumbColor: AppColors.primary,
                      activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                      onChanged: (v) => setState(() => _aktif = v),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text(isEdit ? 'Simpan Perubahan' : 'Tambahkan Add-on', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}

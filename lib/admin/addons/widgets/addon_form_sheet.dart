import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:home_care/admin/addons/services/addon_admin_service.dart';

class AddonFormSheet extends StatefulWidget {
  final Map<String, dynamic>? item;
  final List<dynamic> categoriesDropdown;
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
  bool _isSubmitting = false;

  bool get isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _namaCtrl = TextEditingController(text: item?["nama_addon"] ?? "");
    _deskCtrl = TextEditingController(text: item?["deskripsi"] ?? "");

    final num rawHarga = num.tryParse(item?["harga_fix_raw"]?.toString() ?? "") ?? 0;
    _hargaCtrl = TextEditingController(
      text: isEdit ? NumberFormat.decimalPattern('id_ID').format(rawHarga) : "",
    );

    _catId = item?["addon_category_id"];
    _isQtyEnabled = isEdit ? (item?["is_qty_enabled"] == true) : true;
    _aktif = isEdit ? (item?["aktif"] == true) : true;
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _deskCtrl.dispose();
    _hargaCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    final hargaStr = _hargaCtrl.text.trim().replaceAll(RegExp(r'[^0-9]'), '');

    final fields = <String, String>{
      "nama_addon": _namaCtrl.text.trim(),
      "deskripsi": _deskCtrl.text.trim(),
      "harga_fix": hargaStr.isEmpty ? "0" : hargaStr,
      "is_qty_enabled": _isQtyEnabled ? "1" : "0",
      "aktif": _aktif ? "1" : "0",
    };
    if (_catId != null) fields["addon_category_id"] = _catId.toString();

    try {
      final msg = await AddonAdminService.submitAddon(
        isEdit: isEdit,
        id: widget.item?["id"],
        fields: fields,
        removeGambar: _removeGambar,
        pickedImage: _pickedImage,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      }
      widget.onSuccess();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll("Exception: ", ""))),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final kodeAddon = isEdit ? (widget.item?["kode_addon"] ?? "") : "Auto-generate";

    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      isEdit ? "Edit Add-on" : "Tambah Add-on",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              TextFormField(
                initialValue: kodeAddon,
                enabled: false,
                decoration: InputDecoration(
                  labelText: "Kode Add-on",
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  suffixIcon: const Tooltip(
                    message: "Kode otomatis dibuat oleh sistem",
                    child: Icon(Icons.info_outline),
                  ),
                ),
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _namaCtrl,
                decoration: const InputDecoration(
                  labelText: "Nama Add-on",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v ?? "").trim().isEmpty ? "Nama wajib diisi" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _deskCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Deskripsi (opsional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<int?>(
                value: _catId,
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text("Tanpa kategori"),
                  ),
                  ...widget.categoriesDropdown.map(
                    (c) => DropdownMenuItem<int?>(
                      value: c["id"],
                      child: Text("${c["name"]}"),
                    ),
                  ),
                ],
                onChanged: (v) => setState(() => _catId = v),
                decoration: const InputDecoration(
                  labelText: "Kategori",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _hargaCtrl,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  _AddonCurrencyFormatter(),
                ],
                decoration: const InputDecoration(
                  labelText: "Harga Fix",
                  border: OutlineInputBorder(),
                  prefixText: "Rp ",
                ),
                validator: (v) {
                  final val = (v ?? "").trim().replaceAll(RegExp(r'[^0-9]'), '');
                  if (val.isEmpty) return "Harga wajib diisi";
                  final n = num.tryParse(val);
                  if (n == null || n < 0) return "Harga tidak valid";
                  return null;
                },
              ),
              const SizedBox(height: 10),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Qty bisa diubah?"),
                subtitle: const Text("Jika OFF, qty dipaksa 1 saat dipilih pasien."),
                value: _isQtyEnabled,
                onChanged: (v) => setState(() => _isQtyEnabled = v),
              ),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Aktif"),
                value: _aktif,
                onChanged: (v) => setState(() => _aktif = v),
              ),

              const Divider(height: 24),

              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () async {
                      final img = await ImagePicker().pickImage(source: ImageSource.gallery);
                      if (img != null) {
                        setState(() {
                          _pickedImage = img;
                          _removeGambar = false;
                        });
                      }
                    },
                    icon: const Icon(Icons.image_outlined),
                    label: Text(_pickedImage == null ? "Pilih Gambar" : "Ganti Gambar"),
                  ),
                  const SizedBox(width: 8),
                  if (_pickedImage != null)
                    IconButton(
                      tooltip: "Hapus pilihan gambar",
                      onPressed: () => setState(() => _pickedImage = null),
                      icon: const Icon(Icons.delete_outline),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (_pickedImage != null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text("File: ${_pickedImage!.name}"),
                ),

              if (isEdit && _pickedImage == null && (widget.item?["gambar"] != null))
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text("Hapus gambar saat ini"),
                  value: _removeGambar,
                  onChanged: (v) => setState(() => _removeGambar = v),
                ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isEdit ? "Simpan Perubahan" : "Tambah Add-on"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddonCurrencyFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.text.isEmpty) return newValue.copyWith(text: '');
    final number = int.tryParse(newValue.text.replaceAll(RegExp(r'[^0-9]'), ''));
    if (number == null) return oldValue;
    final newText = NumberFormat.decimalPattern('id_ID').format(number);
    return newValue.copyWith(text: newText, selection: TextSelection.collapsed(offset: newText.length));
  }
}

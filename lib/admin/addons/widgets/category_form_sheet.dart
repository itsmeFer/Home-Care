import 'package:flutter/material.dart';
import 'package:home_care/admin/addons/services/addon_admin_service.dart';

class CategoryFormSheet extends StatefulWidget {
  final Map<String, dynamic>? item;
  final VoidCallback onSuccess;

  const CategoryFormSheet({
    super.key,
    this.item,
    required this.onSuccess,
  });

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _descCtrl;
  late bool _isActive;
  bool _isSubmitting = false;

  bool get isEdit => widget.item != null;

  @override
  void initState() {
    super.initState();
    final item = widget.item;
    _nameCtrl = TextEditingController(text: item?["name"] ?? "");
    _descCtrl = TextEditingController(text: item?["description"] ?? "");
    _isActive = isEdit ? (item?["is_active"] == true) : true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isSubmitting = true);
    final payload = {
      "name": _nameCtrl.text.trim(),
      "description": _descCtrl.text.trim(),
      "is_active": _isActive,
    };

    try {
      final String msg;
      if (isEdit) {
        msg = await AddonAdminService.updateCategory(widget.item?["id"], payload);
      } else {
        msg = await AddonAdminService.createCategory(payload);
      }

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
                      isEdit ? "Edit Kategori Add-on" : "Tambah Kategori Add-on",
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
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: "Nama Kategori",
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v ?? "").trim().isEmpty ? "Nama wajib diisi" : null,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _descCtrl,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: "Deskripsi (opsional)",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text("Aktif"),
                value: _isActive,
                onChanged: (v) => setState(() => _isActive = v),
              ),

              const SizedBox(height: 16),

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
                      : Text(isEdit ? "Simpan Perubahan" : "Tambah Kategori"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

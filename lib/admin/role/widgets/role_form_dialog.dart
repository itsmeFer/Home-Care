import 'package:flutter/material.dart';
import 'package:home_care/admin/role/models/role_admin_models.dart';
import 'package:home_care/core/theme/app_colors.dart';

class RoleFormDialog extends StatefulWidget {
  final RoleModel? role;

  const RoleFormDialog({super.key, this.role});

  @override
  State<RoleFormDialog> createState() => _RoleFormDialogState();
}

class _RoleFormDialogState extends State<RoleFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameC;
  late TextEditingController _slugC;
  late TextEditingController _descC;
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    final r = widget.role;
    _nameC = TextEditingController(text: r?.name ?? '');
    _slugC = TextEditingController(text: r?.slug ?? '');
    _descC = TextEditingController(text: r?.description ?? '');
    _isDefault = r?.isDefault ?? false;
  }

  @override
  void dispose() {
    _nameC.dispose();
    _slugC.dispose();
    _descC.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final name = _nameC.text.trim();
    final slugText = _slugC.text.trim();
    final descText = _descC.text.trim();

    final payload = <String, dynamic>{
      'name': name,
      'slug': slugText.isEmpty ? null : slugText,
      'description': descText.isEmpty ? null : descText,
      'is_default': _isDefault,
    };

    Navigator.pop(context, payload);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.role != null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        isEdit ? 'Edit Role' : 'Tambah Role',
        style: const TextStyle(fontWeight: FontWeight.bold),
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
                  controller: _nameC,
                  decoration: const InputDecoration(
                    labelText: 'Nama Role',
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Nama role wajib diisi';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _slugC,
                  decoration: const InputDecoration(
                    labelText: 'Slug (boleh kosong, auto dari nama di backend)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _descC,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi (opsional)',
                    border: OutlineInputBorder(),
                  ),
                  minLines: 2,
                  maxLines: 4,
                ),
                const SizedBox(height: 10),
                SwitchListTile(
                  value: _isDefault,
                  title: const Text('Jadikan default untuk user baru'),
                  contentPadding: EdgeInsets.zero,
                  onChanged: (val) {
                    setState(() => _isDefault = val);
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
          child: Text(isEdit ? 'Simpan' : 'Tambah'),
        ),
      ],
    );
  }
}

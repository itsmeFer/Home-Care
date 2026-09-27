import 'package:flutter/material.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/admin/fee/models/fee_models.dart';
import 'package:home_care/admin/fee/widgets/create_user_dialog.dart';
import 'package:home_care/admin/fee/widgets/fee_ui_components.dart';
import 'package:home_care/admin/fee/widgets/user_picker_dialog.dart';

String get _kFeeRulesUrl => ApiConstants.adminFeeRules;
String get _kFeeAddonRulesUrl => ApiConstants.adminFeeAddonRules;

class FeeRuleFormDialog extends StatefulWidget {
  final FeeApiBridge api;
  final int itemId;
  final bool isAddon;
  final FeeRule? existing;

  const FeeRuleFormDialog({
    super.key,
    required this.api,
    required this.itemId,
    required this.isAddon,
    this.existing,
  });

  @override
  State<FeeRuleFormDialog> createState() => _FeeRuleFormDialogState();
}

class _FeeRuleFormDialogState extends State<FeeRuleFormDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  SelectableUser? _selectedUser;
  int? _userId;

  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _noHp = TextEditingController();
  final _bankNama = TextEditingController();
  final _bankKode = TextEditingController();
  final _noRek = TextEditingController();
  final _atasNama = TextEditingController();
  final _percent = TextEditingController();

  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    if (e != null) {
      _userId = e.userId;
      _nama.text = e.namaPenerima;
      _email.text = e.emailPenerima ?? '';
      _noHp.text = e.noHpPenerima ?? '';
      _bankNama.text = e.bankNama ?? '';
      _bankKode.text = e.bankKode ?? '';
      _noRek.text = e.noRekening ?? '';
      _atasNama.text = e.atasNamaRekening ?? '';
      _percent.text = e.percent.toString();
      _isActive = e.isActive;
    } else {
      _isActive = true;
      _percent.text = '';
    }
  }

  @override
  void dispose() {
    _nama.dispose();
    _email.dispose();
    _noHp.dispose();
    _bankNama.dispose();
    _bankKode.dispose();
    _noRek.dispose();
    _atasNama.dispose();
    _percent.dispose();
    super.dispose();
  }

  Future<void> _pickUser() async {
    final picked = await showDialog<SelectableUser>(
      context: context,
      barrierDismissible: false,
      builder: (_) => UserPickerDialog(api: widget.api, itemId: widget.itemId),
    );
    if (picked == null) return;

    setState(() {
      _selectedUser = picked;
      _userId = picked.id;
      _nama.text = picked.displayName;
      _email.text = picked.email;
      _noHp.text = picked.noHp ?? '';
    });
  }

  Future<void> _openCreateUser() async {
    double? percentVal;
    final ptxt = _percent.text.trim();
    if (ptxt.isNotEmpty) {
      percentVal = double.tryParse(ptxt.replaceAll(',', '.'));
      if (percentVal == null) {
        setState(() => _error = 'Percent tidak valid.');
        return;
      }
    }

    final created = await showDialog<CreatedUserResult>(
      context: context,
      barrierDismissible: false,
      builder:
          (_) => CreateUserDialog(
            api: widget.api,
            itemId: widget.itemId,
            isAddon: widget.isAddon,
            percent: percentVal,
          ),
    );

    if (created == null) return;

    setState(() {
      _selectedUser = SelectableUser(
        id: created.userId,
        role: created.role,
        email: created.email,
        displayName: created.name,
        noHp: created.noHp,
        fotoUrl: null,
      );
      _userId = created.userId;
      _nama.text = created.name;
      _email.text = created.email;
      _noHp.text = created.noHp ?? '';
    });

    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    if (_userId == null) {
      setState(() => _error = 'User wajib dipilih lewat pencarian.');
      return;
    }

    double? percentVal;
    final ptxt = _percent.text.trim();
    if (ptxt.isNotEmpty) {
      percentVal = double.tryParse(ptxt.replaceAll(',', '.'));
      if (percentVal == null) {
        setState(() => _error = 'Percent tidak valid.');
        return;
      }
    }

    final idKey = widget.isAddon ? 'addon_id' : 'layanan_id';

    final payload = <String, dynamic>{
      idKey: widget.itemId,
      'user_id': _userId,
      'bank_nama': _bankNama.text.trim().isEmpty ? null : _bankNama.text.trim(),
      'bank_kode':
          _bankKode.text.trim().isNotEmpty ? _bankKode.text.trim() : null,
      'no_rekening': _noRek.text.trim().isEmpty ? null : _noRek.text.trim(),
      'atas_nama_rekening':
          _atasNama.text.trim().isEmpty ? null : _atasNama.text.trim(),
      'percent': percentVal,
      'is_active': _isActive,
    };

    payload.removeWhere((k, v) => v == null);

    setState(() => _saving = true);
    try {
      final baseUrl = widget.isAddon ? _kFeeAddonRulesUrl : _kFeeRulesUrl;

      if (widget.existing == null) {
        await widget.api.postJson(baseUrl, payload);
      } else {
        await widget.api.putJson('$baseUrl/${widget.existing!.id}', payload);
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final itemLabel = widget.isAddon ? 'add-on' : 'layanan';

    return RoundedDialog(
      width: R.dialogWidth(context, max: 760),
      height: R.dialogHeight(context, max: 740),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit
                      ? 'Edit Penerima Fee $itemLabel'
                      : 'Tambah Penerima Fee $itemLabel',
                  style: const TextStyle(
                    color: kText,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                if (_error != null) ErrorBox(message: _error!),

                const FeeLabel('Pilih User (wajib)'),

                if (R.isPhone(context)) ...[
                  TextFormField(
                    controller: _nama,
                    readOnly: true,
                    style: const TextStyle(color: kText),
                    decoration: fieldDeco(
                      hint: 'Klik "Cari User" / "Buat User Baru"',
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    validator:
                        (_) => _userId == null ? 'User wajib dipilih.' : null,
                  ),
                  const SizedBox(height: 10),
                  RBtn(
                    filled: true,
                    onPressed: _saving ? null : _pickUser,
                    icon: Icons.search,
                    child: const Text('Cari User'),
                  ),
                  const SizedBox(height: 10),
                  RBtn(
                    filled: false,
                    onPressed: _saving ? null : _openCreateUser,
                    icon: Icons.person_add_alt_1,
                    child: const Text('Buat User Baru'),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _nama,
                          readOnly: true,
                          style: const TextStyle(color: kText),
                          decoration: fieldDeco(
                            hint: 'Klik "Cari User" / "Buat User Baru"',
                            prefixIcon: const Icon(Icons.person_outline),
                          ),
                          validator:
                              (_) =>
                                  _userId == null
                                      ? 'User wajib dipilih.'
                                      : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RBtn(
                          filled: true,
                          onPressed: _saving ? null : _pickUser,
                          icon: Icons.search,
                          child: const Text('Cari'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: RBtn(
                          filled: false,
                          onPressed: _saving ? null : _openCreateUser,
                          icon: Icons.person_add_alt_1,
                          child: const Text('Buat'),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 10),
                if (_selectedUser != null)
                  HintBox(
                    text:
                        'Dipilih: ${_selectedUser!.displayName} • ${_selectedUser!.role}',
                  ),

                const SizedBox(height: 12),
                const FeeLabel('Email (readonly)'),
                TextFormField(
                  controller: _email,
                  readOnly: true,
                  style: const TextStyle(color: kText),
                  decoration: fieldDeco(
                    hint: 'email@domain.com',
                    prefixIcon: const Icon(Icons.email_outlined),
                  ),
                ),

                const SizedBox(height: 12),
                const FeeLabel('No HP (readonly)'),
                TextFormField(
                  controller: _noHp,
                  readOnly: true,
                  style: const TextStyle(color: kText),
                  decoration: fieldDeco(
                    hint: '08xxxxxxxxxx',
                    prefixIcon: const Icon(Icons.phone_outlined),
                  ),
                ),

                const SizedBox(height: 12),
                const FeeLabel('Rekening (opsional)'),
                TextFormField(
                  controller: _bankNama,
                  style: const TextStyle(color: kText),
                  decoration: fieldDeco(
                    hint: 'Bank (BCA/BRI/...)',
                    prefixIcon: const Icon(Icons.account_balance_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _noRek,
                  style: const TextStyle(color: kText),
                  decoration: fieldDeco(
                    hint: 'No rekening',
                    prefixIcon: const Icon(Icons.numbers_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _atasNama,
                  style: const TextStyle(color: kText),
                  decoration: fieldDeco(
                    hint: 'Atas nama',
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                ),

                const SizedBox(height: 12),
                const FeeLabel('Persentase Fee (%)'),
                TextFormField(
                  controller: _percent,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  style: const TextStyle(color: kText),
                  decoration: fieldDeco(
                    hint: 'contoh: 25 atau 12.5',
                    prefixIcon: const Icon(Icons.percent),
                  ).copyWith(
                    helperText:
                        'Total persentase aktif per $itemLabel maksimal 100%',
                    helperStyle: const TextStyle(color: kTextSub),
                  ),
                  validator: (v) {
                    final s = (v ?? '').trim();
                    if (s.isEmpty) return null;
                    final val = double.tryParse(s.replaceAll(',', '.'));
                    if (val == null) return 'Percent tidak valid';
                    if (val < 0 || val > 100) return 'Percent harus 0 - 100';
                    return null;
                  },
                ),

                const SizedBox(height: 12),
                SwitchListTile.adaptive(
                  value: _isActive,
                  onChanged:
                      _saving ? null : (v) => setState(() => _isActive = v),
                  activeThumbColor: kPrimary,
                  activeTrackColor: kPrimary.withValues(alpha: 0.5),
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Aktif',
                    style: TextStyle(color: kText, fontWeight: FontWeight.w800),
                  ),
                  subtitle: Text(
                    _isActive
                        ? 'Penerima dihitung dalam pembagian %'
                        : 'Tidak ikut pembagian fee',
                    style: const TextStyle(color: kTextSub),
                  ),
                ),

                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: RBtn(
                        filled: false,
                        onPressed:
                            _saving
                                ? null
                                : () => Navigator.pop(context, false),
                        child: const Text('Batal'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RBtn(
                        filled: true,
                        onPressed: _saving ? null : _save,
                        child:
                            _saving
                                ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                                : Text(isEdit ? 'Simpan' : 'Tambah'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

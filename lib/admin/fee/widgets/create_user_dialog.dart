import 'package:flutter/material.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/admin/fee/models/fee_models.dart';
import 'package:home_care/admin/fee/widgets/fee_ui_components.dart';

String get _kFeeCreateUserUrl => ApiConstants.adminFeeCreateUser;
String get _kRolesUrl => ApiConstants.adminRoles;

class CreatedUserResult {
  final int userId;
  final String name;
  final String email;
  final String role;
  final String? noHp;

  CreatedUserResult({
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.noHp,
  });
}

class CreateUserDialog extends StatefulWidget {
  final FeeApiBridge api;
  final int itemId;
  final bool isAddon;
  final double? percent;

  const CreateUserDialog({
    super.key,
    required this.api,
    required this.itemId,
    required this.isAddon,
    required this.percent,
  });

  @override
  State<CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<CreateUserDialog> {
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;
  String? _error;

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _noHp = TextEditingController();
  final _password = TextEditingController();
  bool _obscurePassword = true;
  final _bankNama = TextEditingController();
  final _bankKode = TextEditingController();
  final _noRek = TextEditingController();
  final _atasNama = TextEditingController();

  List<RoleOption> _roleOptions = [];
  RoleOption? _selectedRole;
  bool _loadingRoles = true;

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _noHp.dispose();
    _password.dispose();
    _bankNama.dispose();
    _bankKode.dispose();
    _noRek.dispose();
    _atasNama.dispose();
    super.dispose();
  }

  Future<void> _loadRoles() async {
    setState(() => _loadingRoles = true);

    try {
      final res = await widget.api.getJson(
        _kRolesUrl,
        query: {'per_page': '100'},
      );
      final list = extractList(res);
      _roleOptions =
          list
              .map((e) => RoleOption.fromJson(e))
              .toList();

      if (_roleOptions.isNotEmpty) {
        _selectedRole ??= _roleOptions.first;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loadingRoles = false);
    }
  }

  String? _validatePassword(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    if (s.length < 8) return 'Password minimal 8 karakter.';
    final hasLetter = RegExp(r'[A-Za-z]').hasMatch(s);
    final hasDigit = RegExp(r'\d').hasMatch(s);
    if (!hasLetter || !hasDigit) {
      return 'Password harus kombinasi huruf dan angka.';
    }
    return null;
  }

  Future<void> _submit() async {
    setState(() => _error = null);
    if (!_formKey.currentState!.validate()) return;

    final idKey = widget.isAddon ? 'addon_id' : 'layanan_id';

    final payload = <String, dynamic>{
      idKey: widget.itemId,
      'name': _name.text.trim(),
      'email': _email.text.trim(),
      'password': _password.text.trim().isEmpty ? null : _password.text.trim(),
      'role': _selectedRole?.slug,
      'no_hp_penerima': _noHp.text.trim().isEmpty ? null : _noHp.text.trim(),
      'bank_nama': _bankNama.text.trim().isEmpty ? null : _bankNama.text.trim(),
      'bank_kode': _bankKode.text.trim().isEmpty ? null : _bankKode.text.trim(),
      'no_rekening': _noRek.text.trim().isEmpty ? null : _noRek.text.trim(),
      'atas_nama_rekening':
          _atasNama.text.trim().isEmpty ? null : _atasNama.text.trim(),
      'percent': widget.percent,
    };

    setState(() => _saving = true);
    try {
      final res = await widget.api.postJson(_kFeeCreateUserUrl, payload);
      final data = (res['data'] ?? {}) as Map<String, dynamic>;
      final user = (data['user'] ?? {}) as Map<String, dynamic>;

      final result = CreatedUserResult(
        userId: (user['id'] as num).toInt(),
        name: (user['name'] ?? '').toString(),
        email: (user['email'] ?? '').toString(),
        role: (user['role'] ?? '').toString(),
        noHp: payload['no_hp_penerima'] as String?,
      );

      if (mounted) Navigator.pop(context, result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _buildFieldPair({
    required Widget first,
    required Widget second,
    required bool isPhone,
  }) {
    if (isPhone) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [first, const SizedBox(height: 12), second],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: first),
        const SizedBox(width: 12),
        Expanded(child: second),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final itemLabel = widget.isAddon ? 'add-on' : 'layanan';
    final isPhone = R.isPhone(context);

    return RoundedDialog(
      width: R.dialogWidth(context, max: 760),
      height: R.dialogHeight(context, max: 680),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Buat User Baru (Sekaligus jadi penerima fee $itemLabel)',
                  style: const TextStyle(
                    color: kText,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),
                if (_error != null) ErrorBox(message: _error!),

                const FeeLabel('Nama'),
                TextFormField(
                  controller: _name,
                  style: const TextStyle(color: kText),
                  decoration: fieldDeco(
                    hint: 'Nama lengkap',
                    prefixIcon: const Icon(Icons.badge_outlined),
                  ),
                  validator:
                      (v) =>
                          (v ?? '').trim().isEmpty ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 12),

                _buildFieldPair(
                  isPhone: isPhone,
                  first: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FeeLabel('Email'),
                      TextFormField(
                        controller: _email,
                        style: const TextStyle(color: kText),
                        decoration: fieldDeco(
                          hint: 'email@domain.com',
                          prefixIcon: const Icon(Icons.email_outlined),
                        ),
                        validator: (v) {
                          final s = (v ?? '').trim();
                          if (s.isEmpty) return 'Email wajib diisi';
                          if (!s.contains('@')) return 'Email tidak valid';
                          return null;
                        },
                      ),
                    ],
                  ),
                  second: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const FeeLabel('No HP (opsional)'),
                      TextFormField(
                        controller: _noHp,
                        style: const TextStyle(color: kText),
                        decoration: fieldDeco(
                          hint: '08xxxxxxxxxx',
                          prefixIcon: const Icon(Icons.phone_outlined),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                const FeeLabel('Jabatan/Role'),
                _loadingRoles
                    ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(minHeight: 4),
                    )
                    : DropdownButtonFormField<RoleOption>(
                      initialValue: _selectedRole,
                      decoration: fieldDeco(
                        hint: 'Pilih role',
                        prefixIcon: const Icon(
                          Icons.admin_panel_settings_outlined,
                        ),
                      ),
                      items:
                          _roleOptions.map((r) {
                            return DropdownMenuItem<RoleOption>(
                              value: r,
                              child: Text(
                                r.name,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                      onChanged:
                          _saving
                              ? null
                              : (v) => setState(() => _selectedRole = v),
                      validator:
                          (v) =>
                              v == null ? 'Role/jabatan wajib dipilih.' : null,
                    ),

                const SizedBox(height: 12),
                const FeeLabel('Password (opsional)'),
                TextFormField(
                  controller: _password,
                  obscureText: _obscurePassword,
                  style: const TextStyle(color: kText),
                  decoration: fieldDeco(
                    hint: 'Kosongkan untuk auto-generate',
                    prefixIcon: const Icon(Icons.lock_outline),
                  ).copyWith(
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: kTextSub,
                      ),
                      onPressed:
                          () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    ),
                  ),
                  validator: _validatePassword,
                ),

                const SizedBox(height: 12),
                const FeeLabel('Rekening (opsional)'),

                _buildFieldPair(
                  isPhone: isPhone,
                  first: TextFormField(
                    controller: _bankNama,
                    style: const TextStyle(color: kText),
                    decoration: fieldDeco(
                      hint: 'Bank',
                      prefixIcon: const Icon(Icons.account_balance_outlined),
                    ),
                  ),
                  second: TextFormField(
                    controller: _bankKode,
                    style: const TextStyle(color: kText),
                    decoration: fieldDeco(
                      hint: 'Kode bank',
                      prefixIcon: const Icon(
                        Icons.confirmation_number_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildFieldPair(
                  isPhone: isPhone,
                  first: TextFormField(
                    controller: _noRek,
                    style: const TextStyle(color: kText),
                    decoration: fieldDeco(
                      hint: 'No rekening',
                      prefixIcon: const Icon(Icons.numbers_outlined),
                    ),
                  ),
                  second: TextFormField(
                    controller: _atasNama,
                    style: const TextStyle(color: kText),
                    decoration: fieldDeco(
                      hint: 'Atas nama',
                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                if (isPhone) ...[
                  RBtn(
                    filled: false,
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Batal'),
                  ),
                  const SizedBox(height: 10),
                  RBtn(
                    filled: true,
                    onPressed: _saving ? null : _submit,
                    child:
                        _saving
                            ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Text('Buat & Tambah'),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: RBtn(
                          filled: false,
                          onPressed:
                              _saving ? null : () => Navigator.pop(context),
                          child: const Text('Batal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RBtn(
                          filled: true,
                          onPressed: _saving ? null : _submit,
                          child:
                              _saving
                                  ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text('Buat & Tambah'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/core/network/api_client.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/features/fee_management/domain/fee_models.dart';
import 'package:home_care/features/fee_management/presentation/widgets/fee_ui_components.dart';

String get kFeeUsersUrl => ApiConstants.adminFeeUsers;
String get kFeeCreateUserUrl => ApiConstants.adminFeeCreateUser;
String get kRolesUrl => ApiConstants.adminRoles;
class UserPickerDialog extends StatefulWidget {
  final FeeApiBridge api;
  final int itemId;

  const UserPickerDialog({required this.api, required this.itemId});

  @override
  State<UserPickerDialog> createState() => _UserPickerDialogState();
}

class _UserPickerDialogState extends State<UserPickerDialog> {
  final _search = TextEditingController();
  bool _loading = false;
  String? _error;
  List<SelectableUser> _items = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final res = await widget.api.getJson(
        kFeeUsersUrl,
        query: {
          'per_page': '20',
          if (_search.text.trim().isNotEmpty) 'search': _search.text.trim(),
        },
      );

      final data = (res['data'] ?? {}) as Map<String, dynamic>;
      final list = (data['data'] ?? []) as List;
      _items =
          list
              .map((e) => SelectableUser.fromJson(e as Map<String, dynamic>))
              .toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return RoundedDialog(
      width: R.dialogWidth(context, max: 720),
      height: R.dialogHeight(context, max: 620),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Cari & Pilih User (kecuali pasien)',
              style: TextStyle(
                color: kText,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _search,
              style: const TextStyle(color: kText),
              decoration: fieldDeco(
                hint: 'Cari nama / email...',
                prefixIcon: const Icon(Icons.search),
              ),
              onSubmitted: (_) => _load(),
            ),
            const SizedBox(height: 12),
            if (_error != null) ErrorBox(message: _error!),
            Expanded(
              child:
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _items.isEmpty
                      ? const HintBox(text: 'User tidak ditemukan.')
                      : ListView.separated(
                        itemCount: _items.length,
                        separatorBuilder:
                            (_, __) => const Divider(color: kBorder, height: 1),
                        itemBuilder: (_, i) {
                          final u = _items[i];
                          return ListTile(
                            onTap: () => Navigator.pop(context, u),
                            leading: avatarCircle(
                              url: u.fotoUrl,
                              fallback: Icons.person,
                              radius: 20,
                            ),
                            title: Text(
                              u.displayName,
                              style: const TextStyle(
                                color: kText,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text(
                              '${u.role} • ${u.email}${(u.noHp ?? '').isNotEmpty ? ' • ${u.noHp}' : ''}',
                              style: const TextStyle(color: kTextSub),
                            ),
                            trailing: const Icon(
                              Icons.chevron_right,
                              color: kTextSub,
                            ),
                          );
                        },
                      ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: RBtn(
                    filled: false,
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Tutup'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: RBtn(
                    filled: true,
                    onPressed: _loading ? null : _load,
                    icon: Icons.refresh,
                    child: const Text('Cari'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

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
        kRolesUrl,
        query: {'per_page': '100'},
      );
      final list = extractList(res);
      _roleOptions =
          list
              .map((e) => RoleOption.fromJson(e as Map<String, dynamic>))
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
    if (!hasLetter || !hasDigit)
      return 'Password harus kombinasi huruf dan angka.';
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
      final res = await widget.api.postJson(kFeeCreateUserUrl, payload);
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

  @override
  Widget build(BuildContext context) {
    final itemLabel = widget.isAddon ? 'add-on' : 'layanan';

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

                if (R.isPhone(context)) ...[
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
                  const SizedBox(height: 12),
                  const FeeLabel('No HP (opsional)'),
                  TextFormField(
                    controller: _noHp,
                    style: const TextStyle(color: kText),
                    decoration: fieldDeco(
                      hint: '08xxxxxxxxxx',
                      prefixIcon: const Icon(Icons.phone_outlined),
                    ),
                  ),
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: Column(
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
                                if (!s.contains('@'))
                                  return 'Email tidak valid';
                                return null;
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
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
                    ],
                  ),
                ],

                const SizedBox(height: 12),
                const FeeLabel('Jabatan/Role'),
                _loadingRoles
                    ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: LinearProgressIndicator(minHeight: 4),
                    )
                    : DropdownButtonFormField<RoleOption>(
                      value: _selectedRole,
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

                if (R.isPhone(context)) ...[
                  TextFormField(
                    controller: _bankNama,
                    style: const TextStyle(color: kText),
                    decoration: fieldDeco(
                      hint: 'Bank',
                      prefixIcon: const Icon(Icons.account_balance_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _bankKode,
                    style: const TextStyle(color: kText),
                    decoration: fieldDeco(
                      hint: 'Kode bank',
                      prefixIcon: const Icon(
                        Icons.confirmation_number_outlined,
                      ),
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
                ] else ...[
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _bankNama,
                          style: const TextStyle(color: kText),
                          decoration: fieldDeco(
                            hint: 'Bank',
                            prefixIcon: const Icon(
                              Icons.account_balance_outlined,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
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
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _noRek,
                          style: const TextStyle(color: kText),
                          decoration: fieldDeco(
                            hint: 'No rekening',
                            prefixIcon: const Icon(Icons.numbers_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _atasNama,
                          style: const TextStyle(color: kText),
                          decoration: fieldDeco(
                            hint: 'Atas nama',
                            prefixIcon: const Icon(Icons.badge_outlined),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                if (R.isPhone(context)) ...[
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

class FeeRuleFormDialog extends StatefulWidget {
  final FeeApiBridge api;
  final int itemId;
  final bool isAddon;
  final FeeRule? existing;

  const FeeRuleFormDialog({
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
      final baseUrl = widget.isAddon ? kFeeAddonRulesUrl : kFeeRulesUrl;

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
                  activeColor: kPrimary,
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


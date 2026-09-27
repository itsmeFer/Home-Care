import 'package:flutter/material.dart';
import 'package:home_care/core/constants/api_constants.dart';
import 'package:home_care/admin/fee/models/fee_models.dart';
import 'package:home_care/admin/fee/widgets/fee_ui_components.dart';

String get _kFeeUsersUrl => ApiConstants.adminFeeUsers;

class UserPickerDialog extends StatefulWidget {
  final FeeApiBridge api;
  final int itemId;

  const UserPickerDialog({super.key, required this.api, required this.itemId});

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
        _kFeeUsersUrl,
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

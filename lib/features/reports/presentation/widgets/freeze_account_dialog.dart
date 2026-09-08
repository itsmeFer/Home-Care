import 'dart:async';
import 'package:flutter/material.dart';
import 'package:home_care/features/reports/presentation/widgets/audit_dialog_helpers.dart';

int _toInt(dynamic v) {
  if (v == null) return 0;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? 0;
}

class FreezeAccountDialog {
  static Future<void> show({
    required BuildContext context,
    required String token,
    required bool isDesktop,
    required Future<List<Map<String, dynamic>>> Function({
      required String token,
      String q,
    }) fetchFreezeUsers,
    required Future<void> Function({
      required int userId,
      required bool freeze,
      String reason,
    }) doFreezeAction,
    required void Function(String msg) toast,
  }) async {
// token passed in

    const kCard = Colors.white;
    const kBorder = Color(0xFFE2E8F0);
    const kText = Color(0xFF0F172A);
    const kMuted = Color(0xFF64748B);
    const kBg = Color(0xFFF8FAFC);

    const kDanger = Color(0xFFDC2626);
    const kInfo = Color(0xFF0284C7);

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {

        String q = '';
        bool loading = true;
        bool busyAction = false;
        String? err;
        bool didInit = false;

        final reasonCtrl = TextEditingController();
        final searchCtrl = TextEditingController();
        Timer? debounce;

        List<Map<String, dynamic>> items = [];

        Future<void> load(void Function(void Function()) setStateSB) async {
          setStateSB(() {
            loading = true;
            err = null;
          });

          try {
            final res = await fetchFreezeUsers(token: token, q: q);
            setStateSB(() {
              items = res;
              loading = false;
            });
          } catch (e) {
            setStateSB(() {
              loading = false;
              err = e.toString();
            });
          }
        }

        Widget userRow(
          Map<String, dynamic> u,
          void Function(void Function()) setStateSB,
        ) {
          final id = _toInt(u['id']);
          final name = (u['name'] ?? '-').toString();
          final email = (u['email'] ?? '-').toString();

          final roleMap =
              (u['role'] is Map) ? Map<String, dynamic>.from(u['role']) : null;
          final roleName = (roleMap?['name'] ?? '-').toString();
          final roleSlug = (roleMap?['slug'] ?? '-').toString();

          final ia = u['is_active'];
          final bool isActive =
              (ia is bool) ? ia : (ia == null ? true : ia.toString() == '1');
          final frozen = !isActive;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: kBorder),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color:
                        frozen
                            ? const Color(0xFFFEE2E2)
                            : const Color(0xFFE0F2FE),
                    border: Border.all(
                      color:
                          frozen
                              ? const Color(0xFFFECACA)
                              : const Color(0xFFBAE6FD),
                    ),
                  ),
                  child: Icon(
                    frozen ? Icons.lock_rounded : Icons.person_rounded,
                    color: frozen ? kDanger : kInfo,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: kText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: Colors.white,
                              border: Border.all(color: kBorder),
                            ),
                            child: Text(
                              roleName,
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                color: kMuted,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          color: kMuted,
                          fontSize: 12.4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color:
                                  frozen
                                      ? const Color(0xFFFEE2E2)
                                      : const Color(0xFFDCFCE7),
                              border: Border.all(
                                color:
                                    frozen
                                        ? const Color(0xFFFECACA)
                                        : const Color(0xFFBBF7D0),
                              ),
                            ),
                            child: Text(
                              frozen ? 'FROZEN' : 'ACTIVE',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color:
                                    frozen ? kDanger : const Color(0xFF15803D),
                                fontSize: 12,
                              ),
                            ),
                          ),
                          const Spacer(),
                          OutlinedButton.icon(
                            onPressed:
                                busyAction
                                    ? null
                                    : () async {
                                      final wantFreeze = !frozen;

                                      final ok = await showDialog<bool>(
                                        context: ctx,
                                        barrierDismissible: true,
                                        builder: (c2) {
                                          return AlertDialog(
                                            backgroundColor: kCard,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(18),
                                            ),
                                            title: Text(
                                              wantFreeze
                                                  ? 'Freeze Akun'
                                                  : 'Unfreeze Akun',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w900,
                                                color: kText,
                                              ),
                                            ),
                                            content: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  '$name ($roleSlug)',
                                                  style: const TextStyle(
                                                    color: kMuted,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 10),
                                                if (wantFreeze) ...[
                                                  const Text(
                                                    'Alasan (opsional)',
                                                    style: TextStyle(
                                                      color: kText,
                                                      fontWeight:
                                                          FontWeight.w900,
                                                      fontSize: 12.5,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 6),
                                                  TextField(
                                                    controller: reasonCtrl,
                                                    minLines: 2,
                                                    maxLines: 3,
                                                    decoration: InputDecoration(
                                                      hintText:
                                                          'contoh: pelanggaran SOP / akun bermasalah',
                                                      hintStyle:
                                                          const TextStyle(
                                                            color: Color(
                                                              0xFF94A3B8,
                                                            ),
                                                            fontWeight:
                                                                FontWeight.w700,
                                                          ),
                                                      filled: true,
                                                      fillColor: const Color(
                                                        0xFFF8FAFC,
                                                      ),
                                                      contentPadding:
                                                          const EdgeInsets.symmetric(
                                                            horizontal: 12,
                                                            vertical: 10,
                                                          ),
                                                      border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              14,
                                                            ),
                                                        borderSide:
                                                            const BorderSide(
                                                              color: kBorder,
                                                            ),
                                                      ),
                                                      enabledBorder:
                                                          OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  14,
                                                                ),
                                                            borderSide:
                                                                const BorderSide(
                                                                  color:
                                                                      kBorder,
                                                                ),
                                                          ),
                                                      focusedBorder:
                                                          OutlineInputBorder(
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                  14,
                                                                ),
                                                            borderSide:
                                                                const BorderSide(
                                                                  color: Color(
                                                                    0xFFBAE6FD,
                                                                  ),
                                                                ),
                                                          ),
                                                    ),
                                                  ),
                                                ] else ...[
                                                  const Text(
                                                    'Akun akan diaktifkan kembali.',
                                                    style: TextStyle(
                                                      color: kMuted,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed:
                                                    () => Navigator.pop(
                                                      c2,
                                                      false,
                                                    ),
                                                child: const Text(
                                                  'Batal',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                      wantFreeze
                                                          ? kDanger
                                                          : const Color(
                                                            0xFF16A34A,
                                                          ),
                                                  shape: RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          14,
                                                        ),
                                                  ),
                                                ),
                                                onPressed:
                                                    () =>
                                                        Navigator.pop(c2, true),
                                                child: Text(
                                                  wantFreeze
                                                      ? 'Freeze'
                                                      : 'Unfreeze',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      );

                                      if (ok != true) return;

                                      try {
                                        setStateSB(() => busyAction = true);

                                        await doFreezeAction(
                                          userId: id,
                                          freeze: wantFreeze,
                                          reason: reasonCtrl.text.trim(),
                                        );

                                        reasonCtrl.clear();
                                        toast(
                                          wantFreeze
                                              ? 'Akun berhasil di-freeze.'
                                              : 'Akun berhasil di-unfreeze.',
                                        );

                                        await load(setStateSB);

                                        setStateSB(() => busyAction = false);
                                      } catch (e) {
                                        setStateSB(() => busyAction = false);
                                        toast('Gagal: $e');
                                      }
                                    },
                            icon: Icon(
                              frozen
                                  ? Icons.lock_open_rounded
                                  : Icons.lock_rounded,
                              size: 18,
                              color: frozen ? const Color(0xFF16A34A) : kDanger,
                            ),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color:
                                    frozen
                                        ? const Color(0xFFBBF7D0)
                                        : const Color(0xFFFECACA),
                              ),
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            label: Text(
                              frozen ? 'Unfreeze' : 'Freeze',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                color:
                                    frozen ? const Color(0xFF16A34A) : kDanger,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return StatefulBuilder(
          builder: (context, setStateSB) {

            if (!didInit) {
              didInit = true;
              Future.microtask(() => load(setStateSB));
            }

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: isDesktop ? 860 : 520,
                  maxHeight: MediaQuery.of(context).size.height * 0.86,
                ),
                decoration: BoxDecoration(
                  color: kCard,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: kBorder),
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 30,
                      spreadRadius: 0,
                      offset: const Offset(0, 18),
                      color: Colors.black.withOpacity(0.14),
                    ),
                  ],
                ),
                child: Column(
                  children: [

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 14, 12, 10),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              color: const Color(0xFFFEE2E2),
                              border: Border.all(
                                color: const Color(0xFFFECACA),
                              ),
                            ),
                            child: const Icon(
                              Icons.gpp_maybe_outlined,
                              color: kDanger,
                            ),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Freeze Account',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: kText,
                                    fontSize: 16.2,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Cari user lalu freeze/unfreeze (Semua role).',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: kMuted,
                                    fontSize: 12.6,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed:
                                busyAction
                                    ? null
                                    : () {
                                      debounce?.cancel();
                                      Navigator.pop(ctx);
                                    },
                            icon: const Icon(
                              Icons.close_rounded,
                              color: kMuted,
                            ),
                            tooltip: 'Tutup',
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: searchCtrl,
                                  onChanged: (v) {
                                    debounce?.cancel();
                                    debounce = Timer(
                                      const Duration(milliseconds: 350),
                                      () {
                                        q = v;
                                        load(setStateSB);
                                      },
                                    );
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Cari nama / email...',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w700,
                                    ),
                                    filled: true,
                                    fillColor: kBg,
                                    prefixIcon: const Icon(
                                      Icons.search_rounded,
                                      color: kMuted,
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 12,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: kBorder,
                                      ),
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: kBorder,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      borderSide: const BorderSide(
                                        color: Color(0xFFBAE6FD),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              IconButton(
                                onPressed:
                                    busyAction ? null : () => load(setStateSB),
                                icon: const Icon(Icons.refresh_rounded),
                                tooltip: 'Refresh',
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),

                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: kBg,
                                  border: Border.all(color: kBorder),
                                ),
                                child: const Text(
                                  'Semua Role',
                                  style: TextStyle(
                                    color: kMuted,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.4,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  color: kBg,
                                  border: Border.all(color: kBorder),
                                ),
                                child: Text(
                                  'Total: ${items.length}',
                                  style: const TextStyle(
                                    color: kMuted,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        child:
                            loading
                                ? const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.6,
                                    ),
                                  ),
                                )
                                : (err != null)
                                ? DialogError(
                                  message: err!,
                                  onRetry: () => load(setStateSB),
                                )
                                : (items.isEmpty)
                                ? const DialogEmpty(
                                  title: 'Tidak ada data',
                                  subtitle: 'Coba ketik kata kunci lain.',
                                )
                                : ListView(
                                  children:
                                      items
                                          .map((u) => userRow(u, setStateSB))
                                          .toList(),
                                ),
                      ),
                    ),

                    Container(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                      decoration: const BoxDecoration(
                        border: Border(top: BorderSide(color: kBorder)),
                      ),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Freeze akan revoke token (user langsung logout).',
                              style: TextStyle(
                                color: kMuted,
                                fontWeight: FontWeight.w700,
                                fontSize: 12.4,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          TextButton(
                            onPressed:
                                busyAction
                                    ? null
                                    : () {
                                      debounce?.cancel();
                                      Navigator.pop(ctx);
                                    },
                            child: const Text(
                              'Tutup',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

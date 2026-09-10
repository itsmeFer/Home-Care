import 'package:flutter/material.dart';
import 'package:home_care/features/fee_management/domain/fee_models.dart';
import 'package:home_care/features/fee_management/presentation/widgets/fee_ui_components.dart';

class FeeRecipientCard extends StatefulWidget {
  final FeeRule rule;
  final num itemHargaFix;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const FeeRecipientCard({
    super.key,
    required this.rule,
    required this.itemHargaFix,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<FeeRecipientCard> createState() => _FeeRecipientCardState();
}

class _FeeRecipientCardState extends State<FeeRecipientCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.rule;
    final badgeColor = r.isActive ? kSuccess : kDanger;
    final num nominal =
        r.isActive ? (widget.itemHargaFix * (r.percent / 100)) : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: kCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                avatarCircle(
                  url: r.fotoUrl,
                  fallback: r.userId != null ? Icons.person : Icons.badge,
                  radius: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.namaPenerima,
                        style: const TextStyle(
                          color: kText,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          MiniChip(
                            text: r.isActive ? 'Aktif' : 'Nonaktif',
                            color: badgeColor,
                            icon:
                                r.isActive
                                    ? Icons.check_circle_outline
                                    : Icons.block_outlined,
                          ),
                          MiniChip(
                            text: 'Share: ${r.percent.toStringAsFixed(4)}%',
                            icon: Icons.percent,
                          ),
                          InkWell(
                            onTap: () => setState(() => _open = !_open),
                            borderRadius: BorderRadius.circular(100),
                            child: MiniChip(
                              text: _open ? 'Tutup nominal' : 'Lihat nominal',
                              icon:
                                  _open ? Icons.expand_less : Icons.expand_more,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: widget.onEdit,
                  icon: const Icon(Icons.edit, color: kTextSub),
                  tooltip: 'Edit',
                ),
                IconButton(
                  onPressed: widget.onDelete,
                  icon: const Icon(Icons.delete_outline, color: kTextSub),
                  tooltip: 'Nonaktifkan',
                ),
              ],
            ),
          ),
          InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedCrossFade(
              duration: const Duration(milliseconds: 180),
              crossFadeState:
                  _open ? CrossFadeState.showSecond : CrossFadeState.showFirst,
              firstChild: const SizedBox.shrink(),
              secondChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: kBorder, height: 18),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        MiniChip(
                          text: 'Harga: ${formatRupiah(widget.itemHargaFix)}',
                          icon: Icons.payments_outlined,
                        ),
                        MiniChip(
                          text: 'Nominal: ${formatRupiah(nominal)}',
                          icon: Icons.account_balance_wallet_outlined,
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if ((r.noHpPenerima ?? '').isNotEmpty ||
                        (r.emailPenerima ?? '').isNotEmpty)
                      Text(
                        '${r.noHpPenerima ?? '-'} • ${r.emailPenerima ?? '-'}',
                        style: const TextStyle(color: kTextSub),
                      ),
                    if ((r.bankNama ?? '').isNotEmpty ||
                        (r.noRekening ?? '').isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '${r.bankNama ?? '-'} • ${r.noRekening ?? '-'}',
                        style: TextStyle(
                          color: kTextSub.withValues(alpha: 0.9),
                        ),
                      ),
                      if ((r.atasNamaRekening ?? '').isNotEmpty)
                        Text(
                          'a/n ${r.atasNamaRekening}',
                          style: TextStyle(
                            color: kTextSub.withValues(alpha: 0.9),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

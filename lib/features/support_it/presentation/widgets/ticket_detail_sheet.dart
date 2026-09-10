import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/core/utils/app_formatters.dart';
import 'package:home_care/features/support_it/domain/support_it_models.dart';

class TicketDetailSheet extends StatelessWidget {
  final SupportTicket ticket;

  const TicketDetailSheet({super.key, required this.ticket});

  static Future<void> show(BuildContext context, SupportTicket ticket) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => TicketDetailSheet(ticket: ticket),
    );
  }

  static const Color _cardColor = AppColors.card;
  static const Color _borderColor = AppColors.border;
  static const Color _textColor = AppColors.textPrimary;
  static const Color _mutedColor = AppColors.textSecondary;
  static const Color _primaryColor = Color(0xFF0EA5E9);

  @override
  Widget build(BuildContext context) {
    final statusColor = ticket.statusColor;
    final priorityColor = ticket.priorityColor;

    return Container(
      height: MediaQuery.sizeOf(context).height * 0.8,
      decoration: const BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: _borderColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Detail Laporan #${ticket.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _textColor,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: _mutedColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          ticket.statusLabel,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: priorityColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.flag_rounded,
                              size: 12,
                              color: priorityColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              ticket.priorityLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: priorityColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Judul',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: _mutedColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ticket.subject,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: _textColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Deskripsi',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: _mutedColor,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ticket.description,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildInfoRow(
                    'Dibuat',
                    AppFormatters.formatDate(
                      ticket.createdAt,
                      pattern: 'dd MMM yyyy, HH:mm',
                    ),
                  ),
                  if (ticket.solvedAt != null && ticket.solvedAt!.isNotEmpty)
                    _buildInfoRow(
                      'Diselesaikan',
                      AppFormatters.formatDate(
                        ticket.solvedAt,
                        pattern: 'dd MMM yyyy, HH:mm',
                      ),
                    ),
                  if (ticket.itNotes != null && ticket.itNotes!.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Catatan IT',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: _mutedColor,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _primaryColor.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Text(
                        ticket.itNotes!,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _textColor,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: _mutedColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

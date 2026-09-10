import 'package:flutter/material.dart';
import 'package:home_care/core/theme/app_colors.dart';
import 'package:home_care/admin/fee/models/fee_models.dart';

class UserFeePickerCard extends StatelessWidget {
  final TextEditingController searchController;
  final bool isSearching;
  final List<SimpleUserOption> searchResults;
  final SimpleUserOption? selectedUser;
  final ValueChanged<SimpleUserOption> onUserSelected;
  final VoidCallback onSearch;
  final ValueChanged<String> onQueryChanged;

  const UserFeePickerCard({
    super.key,
    required this.searchController,
    required this.isSearching,
    required this.searchResults,
    required this.selectedUser,
    required this.onUserSelected,
    required this.onSearch,
    required this.onQueryChanged,
  });

  static const Color _card = AppColors.card;
  static const Color _border = AppColors.border;
  static const Color _text = AppColors.textPrimary;
  static const Color _textSub = AppColors.textSecondary;
  static const Color _primary = Color(0xFF2563EB);
  static const Color _bg = AppColors.background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pilih User Penerima Fee',
            style: TextStyle(
              color: _text,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Admin bisa mencari dan memilih user, lalu melihat catatan fee yang diterima user tersebut.',
            style: TextStyle(color: _textSub, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: 'Cari nama / email user...',
                    prefixIcon: const Icon(Icons.search, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _border),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _border),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                  ),
                  onChanged: onQueryChanged,
                  onSubmitted: (_) => onSearch(),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                height: 38,
                child: ElevatedButton(
                  onPressed: isSearching ? null : onSearch,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSearching
                      ? const SizedBox(
                          height: 16,
                          width: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Cari', style: TextStyle(fontSize: 13)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (isSearching)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            _buildUserSearchResultList(),
          if (selectedUser != null) ...[
            const Divider(height: 16),
            _buildSelectedUserInfo(selectedUser!),
          ],
        ],
      ),
    );
  }

  Widget _buildUserSearchResultList() {
    if (searchResults.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(top: 6),
        child: Text(
          'Tidak ada hasil. Coba kata kunci lain.',
          style: TextStyle(color: _textSub, fontSize: 12),
        ),
      );
    }

    return Column(
      children: searchResults.map((u) {
        final selected = selectedUser?.id == u.id;
        return InkWell(
          onTap: () => onUserSelected(u),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            margin: const EdgeInsets.only(top: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _bg : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? _primary.withValues(alpha: 0.6) : _border,
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: _primary.withValues(alpha: 0.1),
                  child: Text(
                    u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        u.name,
                        style: const TextStyle(
                          color: _text,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (u.email != null)
                        Text(
                          u.email!,
                          style: const TextStyle(
                            color: _textSub,
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                if (u.role != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _bg,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      u.role!,
                      style: const TextStyle(
                        color: _textSub,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectedUserInfo(SimpleUserOption u) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.info_outline, size: 18, color: _primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            'Sedang melihat catatan fee untuk: ${u.name}${u.email != null ? ' (${u.email})' : ''}',
            style: const TextStyle(color: _textSub, fontSize: 12),
          ),
        ),
      ],
    );
  }
}

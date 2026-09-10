import 'package:flutter/material.dart';
import 'package:home_care/core/widgets/skeletons/app_skeleton.dart';

/// Shimmer skeleton loader for chat room list tiles (Tokopedia/Shopee standard).
/// Matches exact layout and padding of ChatRoomTile to prevent layout shifts.
class ChatListSkeleton extends StatelessWidget {
  final int itemCount;

  const ChatListSkeleton({
    super.key,
    this.itemCount = 7,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x06000000),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Avatar skeleton
                const AppSkeleton(
                  width: 50,
                  height: 50,
                  borderRadius: 16,
                ),
                const SizedBox(width: 13),
                // Chat information skeleton
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Row(
                        children: [
                          Expanded(
                            child: AppSkeleton.text(
                              width: 140,
                              height: 15,
                              borderRadius: 4,
                            ),
                          ),
                          SizedBox(width: 8),
                          AppSkeleton.text(
                            width: 45,
                            height: 11,
                            borderRadius: 3,
                          ),
                        ],
                      ),
                      SizedBox(height: 7),
                      AppSkeleton.text(
                        width: 110,
                        height: 12,
                        borderRadius: 3,
                      ),
                      SizedBox(height: 7),
                      AppSkeleton.text(
                        width: double.infinity,
                        height: 13,
                        borderRadius: 3,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const AppSkeleton(
                  width: 18,
                  height: 18,
                  borderRadius: 9,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

import 'package:flutter/material.dart';

/// Global unread counter untuk badge icon chat (bottom nav)
class ChatUnreadCounter {
  static final ValueNotifier<int> totalUnread = ValueNotifier<int>(0);

  static void setTotal(int v) {
    totalUnread.value = v < 0 ? 0 : v;
  }

  static void clear() {
    totalUnread.value = 0;
  }
}
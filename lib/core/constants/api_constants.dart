class ApiConstants {
  ApiConstants._();

  static const String baseUrl = 'https://homecare.primamadanitalenta.my.id';
  static const String apiBase = '$baseUrl/api';
  static const String storageBase = '$baseUrl/storage';
  static const String mediaBase = '$baseUrl/media';

  static String? resolveMediaUrl(dynamic raw) {
    final s = (raw ?? '').toString().trim();
    if (s.isEmpty) return null;
    if (s.startsWith('http://') || s.startsWith('https://')) return s;
    if (s.startsWith('/storage/')) return '$baseUrl$s';
    if (s.startsWith('storage/')) return '$baseUrl/$s';
    if (s.startsWith('/media/')) return '$baseUrl$s';
    if (s.startsWith('media/')) return '$baseUrl/$s';
    return '$storageBase/$s';
  }

  // Auth
  static const String login = '$apiBase/login';
  static const String register = '$apiBase/register';
  static const String me = '$apiBase/me';
  static const String logout = '$apiBase/logout';
  static const String deleteAccount = '$apiBase/account/delete';
  static const String checkVerificationStatus =
      '$apiBase/check-verification-status';
  static const String resendVerification = '$apiBase/resend-verification';
  static const String forgotPassword = '$apiBase/forgot-password';
  static const String resetPassword = '$apiBase/reset-password';

  // FCM
  static const String fcmToken = '$apiBase/fcm/token';
  static const String fcmTokenUnverified = '$apiBase/fcm/token/unverified';
  static const String fcmTokens = '$apiBase/fcm/tokens';
  static const String fcmDeactivateToken = '$apiBase/fcm/token/deactivate';
  static const String fcmTestSend = '$apiBase/fcm/test-send';

  // Wilayah
  static const String wilayahProvinsi = '$apiBase/wilayah/provinsi';
  static String wilayahKota(dynamic provinsiId) =>
      '$apiBase/wilayah/kota/$provinsiId';
  static String wilayahKecamatan(dynamic kotaId) =>
      '$apiBase/wilayah/kecamatan/$kotaId';
  static String wilayahKelurahan(dynamic kecamatanId) =>
      '$apiBase/wilayah/kelurahan/$kecamatanId';
  static String wilayahKodePos(dynamic kelurahanId) =>
      '$apiBase/wilayah/kodepos/$kelurahanId';

  // Public
  static const String bannersPublik = '$apiBase/banners';
  static const String testimonials = '$apiBase/testimonials';
  static const String kategoriLayananPublik = '$apiBase/kategori-layanan';
  static const String kategoriLayananPublicList = '$apiBase/layanan/kategori';
  static const String notifications = '$apiBase/notifications';
  static const String notificationsUnreadCount =
      '$apiBase/notifications/unread-count';
  static const String notificationsReadAll = '$apiBase/notifications/read-all';
  static String notificationMarkRead(dynamic id) =>
      '$apiBase/notifications/$id/read';
  static const String chatUnreadSummary = '$apiBase/chat/unread-summary';

  // Support Tickets
  static const String supportTickets = '$apiBase/support-tickets';
  static String supportTicketDetail(dynamic id) =>
      '$apiBase/support-tickets/$id';
  static String supportTicketAssign(dynamic id) =>
      '$apiBase/support-tickets/$id/assign';
  static String supportTicketStatus(dynamic id) =>
      '$apiBase/support-tickets/$id/status';
  static String supportTicketITNotes(dynamic id) =>
      '$apiBase/support-tickets/$id/it-notes';

  // Pasien
  static String pasienProfile(dynamic id) => '$apiBase/pasien/$id';
  static String pasienFotoProfil(dynamic id) =>
      '$apiBase/pasien/$id/foto-profil';
  static const String pasienOrdersAktif = '$apiBase/pasien/orders/aktif';
  static const String pasienOrderDrafts = '$apiBase/pasien/order-drafts';
  static const String pasienOrderDraftStore = '$apiBase/pasien/order-draft';
  static String pasienOrderDraftDetail(dynamic draftId) =>
      '$apiBase/pasien/order-draft/$draftId';
  static String pasienOrderDraftStatus(dynamic draftId) =>
      '$apiBase/pasien/order-draft/$draftId/status';
  static String pasienOrderDraftCheckStatus(dynamic draftId) =>
      '$apiBase/pasien/order-draft/$draftId/check-status';
  static String pasienOrderDraftBayar(dynamic draftId) =>
      '$apiBase/pasien/order-draft/$draftId/bayar';
  static const String pasienHistoriOrder = '$apiBase/pasien/histori-order';
  static String pasienHistoriOrderDetail(dynamic id) =>
      '$apiBase/pasien/histori-order/$id';
  static const String pasienOrderLayanan = '$apiBase/pasien/order-layanan';
  static const String pasienOrderLayananBelumBayar =
      '$apiBase/pasien/order-layanan/belum-bayar';
  static String pasienOrderLayananDetail(dynamic id) =>
      '$apiBase/pasien/order-layanan/$id';
  static String pasienOrderCancel(dynamic id) =>
      '$apiBase/pasien/order-layanan/$id/cancel';
  static String pasienOrderCanCancel(dynamic id) =>
      '$apiBase/pasien/order-layanan/$id/can-cancel';
  static String pasienLayananAddons(dynamic layananId) =>
      '$apiBase/pasien/layanan/$layananId/addons';
  static const String layananSearch = '$apiBase/layanan/search';
  static const String pasienSearchHistory = '$apiBase/pasien/search-history';
  static const String pasienSearchHistoryClick =
      '$apiBase/pasien/search-history/click';
  static const String pasienRecentViewedLayanan =
      '$apiBase/pasien/recent-viewed-layanan';
  static const String pasienChatRooms = '$apiBase/pasien/chat-rooms';
  static const String pasienChatRoomsStart = '$apiBase/pasien/chat-rooms/start';
  static String pasienChatMessages(dynamic room) =>
      '$apiBase/pasien/chat-rooms/$room/messages';
  static String pasienChatEtalase(dynamic room) =>
      '$apiBase/pasien/chat-rooms/$room/etalase';
  static String pasienOrderRating(dynamic orderId) =>
      '$apiBase/pasien/order-layanan/$orderId/rating';

  // Admin Fee
  static const String adminFeeLayanan = '$apiBase/admin/fee/layanan';
  static const String adminFeeRules = '$apiBase/admin/fee/rules';
  static String adminFeeRuleDetail(dynamic id) =>
      '$apiBase/admin/fee/rules/$id';
  static String adminFeeRecalc(dynamic layananId) =>
      '$apiBase/admin/fee/rules/$layananId/recalc';
  static String adminFeeSimulate(dynamic layananId) =>
      '$apiBase/admin/fee/rules/$layananId/simulate';
  static const String adminFeeAddons = '$apiBase/admin/fee/addons';
  static const String adminFeeAddonRules = '$apiBase/admin/fee/addon-rules';
  static String adminFeeAddonRuleDetail(dynamic id) =>
      '$apiBase/admin/fee/addon-rules/$id';
  static String adminFeeAddonRecalc(dynamic addonId) =>
      '$apiBase/admin/fee/addon-rules/$addonId/recalc';
  static String adminFeeAddonSimulate(dynamic addonId) =>
      '$apiBase/admin/fee/addon-rules/$addonId/simulate';
  static const String adminFeeUsers = '$apiBase/admin/fee/users';
  static const String adminFeeSearchableUsers =
      '$apiBase/admin/fee/searchable-users';
  static const String adminFeeCreateUser = '$apiBase/admin/fee/create-user';
  static const String adminFeeOrders = '$apiBase/admin/fee/orders';
  static const String adminFeeCatatanUser = '$apiBase/admin/fee/catatan-user';
  static const String adminFeeUsersList = '$apiBase/admin/fee/users-list';
  static const String adminFeeUsersStatistics =
      '$apiBase/admin/fee/users-list/statistics';
  static const String adminFeeUsersRoles =
      '$apiBase/admin/fee/users-list/roles/all';

  // Admin Layanan & Kategori
  static const String adminLayanan = '$apiBase/layanan';
  static const String adminLayananListDropdown = '$apiBase/admin/layanan-list';
  static String adminLayananDetail(dynamic id) => '$apiBase/layanan/$id';
  static String adminLayananGambar(dynamic id) => '$apiBase/layanan/$id/gambar';
  static const String adminKategoriLayanan = '$apiBase/admin/kategori-layanan';
  static const String adminKategoriLayananUrutan =
      '$apiBase/admin/kategori-layanan/urutan';
  static String adminKategoriLayananDetail(dynamic id) =>
      '$apiBase/admin/kategori-layanan/$id';
  static String adminKategoriLayananGambar(dynamic id) =>
      '$apiBase/admin/kategori-layanan/$id/gambar';
  static String adminKategoriLayananToggle(dynamic id) =>
      '$apiBase/admin/kategori-layanan/$id/toggle';

  // Admin Banners
  static const String adminBanners = '$apiBase/admin/banners';
  static const String adminBannersUrutan = '$apiBase/admin/banners/urutan';
  static String adminBannerDetail(dynamic id) => '$apiBase/admin/banners/$id';
  static String adminBannerGambar(dynamic id) =>
      '$apiBase/admin/banners/$id/gambar';
  static String adminBannerToggle(dynamic id) =>
      '$apiBase/admin/banners/$id/toggle';

  // Admin Roles
  static const String adminRoles = '$apiBase/admin/roles';
  static const String adminRolesAssignFormData =
      '$apiBase/admin/roles/assign-form-data';
  static const String adminRolesAssign = '$apiBase/admin/roles/assign';
  static String adminUserRole(dynamic userId) =>
      '$apiBase/admin/users/$userId/role';
  static String adminRoleDetail(dynamic roleId) =>
      '$apiBase/admin/roles/$roleId';

  // Admin Addons
  static const String adminAddons = '$apiBase/admin/addons';
  static const String adminAddonCategories = '$apiBase/admin/addon-categories';
  static const String adminAddonCategoriesAll =
      '$apiBase/admin/addon-categories/all';
  static const String adminAddonCategoriesReorder =
      '$apiBase/admin/addon-categories/reorder';
  static String adminAddonDetail(dynamic id) => '$apiBase/admin/addons/$id';
  static String adminAddonToggle(dynamic id) =>
      '$apiBase/admin/addons/$id/toggle';

  // Admin Koordinator & Perawat
  static const String adminKoordinator = '$apiBase/admin/koordinator';
  static const String adminKoordinatorList = '$apiBase/admin/koordinator-list';
  static const String adminPerawat = '$apiBase/admin/perawat';
  static String adminPerawatDetail(dynamic id) => '$apiBase/admin/perawat/$id';
  static String adminPerawatAssignKoordinator(dynamic id) =>
      '$apiBase/admin/perawat/$id/assign-koordinator';
  static String adminPerawatFoto(dynamic id) =>
      '$apiBase/admin/perawat/$id/foto';
  static const String adminPerawatCrud = '$apiBase/admin/perawat-crud';
  static String adminPerawatCrudDetail(dynamic id) =>
      '$apiBase/admin/perawat-crud/$id';
  static String adminPerawatCrudPassword(dynamic id) =>
      '$apiBase/admin/perawat-crud/$id/password';
  static String adminPerawatCrudVerifikasi(dynamic id) =>
      '$apiBase/admin/perawat-crud/$id/verifikasi';

  // Admin Orders & Ratings
  static const String adminOrderLayanan = '$apiBase/admin/order-layanan';
  static String adminOrderLayananDetail(dynamic id) =>
      '$apiBase/admin/order-layanan/$id';
  static const String adminLayananRatings = '$apiBase/admin/layanan-ratings';
  static String adminLayananRatingComments(dynamic layananId) =>
      '$apiBase/admin/layanan/$layananId/rating-comments';
  static String adminLayananRatingSummary(dynamic layananId) =>
      '$apiBase/admin/layanan/$layananId/rating-summary';
  static String adminLayananKoordinator(dynamic layananId) =>
      '$apiBase/admin/layanan/$layananId/koordinator';

  // Perawat
  static const String perawatProfil = '$apiBase/perawat/profil';
  static const String perawatOrderLayanan = '$apiBase/perawat/order-layanan';
  static String perawatOrderDetail(dynamic id) =>
      '$apiBase/perawat/order-layanan/$id';
  static String perawatUploadBuktiBayar(dynamic id) =>
      '$apiBase/perawat/order-layanan/$id/upload-bukti-bayar';
  static String perawatOrderTerima(dynamic id) =>
      '$apiBase/perawat/order-layanan/$id/terima';
  static String perawatOrderTolak(dynamic id) =>
      '$apiBase/perawat/order-layanan/$id/tolak';
  static String perawatOrderSampai(dynamic id) =>
      '$apiBase/perawat/order-layanan/$id/sampai';
  static String perawatOrderMulaiVisit(dynamic id) =>
      '$apiBase/perawat/order-layanan/$id/mulai-visit';
  static String perawatOrderSelesai(dynamic id) =>
      '$apiBase/perawat/order-layanan/$id/selesai';
  static const String perawatChatRooms = '$apiBase/perawat/chat-rooms';
  static String perawatChatMessages(dynamic room) =>
      '$apiBase/perawat/chat-rooms/$room/messages';

  // Koordinator
  static const String koordinatorPerawatList =
      '$apiBase/koordinator/perawat-list';
  static const String koordinatorPerawat = '$apiBase/koordinator/perawat';
  static String koordinatorPerawatDetail(dynamic id) =>
      '$apiBase/koordinator/perawat/$id';
  static String koordinatorPerawatPassword(dynamic id) =>
      '$apiBase/koordinator/perawat/$id/password';
  static String koordinatorPerawatVerifikasi(dynamic id) =>
      '$apiBase/koordinator/perawat/$id/verifikasi';
  static const String koordinatorOrderLayanan =
      '$apiBase/koordinator/order-layanan';
  static String koordinatorOrderDetail(dynamic id) =>
      '$apiBase/koordinator/order-layanan/$id';
  static String koordinatorOrderAssign(dynamic id) =>
      '$apiBase/koordinator/order-layanan/$id/assign-perawat';
  static String koordinatorOrderStatus(dynamic id) =>
      '$apiBase/koordinator/order-layanan/$id/update-status';
  static const String koordinatorChatRooms = '$apiBase/koordinator/chat-rooms';
  static String koordinatorChatMessages(dynamic room) =>
      '$apiBase/koordinator/chat-rooms/$room/messages';
  static const String koordinatorPerawatRatings =
      '$apiBase/koordinator/perawat-ratings';
  static String koordinatorPerawatRatingSummary(dynamic perawatId) =>
      '$apiBase/koordinator/perawat/$perawatId/rating-summary';
  static String koordinatorPerawatRatingComments(dynamic perawatId) =>
      '$apiBase/koordinator/perawat/$perawatId/rating-comments';

  // Direktur & Manager
  static const String direkturDashboard = '$apiBase/direktur/dashboard';
  static const String direkturOverview = '$apiBase/direktur/dashboard/overview';
  static const String direkturKeuangan = '$apiBase/direktur/dashboard/keuangan';
  static const String direkturTim = '$apiBase/direktur/dashboard/tim';
  static const String direkturPasien = '$apiBase/direktur/dashboard/pasien';
  static const String direkturAudit = '$apiBase/direktur/dashboard/audit';
  static const String direkturFreezeUsers = '$apiBase/direktur/freeze/users';
  static String direkturFreezeUserDetail(dynamic id) =>
      '$apiBase/direktur/freeze/users/$id';
  static String direkturFreezeUser(dynamic id) =>
      '$apiBase/direktur/freeze/users/$id';
  static String direkturUnfreezeUser(dynamic id) =>
      '$apiBase/direktur/freeze/users/$id/unfreeze';

  static const String managerDashboard = '$apiBase/manager/dashboard';
  static const String managerOverview = '$apiBase/manager/dashboard/overview';
  static const String managerKeuangan = '$apiBase/manager/dashboard/keuangan';
  static const String managerTim = '$apiBase/manager/dashboard/tim';
  static const String managerPasien = '$apiBase/manager/dashboard/pasien';
  static const String managerAudit = '$apiBase/manager/dashboard/audit';

  // IT Developer
  static const String itMaintenanceStatus = '$apiBase/it/maintenance/status';
  static const String itMaintenanceActivate =
      '$apiBase/it/maintenance/activate';
  static const String itMaintenanceDeactivate =
      '$apiBase/it/maintenance/deactivate';
}

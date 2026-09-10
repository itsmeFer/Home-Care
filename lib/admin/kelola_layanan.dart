// Entrypoint for KelolaLayananPage
// Modular implementation resides in lib/admin/layanan/
export 'package:home_care/admin/layanan/kelola_layanan_page.dart';
export 'package:home_care/admin/layanan/services/layanan_admin_service.dart';

import 'package:home_care/core/constants/api_constants.dart';

/// Backward compatibility helper
String? resolveMediaUrl(String? raw) => ApiConstants.resolveMediaUrl(raw);

// Entrypoint for DetailLayananPage
// Modular implementation resides in lib/admin/detail_layanan/
export 'package:home_care/admin/detail_layanan/detail_layanan_page.dart';

import 'package:home_care/core/constants/api_constants.dart';

/// Legacy helper retained for backward compatibility.
String? resolveMediaUrl(String? raw) => ApiConstants.resolveMediaUrl(raw);

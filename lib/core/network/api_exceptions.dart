class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([String message = 'Sesi Anda telah berakhir. Silakan login kembali.'])
      : super(message, statusCode: 401);
}

class NotFoundException extends ApiException {
  NotFoundException([String message = 'Data yang diminta tidak ditemukan.'])
      : super(message, statusCode: 404);
}

class ValidationException extends ApiException {
  final Map<String, dynamic> errors;

  ValidationException(this.errors, [String message = 'Validasi data gagal.'])
      : super(message, statusCode: 422, details: errors);

  String get firstErrorMessage {
    if (errors.isEmpty) return message;
    final firstVal = errors.values.first;
    if (firstVal is List && firstVal.isNotEmpty) {
      return firstVal.first.toString();
    }
    return firstVal.toString();
  }
}

class NoInternetException extends ApiException {
  NoInternetException([String message = 'Koneksi internet terputus. Periksa jaringan Anda.'])
      : super(message, statusCode: 0);
}

class ServerException extends ApiException {
  ServerException([String message = 'Terjadi kesalahan pada server. Coba beberapa saat lagi.'])
      : super(message, statusCode: 500);
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic details;

  ApiException(this.message, {this.statusCode, this.details});

  @override
  String toString() => message;
}

class UnauthorizedException extends ApiException {
  UnauthorizedException([super.message = 'Sesi Anda telah berakhir. Silakan login kembali.'])
      : super(statusCode: 401);
}

class NotFoundException extends ApiException {
  NotFoundException([super.message = 'Data yang diminta tidak ditemukan.'])
      : super(statusCode: 404);
}

class ValidationException extends ApiException {
  final Map<String, dynamic> errors;

  ValidationException(this.errors, [super.message = 'Validasi data gagal.'])
      : super(statusCode: 422, details: errors);

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
  NoInternetException([super.message = 'Koneksi internet terputus. Periksa jaringan Anda.'])
      : super(statusCode: 0);
}

class ServerException extends ApiException {
  ServerException([super.message = 'Terjadi kesalahan pada server. Coba beberapa saat lagi.'])
      : super(statusCode: 500);
}

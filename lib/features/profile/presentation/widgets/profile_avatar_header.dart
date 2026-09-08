import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_iconly/flutter_iconly.dart';

class ProfileAvatarHeader extends StatelessWidget {
  final String nama;
  final String noRm;
  final String? email;
  final String? fotoProfilUrl;
  final File? localFotoFile;
  final bool isEditMode;
  final bool isUploadingFoto;
  final VoidCallback? onPickPhoto;

  static const Color _primary = Color(0xFF0BA5A7);
  static const Color _primaryDark = Color(0xFF088789);

  const ProfileAvatarHeader({
    super.key,
    required this.nama,
    required this.noRm,
    this.email,
    this.fotoProfilUrl,
    this.localFotoFile,
    this.isEditMode = false,
    this.isUploadingFoto = false,
    this.onPickPhoto,
  });

  Widget _buildAvatar() {
    final String initial = (nama.isNotEmpty ? nama[0] : '?').toUpperCase();

    if (!kIsWeb && localFotoFile != null) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: _primary,
        backgroundImage: FileImage(localFotoFile!),
      );
    }

    if (fotoProfilUrl != null && fotoProfilUrl!.isNotEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: _primary,
        child: ClipOval(
          child: Image.network(
            fotoProfilUrl!,
            width: 56,
            height: 56,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            },
          ),
        ),
      );
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: _primary,
      child: Text(
        initial,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 24,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!isEditMode) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_primary, _primaryDark],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              blurRadius: 20,
              offset: const Offset(0, 8),
              color: _primary.withValues(alpha: 0.22),
            ),
          ],
        ),
        child: Column(
          children: [
            _buildAvatar(),
            const SizedBox(height: 14),
            Text(
              nama,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 21,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'No. Rekam Medis: $noRm',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (email != null && email!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                email!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontSize: 13.5),
              ),
            ],
          ],
        ),
      );
    }

    // Edit mode
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            blurRadius: 20,
            offset: const Offset(0, 8),
            color: _primary.withValues(alpha: 0.22),
          ),
        ],
      ),
      child: Row(
        children: [
          Stack(
            children: [
              _buildAvatar(),
              Positioned(
                bottom: 0,
                right: 0,
                child: InkWell(
                  onTap: isUploadingFoto ? null : onPickPhoto,
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                          color: Colors.black.withValues(alpha: 0.12),
                        ),
                      ],
                    ),
                    child:
                        isUploadingFoto
                            ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                            : const Icon(
                              IconlyLight.camera,
                              size: 16,
                              color: _primary,
                            ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'No. Rekam Medis: $noRm',
                  style: const TextStyle(color: Colors.white70, fontSize: 13.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

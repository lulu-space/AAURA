import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads profile photos to the Supabase `avatars` storage bucket.
class AvatarRepository {
  static const _bucket = 'avatars';

  Future<String> upload({
    required String userId,
    required Uint8List bytes,
    required String contentType,
  }) async {
    final storage = Supabase.instance.client.storage.from(_bucket);
    final ext = contentType.contains('png')
        ? 'png'
        : contentType.contains('webp')
            ? 'webp'
            : 'jpg';
    final path = '$userId/avatar.$ext';
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: FileOptions(
        upsert: true,
        contentType: contentType,
      ),
    );
    final base = storage.getPublicUrl(path);
    return '$base?v=${DateTime.now().millisecondsSinceEpoch}';
  }
}

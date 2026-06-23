import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

/// Uploads CV files to the Supabase `cvs` storage bucket and returns a public
/// URL the app can open in the browser.
class CvRepository {
  static const _bucket = 'cvs';

  Future<String> upload({
    required String userId,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final storage = Supabase.instance.client.storage.from(_bucket);
    // One canonical object per user so re-uploading replaces the old CV.
    final path = '$userId/cv.pdf';
    await storage.uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(
        upsert: true,
        contentType: 'application/pdf',
      ),
    );
    final base = storage.getPublicUrl(path);
    // Cache-bust so a freshly replaced CV doesn't open the stale cached copy.
    return '$base?v=${DateTime.now().millisecondsSinceEpoch}';
  }
}

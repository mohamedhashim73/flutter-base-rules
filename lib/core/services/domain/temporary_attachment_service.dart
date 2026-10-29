import 'dart:typed_data';

import 'temporary_attachment_service_stub.dart'
    if (dart.library.html) 'temporary_attachment_service_web.dart';

class TemporaryAttachment {
  const TemporaryAttachment({
    required this.fileName,
    required this.mimeType,
    required this.bytes,
  });

  final String fileName;
  final String mimeType;
  final Uint8List bytes;
}

abstract interface class TemporaryAttachmentService {
  Future<TemporaryAttachment?> pickImage({bool camera = false});
}

TemporaryAttachmentService createTemporaryAttachmentService() =>
    createPlatformTemporaryAttachmentService();

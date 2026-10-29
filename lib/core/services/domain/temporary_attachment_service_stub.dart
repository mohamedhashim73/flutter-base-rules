import 'temporary_attachment_service.dart';

TemporaryAttachmentService createPlatformTemporaryAttachmentService() =>
    _UnsupportedTemporaryAttachmentService();

class _UnsupportedTemporaryAttachmentService
    implements TemporaryAttachmentService {
  @override
  Future<TemporaryAttachment?> pickImage({bool camera = false}) async => null;
}

import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

import 'temporary_attachment_service.dart';

TemporaryAttachmentService createPlatformTemporaryAttachmentService() =>
    _WebTemporaryAttachmentService();

class _WebTemporaryAttachmentService implements TemporaryAttachmentService {
  @override
  Future<TemporaryAttachment?> pickImage({bool camera = false}) {
    final completer = Completer<TemporaryAttachment?>();
    final input = html.FileUploadInputElement()
      ..accept = 'image/*'
      ..setAttribute('aria-label', camera ? 'التقاط صورة' : 'اختيار صورة');
    if (camera) input.setAttribute('capture', 'environment');
    input.onChange.listen((_) {
      final files = input.files;
      final file = files == null || files.isEmpty ? null : files.first;
      if (file == null) {
        if (!completer.isCompleted) completer.complete();
        return;
      }
      final reader = html.FileReader();
      reader.onLoadEnd.listen((_) {
        final result = reader.result;
        if (result is ByteBuffer) {
          completer.complete(
            TemporaryAttachment(
              fileName: file.name,
              mimeType: file.type,
              bytes: Uint8List.view(result),
            ),
          );
        } else if (!completer.isCompleted) {
          completer.complete();
        }
      });
      reader.onError.listen((_) {
        if (!completer.isCompleted) completer.complete();
      });
      reader.readAsArrayBuffer(file);
    });
    input.click();
    return completer.future;
  }
}

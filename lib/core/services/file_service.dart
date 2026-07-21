// import 'dart:io';
// import 'package:image_picker/image_picker.dart';
// import 'package:base/core/components/custom_dialogs_widget/show_toast.dart';
// import 'package:base/core/constants/enums/msg_type_enum.dart';
// import 'package:base/core/services/dependency_injection.dart';

// class FileService {
//   static final ImagePicker _imgPicker = sl<ImagePicker>();

//   static Future<File?> pickImgOnGallery({bool msgIsOn = false}) async {
//     try {
//       final XFile? image = await _imgPicker.pickImage(
//         source: ImageSource.gallery,
//         maxWidth: 1920,
//         maxHeight: 1080,
//         imageQuality: 85,
//       );
//       return image != null ? File(image.path) : null;
//     } catch (e) {
//       if (msgIsOn) {
//         AppToast.showToast(
//           message: 'Failed to pick image: ${e.toString()}',
//           type: MsgType.error,
//         );
//       }
//       return null;
//     }
//   }
// }

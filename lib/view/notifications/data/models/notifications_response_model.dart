import 'package:base/core/services/services.dart';
import 'package:base/model/domain/app_notification_model.dart';

class AppNotificationsResponseModel
    implements LoadableResponse<List<AppNotificationModel>> {
  const AppNotificationsResponseModel(this.data);
  @override
  final List<AppNotificationModel> data;
}

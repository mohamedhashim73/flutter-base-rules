import 'package:base/core/utils/utils.dart';
import 'package:base/model/base/base_response.dart';
import 'package:base/model/notification_model.dart';
import 'package:base/model/base/pagination_model.dart';

class NotificationsResponseModel
    implements
        PaginatedResponse<List<NotificationModel>, NotificationsResponseModel> {
  @override
  final List<NotificationModel> data;

  @override
  final PaginationModel? pagination;

  const NotificationsResponseModel({required this.data, this.pagination});

  factory NotificationsResponseModel.fromJson(dynamic json) {
    final response = asMapOr(json, 'data', fallback: json);

    return NotificationsResponseModel(
      data: asListOr(
        response,
        'data',
      ).map((e) => NotificationModel.fromJson(e)).toList(),
      pagination: asMapOrNull(response, 'pagination') != null
          ? PaginationModel.fromJson(asMapOr(response, 'pagination'))
          : null,
    );
  }

  @override
  NotificationsResponseModel copyWithPagination({
    required List<dynamic> data,
    required PaginationModel? pagination,
  }) {
    return NotificationsResponseModel(
      data: data.cast<NotificationModel>(),
      pagination: pagination,
    );
  }

  NotificationsResponseModel copyWith({
    List<NotificationModel>? data,
    PaginationModel? pagination,
  }) {
    return NotificationsResponseModel(
      data: data ?? this.data,
      pagination: pagination ?? this.pagination,
    );
  }

  @override
  String toString() {
    return 'NotificationsResponseModel('
        'dataLength: ${data.length}, '
        'currentPage: ${pagination?.currentPage}, '
        'totalPages: ${pagination?.totalPages}, '
        'total: ${pagination?.total}'
        ')';
  }
}

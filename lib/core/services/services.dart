import 'package:base/core/network/network.dart';
import 'package:base/core/utils/utils.dart';
import 'package:get_it/get_it.dart';
import 'package:base/core/enums/enums.dart';
import 'package:base/model/base/request_state.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:base/core/constants/constants.dart';
import 'package:base/core/extensions/extensions.dart';
import 'package:base/core/routes/routes.dart';
import 'package:base/core/theme/theme.dart';
import 'package:flutter/cupertino.dart';
import 'dart:developer';
import 'package:flutter/foundation.dart';
import 'package:base/core/widgets/widgets.dart';
import 'package:base/model/user_model.dart';
import 'domain/firebase_auth_service.dart';
import 'domain/firebase_service.dart';
import 'domain/audit_service.dart';
import 'domain/finance_settings_service.dart';
import 'domain/in_app_notification_service.dart';
import 'domain/notification_preferences_service.dart';
import 'domain/web_push_notification_service.dart';
import 'domain/firebase_cache_service.dart';
import 'domain/temporary_attachment_service.dart';

export 'domain/firebase_auth_service.dart';
export 'domain/firebase_service.dart';
export 'domain/audit_service.dart';
export 'domain/finance_settings_service.dart';
export 'domain/in_app_notification_service.dart';
export 'domain/notification_preferences_service.dart';
export 'domain/web_push_notification_service.dart';
export 'domain/firebase_cache_service.dart';
export 'domain/print_service.dart';
export 'domain/temporary_attachment_service.dart';

part 'base/asset_service.dart';
part 'base/data_state_helper.dart';
part 'base/debouncer.dart';
part 'base/incremental_sync_merger.dart';
part 'base/pagination_manager.dart';
part 'base/safe_executer.dart';
part 'base/scroll_manager.dart';
part 'base/search_manager.dart';
part 'base/date_time_picker_service.dart';
part 'base/dependency_injection.dart';
part 'base/file_service.dart';
part 'base/location_service.dart';
part 'base/logging_service.dart';
part 'base/share_service.dart';
part 'base/system_ui_service.dart';
part 'base/url_launcher_service.dart';
part 'base/user_session_service.dart';

abstract interface class LoadableResponse<T> {
  T? get data;
}

abstract interface class PaginatedResponse<T, R> {
  T get data;
  PaginationModel? get pagination;

  R copyWithPagination({
    required List<dynamic> data,
    required PaginationModel? pagination,
  });
}

class PaginationModel {
  const PaginationModel({
    required this.total,
    required this.count,
    required this.perPage,
    required this.currentPage,
    required this.totalPages,
  });

  final int total;
  final int count;
  final int perPage;
  final int currentPage;
  final int totalPages;

  bool get hasNext => currentPage < totalPages;

  factory PaginationModel.fromJson(
    Map<String, dynamic> json,
  ) => PaginationModel(
    total: (json['total'] as num? ?? 0).toInt(),
    count: (json['count'] as num? ?? 0).toInt(),
    perPage: (json['per_page'] as num? ?? json['perPage'] as num? ?? 0).toInt(),
    currentPage:
        (json['current_page'] as num? ?? json['currentPage'] as num? ?? 1)
            .toInt(),
    totalPages: (json['total_pages'] as num? ?? json['totalPages'] as num? ?? 1)
        .toInt(),
  );
}

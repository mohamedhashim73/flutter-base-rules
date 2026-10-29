import 'package:base/core/services/services.dart';
import 'package:base/view/credit_cards/data/datasource/credit_cards_data_source.dart';
import 'package:base/view/credit_cards/data/datasource/firebase_credit_cards_data_source.dart';
import 'package:base/view/credit_cards/data/repository/credit_cards_repository.dart';
import 'package:base/view/credit_cards/data/repository/credit_cards_repository_impl.dart';
import 'package:base/view/credit_cards/ui/controllers/credit_cards_cubit/credit_cards_cubit.dart';
import 'package:base/view/auth/ui/controllers/auth_cubit/auth_cubit.dart';
import 'package:base/view/operations/data/datasource/operations_data_source.dart';
import 'package:base/view/operations/data/datasource/firebase_operations_data_source.dart';
import 'package:base/view/operations/data/repository/operations_repository.dart';
import 'package:base/view/operations/data/repository/operations_repository_impl.dart';
import 'package:base/view/operations/ui/controllers/operations_cubit/operations_cubit.dart';
import 'package:base/view/notifications/data/datasource/notifications_data_source.dart';
import 'package:base/view/notifications/data/datasource/firebase_notifications_data_source.dart';
import 'package:base/view/notifications/data/repository/notifications_repository.dart';
import 'package:base/view/notifications/data/repository/notifications_repository_impl.dart';
import 'package:base/view/notifications/ui/controllers/notifications_cubit/notifications_cubit.dart';
import 'package:base/view/users/data/repository/users_repository.dart';
import 'package:base/view/users/data/repository/users_repository_impl.dart';
import 'package:base/view/users/ui/controllers/users_cubit/users_cubit.dart';
import 'package:base/view/audit/data/datasource/audit_data_source.dart';
import 'package:base/view/audit/data/datasource/firebase_audit_data_source.dart';
import 'package:base/view/audit/data/repository/audit_repository.dart';
import 'package:base/view/audit/data/repository/audit_repository_impl.dart';
import 'package:base/view/audit/ui/controllers/audit_cubit/audit_cubit.dart';

void registerAppDependencies() {
  if (!sl.isRegistered<AuditDataSource>()) {
    sl.registerLazySingleton<AuditDataSource>(
      () => FirebaseAuditDataSource(sl<FirebaseService>()),
    );
  }
  if (!sl.isRegistered<AuditRepository>()) {
    sl.registerLazySingleton<AuditRepository>(
      () => AuditRepositoryImpl(sl<AuditDataSource>()),
    );
  }
  if (!sl.isRegistered<AuditCubit>()) {
    sl.registerFactory<AuditCubit>(() => AuditCubit(sl<AuditRepository>()));
  }
  if (!sl.isRegistered<CreditCardsDataSource>()) {
    sl.registerLazySingleton<CreditCardsDataSource>(
      () => FirebaseCreditCardsDataSource(
        sl<FirebaseService>(),
        sl<FirebaseCacheService>(),
      ),
    );
  }
  if (!sl.isRegistered<CreditCardsRepository>()) {
    sl.registerLazySingleton<CreditCardsRepository>(
      () => CreditCardsRepositoryImpl(
        sl<CreditCardsDataSource>(),
        sl<FirebaseAuthService>(),
        sl<AuditService>(),
        sl<FinanceSettingsService>(),
      ),
    );
  }
  if (!sl.isRegistered<CreditCardsCubit>()) {
    sl.registerFactory<CreditCardsCubit>(
      () => CreditCardsCubit(sl<CreditCardsRepository>()),
    );
  }
  if (!sl.isRegistered<AuthCubit>()) {
    sl.registerFactory<AuthCubit>(() => AuthCubit(sl<FirebaseAuthService>()));
  }
  if (!sl.isRegistered<OperationsDataSource>()) {
    sl.registerLazySingleton<OperationsDataSource>(
      () => FirebaseOperationsDataSource(
        sl<FirebaseService>(),
        sl<FirebaseCacheService>(),
      ),
    );
  }
  if (!sl.isRegistered<OperationsRepository>()) {
    sl.registerLazySingleton<OperationsRepository>(
      () => OperationsRepositoryImpl(
        sl<OperationsDataSource>(),
        sl<FirebaseAuthService>(),
        sl<AuditService>(),
        sl<FinanceSettingsService>(),
        sl<InAppNotificationService>(),
      ),
    );
  }
  if (!sl.isRegistered<OperationsCubit>()) {
    sl.registerFactory<OperationsCubit>(
      () => OperationsCubit(
        sl<OperationsRepository>(),
        sl<CreditCardsRepository>(),
      ),
    );
  }
  if (!sl.isRegistered<NotificationsDataSource>()) {
    sl.registerLazySingleton<NotificationsDataSource>(
      () => FirebaseNotificationsDataSource(sl<FirebaseService>()),
    );
  }
  if (!sl.isRegistered<NotificationsRepository>()) {
    sl.registerLazySingleton<NotificationsRepository>(
      () => NotificationsRepositoryImpl(sl<NotificationsDataSource>()),
    );
  }
  if (!sl.isRegistered<NotificationsCubit>()) {
    sl.registerFactory<NotificationsCubit>(
      () => NotificationsCubit(sl<NotificationsRepository>()),
    );
  }
  if (!sl.isRegistered<UsersRepository>()) {
    sl.registerLazySingleton<UsersRepository>(
      () =>
          UsersRepositoryImpl(sl<FirebaseService>(), sl<FirebaseAuthService>()),
    );
  }
  if (!sl.isRegistered<UsersCubit>()) {
    sl.registerFactory<UsersCubit>(() => UsersCubit(sl<UsersRepository>()));
  }
}

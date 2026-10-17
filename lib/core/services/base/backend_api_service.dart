part of '../services.dart';

/// App-owned configuration for the provider-neutral API client.
///
/// Feature data sources use [client]; transport, authorization, token refresh,
/// request logging and failure mapping remain inside `backend_sdk`.
class BackendApiService {
  static const int perPage = 10;

  BackendApiService()
    : client = ApiClient(
        configuration: const ApiConfiguration(
          baseUrl: ApiEndpoints.baseUrl,
          isLoggingOn: kDebugMode,
        ),
        session: ApiSessionConfiguration(
          accessTokenProvider: () => CacheManager.getUser?.accessToken,
          refreshTokenProvider: () => CacheManager.getUser?.refreshToken,
          localeProvider: () => CacheManager.getLanguage().name,
          onTokensUpdated: (tokens) async {
            final user = CacheManager.getUser;
            if (user == null) return;
            await CacheManager.setUser(
              user.copyWith(
                accessToken: tokens.accessToken,
                refreshToken: tokens.refreshToken,
              ),
            );
          },
          onSessionExpired: () =>
              UserSessionService.validateSessionExpire(isExpired: true),
          refreshPath: ApiEndpoints.refreshToken,
        ),
      );

  final ApiClient client;

  void resetSessionExpiryGuard() => client.resetSessionExpiryGuard();
}

class ApiEndpoints {
  static const String baseUrl = "https://raghwa.ahmedgamal.org/api/v1/";

  static const String sendOtp = "auth/register/send-otp";
  static const String verifyOtp = "auth/register/verify-otp";
  static const String verifyLogin = "auth/verify-login";
  static const String completeSignUp = "auth/register/complete";
  static String compounds({double? lat, double? lon}) {
    String endpoint = "auth/compounds";
    final queryParams = <String, String>{};
    if (lat != null) queryParams['lat'] = lat.toString();
    if (lon != null) queryParams['lon'] = lon.toString();
    if (queryParams.isNotEmpty) {
      final query = queryParams.entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      endpoint = '$endpoint?$query';
    }
    return endpoint;
  }

  /// Profile
  static const String profile = "profile";
  static const String updateProfile = "profile/update-data";
  static const String changeLanguage = "profile/change-language";

  /// Addresses
  static const String addresses = "addresses";
  static const String governorates = "governorates";
  static String cities(dynamic id) => "cities?governorate_id=$id";
  static String makeAddressDefault(dynamic id) => "$addresses/$id/make-default";

  /// Oil
  static const String oil = "oil-collection";
  static const String oilPolicies = "$oil/policies";
  static const String oilHistory = "$oil/history";
  static const String oilDeliverySlots = "$oil/delivery-slots";
  static const String requestOil = "$oil/request";
  static String oilRequestDetail(dynamic id) => "$oil/request/$id";
  static String cancelOilRequest(dynamic id) => "oil-collection/request/$id/cancel";
  static const String oilAvailableProducts = "$oil/available-products";

  /// Mixtures
  static const String mixtures = "mixes";
  static const String ingredients = "$mixtures/ingredients";
  static const String calculatePrice = "$mixtures/calculate-price";
  static String incrementMixQuantity(dynamic id) => "$mixtures/$id/increment";

  /// Orders
  static const String orders = "store/orders";
  static String orderDetail(dynamic id) => "store/orders/$id";
  static String cancelOrder(dynamic id) => "store/orders/$id/cancel";
  static String reorder(dynamic id) => "store/orders/$id/reorder";
  static String refundOrder(dynamic id) => "store/orders/$id/refund";
  static String kashierInitiate(dynamic id) => "kashier/initiate/$id";
  static const String refundRequests = "store/refunds";
  static const String refundReasons = "orders/refund-reasons";

  /// Market
  static const String market = "market";
  static const String addMarketCart = "cart/add";
  static const String getMarketCart = "cart";
  static const String updateMarketMultipleCart = "cart/update-multiple";
  static const String products = "market/products";
  static const String home = "$market/home";
  static String productDetails(dynamic id) => "$market/products/$id";

  /// Auth
  static const String deleteAccount = "auth/account";
  static const String logOut = "auth/logout";
  static const String googleLogin = "auth/google-login";
  static const String appleLogin = "auth/apple-login";

  /// Leaderboard
  static const String leaderboard = "gamification/leaderboard";

  /// Notifications
  static const String notifications = "notifications";
  static const String readAllNotifications = "$notifications/read-all";
  static String readNotification(dynamic id) => "$notifications/$id/read";

  /// Spin Wheel
  static const String spinWheel = "spin-wheel";
  static const String spinWheelSpin = "$spinWheel/spin";
}

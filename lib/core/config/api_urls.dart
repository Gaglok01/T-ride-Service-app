/// API base URL and endpoint constants for T-Ride.
/// Structure follows MVVM - config lives in core layer.
class ApiUrls {
  ApiUrls._();

  static const String baseUrl = 'https://order.t-ride.tech/';

  // Languages
  static const String languages = 'api/languages';

  // Roles
  static const String roles = 'api/roles';

  // Auth
  static const String login = 'api/app/login';
  static const String sendOtp = 'api/app/send-otp';
  static const String verifyOtp = 'api/app/verify-otp';
  static const String register = 'api/app/register';
  static const String logout = 'api/logout';
  static const String appLogout = 'api/app/logout';

  // Profile
  static const String getProfile = 'api/app/get-profile';
  static const String updateProfile = 'api/app/update-profile';

  // Feedback
  static const String submitFeedback = 'api/app/submit-feedback';

  // Location
  static const String saveLocation = 'api/app/save-location';

  // Recent activity
  static const String recentActivity = 'api/app/recent-activity';

  // Rides
  static const String ridesEstimate = 'api/app/rides/estimate';
  static const String ridesNearbyDrivers = 'api/app/rides/nearby-drivers';
  static const String ridesRequest = 'api/app/rides/request';
  static const String ridesActive = 'api/app/rides/active';
  static const String couponApply = 'api/app/coupon/apply';

  // Courier
  static const String courierEstimate = 'api/app/courier/estimate';
  static const String courierRequest = 'api/app/courier/request';
  static const String courierNearby = 'api/app/courier/nearby';
  static const String courierActive = 'api/app/courier/active';

  // Food delivery
  static const String foodHome = 'api/app/food/home';
  static const String foodVendor = 'api/app/food/vendor';
  static const String foodProduct = 'api/app/food/product';
  static const String foodOrderPlace = 'api/app/food/order/place';

  // Rental
  static const String rentalItems = 'api/app/rental/items';
  static const String rentalItemDetails = 'api/app/rental/item';
  static const String rentalBook = 'api/app/rental/book';

  // Stripe payments
  static const String stripeCreatePaymentIntent =
      'api/stripe/create-payment-intent';

  // Add more endpoints as you integrate APIs
  // static const String profile = 'api/profile';
  // static const String rides = 'api/rides';
}

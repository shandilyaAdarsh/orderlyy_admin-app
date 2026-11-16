class ApiConstants {
  static const String apiVersion = '/api/v1';

  // Auth Endpoints
  static const String login = '$apiVersion/auth/login';
  static const String logout = '$apiVersion/auth/logout';
  static const String refreshToken = '$apiVersion/auth/refresh';
  static const String changePassword = '$apiVersion/auth/change-password';
  static const String setFirstLoginPassword = '$apiVersion/auth/set-password';

  // Restaurant Context Endpoints
  static const String restaurantContext = '$apiVersion/context/bootstrap';
  static const String currentTenant = '$apiVersion/tenants/current';
  static const String selectOrganization = '$apiVersion/tenants/select';

  // Menu & Catalog Endpoints
  static String categories(String tenantId) => '$apiVersion/tenants/$tenantId/menu/categories';
  static String menuItems(String tenantId) => '$apiVersion/tenants/$tenantId/menu/items';
  static String pricing(String tenantId) => '$apiVersion/tenants/$tenantId/pricing';
  static String taxes(String tenantId) => '$apiVersion/tenants/$tenantId/tax/profiles';
  static String modifiers(String tenantId) => '$apiVersion/tenants/$tenantId/modifier/groups';
  static String itemRecommendations(String tenantId, String itemId) =>
      '${menuItems(tenantId)}/$itemId/recommendations';
  static String recommendation(String tenantId, String recId) =>
      '$apiVersion/tenants/$tenantId/menu/recommendations/$recId';
  static String deactivateRecommendation(String tenantId, String recId) =>
      '${recommendation(tenantId, recId)}/deactivate';
  static String reactivateRecommendation(String tenantId, String recId) =>
      '${recommendation(tenantId, recId)}/reactivate';

  // Operational Endpoints
  static String get tables => '$apiVersion/admin/tables';
  static const String availability = '$apiVersion/availability';
  static const String orders = '$apiVersion/orders';
  static const String staff = '$apiVersion/staff';

  // Analytics & Settings
  static const String analytics = '$apiVersion/analytics';
  static const String settings = '$apiVersion/settings';

  // Runtime Observability
  static const String runtimeObservability =
      '$apiVersion/runtime/observability';
  static const String runtimeCertify = '$apiVersion/runtime/certify';
}

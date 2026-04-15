import 'package:http/http.dart' as http;
import 'api_client.dart';
import 'auth_service.dart';

class ApiService {
  static String get baseUrl => ApiClient.baseUrl;

  // ─── Token helpers (Bridge to AuthService) ────────────────────────────────
  static Future<String?> getToken() async => await AuthService.getToken();
  static Future<void> saveToken(String token) async {
    final refreshToken = await AuthService.getRefreshToken();
    if (refreshToken != null) {
      await AuthService.saveTokens(token: token, refreshToken: refreshToken);
    }
  }
  static Future<void> clearToken() async => await AuthService.logout();

  // ─── API Methods (Delegated to ApiClient with Refresh Logic) ──────────────
  static Future<http.Response> get(String endpoint) {
    return ApiClient.request('GET', endpoint);
  }

  static Future<http.Response> post(String endpoint, Map<String, dynamic> body) {
    return ApiClient.request('POST', endpoint, body: body);
  }

  static Future<http.Response> put(String endpoint, Map<String, dynamic> body) {
    return ApiClient.request('PUT', endpoint, body: body);
  }

  static Future<http.Response> patch(String endpoint, Map<String, dynamic> body) {
    return ApiClient.request('PATCH', endpoint, body: body);
  }

  static Future<http.Response> delete(String endpoint) {
    return ApiClient.request('DELETE', endpoint);
  }
}




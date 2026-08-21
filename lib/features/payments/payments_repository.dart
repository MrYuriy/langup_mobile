import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../core/models/subscription.dart';

/// Billing endpoints (`/payments`, from `routers/payments.py`). Checkout and the
/// customer portal are hosted Stripe pages — the app opens the returned URL.
class PaymentsRepository {
  PaymentsRepository(this._api);

  final ApiClient _api;
  Dio get _dio => _api.dio;

  Future<Subscription?> subscription() async {
    final resp = await _dio.get('/payments/subscription');
    if ((resp.statusCode ?? 0) != 200) return null;
    return Subscription.fromJson((resp.data as Map).cast<String, dynamic>());
  }

  /// Returns the hosted Stripe Checkout URL for a plan.
  Future<String> checkoutUrl(String planCode) async {
    final resp =
        await _dio.post('/payments/checkout', data: {'plan_code': planCode});
    _ok(resp);
    return (resp.data as Map)['checkout_url'] as String;
  }

  /// Returns the hosted Stripe Customer Portal URL.
  Future<String> portalUrl() async {
    final resp = await _dio.post('/payments/portal');
    _ok(resp);
    return (resp.data as Map)['portal_url'] as String;
  }

  void _ok(Response resp) {
    final code = resp.statusCode ?? 0;
    if (code >= 200 && code < 300) return;
    final body = resp.data;
    final detail =
        body is Map && body['detail'] is String ? body['detail'] as String : null;
    throw PaymentsException(detail ?? 'Request failed ($code)');
  }
}

class PaymentsException implements Exception {
  PaymentsException(this.message);
  final String message;
  @override
  String toString() => message;
}

import 'dart:convert';
import 'package:http/http.dart' as http;

/// 백엔드 API 기본 주소. 개발 시 --dart-define=API_BASE=http://localhost:3000 로 덮어쓰기.
const String kApiBase =
    String.fromEnvironment('API_BASE', defaultValue: 'https://budget.feelw00.com');

class ApiException implements Exception {
  final String message;
  final int? status;
  ApiException(this.message, [this.status]);
  @override
  String toString() => message;
}

class ApiClient {
  String? token;
  ApiClient({this.token});

  Map<String, String> _headers({bool json = false}) => {
        if (token != null) 'Authorization': 'Bearer $token',
        if (json) 'Content-Type': 'application/json',
      };

  Uri _u(String path, [Map<String, dynamic>? q]) => Uri.parse('$kApiBase$path')
      .replace(queryParameters: q?.map((k, v) => MapEntry(k, '$v')));

  dynamic _decode(http.Response r) {
    dynamic body;
    try {
      body = r.body.isNotEmpty ? jsonDecode(r.body) : null;
    } catch (_) {
      body = null;
    }
    if (r.statusCode >= 200 && r.statusCode < 300) return body;
    final msg = (body is Map && body['error'] != null)
        ? body['error'].toString()
        : 'HTTP ${r.statusCode}';
    throw ApiException(msg, r.statusCode);
  }

  Future<Map<String, dynamic>> login(String username, String password) async {
    final r = await http.post(_u('/api/login'),
        headers: _headers(json: true),
        body: jsonEncode({'username': username, 'password': password}));
    final data = _decode(r) as Map<String, dynamic>;
    token = data['token'] as String;
    return data;
  }

  Future<void> logout() async {
    try {
      await http.post(_u('/api/logout'), headers: _headers());
    } catch (_) {}
    token = null;
  }

  Future<dynamic> _get(String path, [Map<String, dynamic>? q]) async =>
      _decode(await http.get(_u(path, q), headers: _headers()));
  Future<dynamic> _post(String path, Map<String, dynamic> body) async =>
      _decode(await http.post(_u(path),
          headers: _headers(json: true), body: jsonEncode(body)));
  Future<dynamic> _delete(String path) async =>
      _decode(await http.delete(_u(path), headers: _headers()));

  Future<Map<String, dynamic>> me() async =>
      await _get('/api/me') as Map<String, dynamic>;
  Future<Map<String, dynamic>> dashboard() async =>
      await _get('/api/dashboard') as Map<String, dynamic>;

  Future<List<dynamic>> transactions({String? from, String? to, int limit = 100}) async =>
      await _get('/api/transactions',
          {if (from != null) 'from': from, if (to != null) 'to': to, 'limit': limit}) as List<dynamic>;
  Future<void> addTx(Map<String, dynamic> b) async => await _post('/api/transactions', b);
  Future<void> delTx(int id) async => await _delete('/api/transactions/$id');

  Future<List<dynamic>> presets() async => await _get('/api/presets') as List<dynamic>;
  Future<void> addPreset(Map<String, dynamic> b) async => await _post('/api/presets', b);
  Future<void> delPreset(int id) async => await _delete('/api/presets/$id');

  Future<Map<String, dynamic>> fixed() async =>
      await _get('/api/fixed') as Map<String, dynamic>;
  Future<void> addFixed(Map<String, dynamic> b) async => await _post('/api/fixed', b);
  Future<void> delFixed(int id) async => await _delete('/api/fixed/$id');
  Future<void> toggleFixed(int id) async => await _post('/api/fixed/$id/toggle', {});

  Future<Map<String, dynamic>> month(String ym) async =>
      await _get('/api/month', {'ym': ym}) as Map<String, dynamic>;
  Future<Map<String, dynamic>> week(String date) async =>
      await _get('/api/week', {'date': date}) as Map<String, dynamic>;
  Future<Map<String, dynamic>> year(int y) async =>
      await _get('/api/year', {'y': y}) as Map<String, dynamic>;

  Future<void> changePassword(String current, String next) async =>
      await _post('/api/account/password', {'current': current, 'next': next});

  Future<List<dynamic>> categories() async => await _get('/api/categories') as List<dynamic>;
  Future<void> addCategory(String name) async => await _post('/api/categories', {'name': name});
  Future<void> delCategory(int id) async => await _delete('/api/categories/$id');

  Future<Map<String, dynamic>> holdings() async => await _get('/api/holdings') as Map<String, dynamic>;
  Future<void> addHolding(Map<String, dynamic> b) async => await _post('/api/holdings', b);
  Future<void> updateHolding(int id, String amount) async => await _post('/api/holdings/$id', {'amount': amount});
  Future<void> delHolding(int id) async => await _delete('/api/holdings/$id');

  Future<void> applyFixed(String ym) async => await _post('/api/fixed/apply', {'ym': ym});
}

/// JSON 숫자 → int (SQLite 정수 금액)
int asInt(dynamic v) => v == null ? 0 : (v as num).toInt();
String asStr(dynamic v) => v?.toString() ?? '';

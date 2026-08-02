import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api.dart';

class AuthState extends ChangeNotifier {
  final ApiClient api = ApiClient();
  String? username;
  bool loading = true;

  bool get isAuthed => api.token != null;

  Future<void> init() async {
    final sp = await SharedPreferences.getInstance();
    final t = sp.getString('token');
    if (t != null) {
      api.token = t;
      username = sp.getString('username');
      try {
        final m = await api.me();
        username = m['username'] as String?;
      } catch (_) {
        api.token = null;
        username = null;
        await sp.remove('token');
        await sp.remove('username');
      }
    }
    loading = false;
    notifyListeners();
  }

  Future<void> login(String u, String p) async {
    final data = await api.login(u, p);
    username = data['username'] as String?;
    final sp = await SharedPreferences.getInstance();
    await sp.setString('token', api.token!);
    await sp.setString('username', username ?? '');
    notifyListeners();
  }

  Future<void> logout() async {
    await api.logout();
    final sp = await SharedPreferences.getInstance();
    await sp.remove('token');
    await sp.remove('username');
    username = null;
    notifyListeners();
  }
}

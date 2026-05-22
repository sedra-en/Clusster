import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cluster_app/models/app_user.dart';

class LocalStore {
  static const String _key = 'users_list';

  Future<List<AppUser>> getUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_key);
    if (data == null) return [];
    final List decoded = json.decode(data);
    return decoded.map((u) => AppUser.fromMap(u)).toList();
  }

  Future<void> saveUser(AppUser user) async {
    final users = await getUsers();
    final index = users.indexWhere((u) => u.id == user.id);
    if (index != -1) users[index] = user; else users.add(user);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, json.encode(users.map((u) => u.toMap()).toList()));
  }

  // للتحقق من الكود وهمياً (أثناء العرض)
  Future<AppUser?> verifyActivationCode(String email, String code) async {
    final users = await getUsers();
    try {
      return users.firstWhere((u) => u.email == email && u.activationCode == code);
    } catch (e) { return null; }
  }
}
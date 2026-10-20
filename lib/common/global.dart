import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../index.dart';

const _themes = <MaterialColor>[
  Colors.blue,
  Colors.cyan,
  Colors.teal,
  Colors.green,
  Colors.red,
];

class Global {
  static bool get isRelease => const bool.fromEnvironment('dart.vm.product');

  static const _secureStorage = FlutterSecureStorage();
  static const _profileKey = 'profile';

  static late SharedPreferences prefs;
  static Profile profile = Profile();
  static NetCache netCache = NetCache();

  static List<MaterialColor> get themes => _themes;

  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
    try {
      prefs = await SharedPreferences.getInstance();
    } catch (e) {
      // SharedPreferences 初始化失败时降级为内存存储，避免 prefs 未初始化导致启动崩溃。
      debugPrint('SharedPreferences 初始化失败，降级为内存存储: $e');
      SharedPreferences.setMockInitialValues({});
      prefs = await SharedPreferences.getInstance();
    }
    // 优先从安全存储恢复 profile，保证跨重启持久化（SharedPreferences 在 release 下可能失效）。
    try {
      final secureJson = await _secureStorage.read(key: _profileKey);
      if (secureJson != null && secureJson.isNotEmpty) {
        profile = Profile.fromJson(
          jsonDecode(secureJson) as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // 忽略，回退到 SharedPreferences。
    }
    if (profile.user == null) {
      final savedProfile = prefs.getString(PREFS_PROFILE);
      if (savedProfile != null) {
        try {
          profile = Profile.fromJson(
            jsonDecode(savedProfile) as Map<String, dynamic>,
          );
        } catch (_) {
          profile = Profile();
        }
      }
    }
    profile.cache ??= CacheConfig()
      ..enable = true
      ..maxAge = 3600
      ..maxCount = 100;
    GiteeApi.init();
  }

  static Future<bool> saveProfile() async {
    final json = jsonEncode(profile.toJson());
    try {
      await _secureStorage.write(key: _profileKey, value: json);
    } catch (_) {
      // 安全存储写入失败时仍回退到 SharedPreferences。
    }
    return prefs.setString(PREFS_PROFILE, json);
  }
}

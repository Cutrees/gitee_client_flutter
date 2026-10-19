import 'dart:convert';

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
    profile.cache ??= CacheConfig()
      ..enable = true
      ..maxAge = 3600
      ..maxCount = 100;
    GiteeApi.init();
  }

  static Future<bool> saveProfile() =>
      prefs.setString(PREFS_PROFILE, jsonEncode(profile.toJson()));
}

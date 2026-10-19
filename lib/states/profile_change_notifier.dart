import '../index.dart';

class ProfileChangeNotifier extends ChangeNotifier {
  Profile get _profile => Global.profile;

  @override
  void notifyListeners() {
    Global.saveProfile();
    super.notifyListeners();
  }
}

class UserModel extends ProfileChangeNotifier {
  User? get user => _profile.user;

  bool get isLogin => user != null;

  set user(User? user) {
    if (user == null && _profile.user == null) return;
    _profile.lastLogin = user?.login ?? _profile.user?.login;
    _profile.user = user;
    notifyListeners();
  }
}

class ThemeModel extends ProfileChangeNotifier {
  Color get seedColor {
    final value = _profile.theme;
    return value == null ? const Color(0xFF009688) : Color(value.toInt());
  }

  Color get theme => seedColor;

  set theme(Color color) {
    if (color.toARGB32() != _profile.theme) {
      _profile.theme = color.toARGB32();
      notifyListeners();
    }
  }
}

class LocaleModel extends ProfileChangeNotifier {
  Locale? getLocale() {
    final locale = _profile.locale;
    if (locale == null) return null;
    final parts = locale.split('_');
    return parts.length > 1 ? Locale(parts[0], parts[1]) : Locale(parts[0]);
  }

  String? get locale => _profile.locale;

  set locale(String? locale) {
    if (locale != _profile.locale) {
      _profile.locale = locale;
      notifyListeners();
    }
  }
}

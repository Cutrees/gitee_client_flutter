import 'dart:io';

import 'package:dio/dio.dart';

import '../index.dart';

/// 刷新 access_token 的结果。
enum _RefreshResult { success, invalidGrant, failed }

class OAuth {
  static final OAuth _shared = OAuth._internal();
  OAuth._internal();
  factory OAuth() => _shared;

  Oauth? _oauth;
  DateTime? _createdAt;

  String? token() => _oauth?.access_token ?? Global.profile.oauth?.access_token;

  Future<OAuth> prepare() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    if (accessToken != null && accessToken.isNotEmpty) {
      _oauth = Oauth()
        ..access_token = accessToken
        ..expires_in = prefs.getInt('expires_in') ?? 0
        ..refresh_token = prefs.getString('refresh_token')
        ..scope = prefs.getString('scope')
        ..created_at = prefs.getInt('created_at') ?? 0;
      Global.profile.oauth = _oauth;
    } else {
      _oauth = Global.profile.oauth;
    }
    if (isAuthorized) {
      _resetCreatedAt(_oauth?.created_at?.toInt() ?? 0);
      if (isExpired) {
        final result = await refreshAccessToken();
        if (result == _RefreshResult.invalidGrant) await resetToken();
      }
    } else if (Global.profile.user != null) {
      await resetToken();
    }
    return this;
  }

  Future<void> storeToken(Map<String, dynamic> data) async {
    final oauth = Oauth.fromJson(data);
    final accessToken = oauth.access_token;
    if (accessToken == null || accessToken.isEmpty) {
      throw const FormatException('Missing access token');
    }
    final prefs = await SharedPreferences.getInstance();
    final time =
        oauth.created_at?.toInt() ??
        DateTime.now().millisecondsSinceEpoch ~/ 1000;
    oauth.created_at = time;
    await prefs.setInt('expires_in', oauth.expires_in?.toInt() ?? 0);
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', oauth.refresh_token ?? _oauth?.refresh_token ?? '');
    await prefs.setString('scope', oauth.scope ?? '');
    await prefs.setInt('created_at', time);
    _oauth = oauth;
    _resetCreatedAt(time);
    Global.profile.oauth = oauth;
    for (final dio in [GiteeApi.dioV3, GiteeApi.dioV5]) {
      dio.options.headers.remove(HttpHeaders.authorizationHeader);
    }
    Global.netCache.cache.clear();
    await Global.saveProfile();
  }

  Future<void> resetToken() async {
    _oauth = null;
    _createdAt = null;
    Global.profile.oauth = null;
    Global.profile.user = null;
    for (final dio in [GiteeApi.dioV3, GiteeApi.dioV5]) {
      dio.options.headers.remove(HttpHeaders.authorizationHeader);
    }
    Global.netCache.cache.clear();
    final prefs = await SharedPreferences.getInstance();
    for (final key in [
      'access_token',
      'refresh_token',
      'scope',
      'expires_in',
      'created_at',
    ]) {
      await prefs.remove(key);
    }
    await Global.saveProfile();
  }

  bool get isAuthorized => token()?.isNotEmpty == true;

  bool get isExpired {
    final createdAt = _createdAt;
    final expiresIn = (_oauth?.expires_in ?? 0).toInt();
    if (createdAt == null || !isAuthorized) return true;
    if (expiresIn <= 0) return false;
    return !createdAt
        .add(Duration(seconds: expiresIn))
        .isAfter(DateTime.now());
  }

  Future<_RefreshResult> refreshAccessToken() async {
    final refreshToken = _oauth?.refresh_token;
    if (refreshToken == null || refreshToken.isEmpty) {
      return _RefreshResult.invalidGrant;
    }
    try {
      await storeToken(await GiteeApi().refreshToken(refreshToken));
      return _RefreshResult.success;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      // 400/401 表示 refresh_token 已失效或被撤销，需要重新授权；
      // 其它（5xx、网络超时等）属于临时问题，保留登录状态，下次启动再重试。
      if (status == 400 || status == 401) {
        return _RefreshResult.invalidGrant;
      }
      return _RefreshResult.failed;
    } catch (_) {
      return _RefreshResult.failed;
    }
  }

  void _resetCreatedAt(int time) {
    _createdAt = DateTime.fromMillisecondsSinceEpoch(time * 1000);
  }

  Future<void> logout() async {
    await resetToken();
    await WebViewCookieManager().clearCookies();
  }
}

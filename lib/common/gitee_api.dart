import 'package:dio/dio.dart';

import '../index.dart';

class GiteeApi {
  static final _ins = GiteeApi._internal();
  factory GiteeApi() => _ins;
  GiteeApi._internal();

  static const int perPage = 20;
  static final Dio dioV3 = Dio(BaseOptions(baseUrl: BASE_URL_V3));
  static final Dio dioV5 = Dio(BaseOptions(baseUrl: BASE_URL));

  static void init() {
    for (final dio in [dioV3, dioV5]) {
      if (!dio.interceptors.contains(Global.netCache)) {
        dio.interceptors.add(Global.netCache);
      }
    }
  }

  String _encodeSegment(String? value) => Uri.encodeComponent(value ?? '');

  Map<String, dynamic> _query(
    Map<String, dynamic>? query, {
    bool authorized = true,
  }) => {
    ...?query,
    if (authorized && OAuth().isAuthorized) ACCESS_TOKEN: OAuth().token(),
  };

  Options _options({bool refresh = false, bool noCache = false}) =>
      Options(extra: {'refresh': refresh, 'list': true, 'noCache': noCache});

  List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) decode) {
    final dynamic items = _extractList(data);
    if (items is! List) throw const FormatException('Expected a list response');
    final result = <T>[];
    for (final item in items) {
      try {
        result.add(decode(Map<String, dynamic>.from(item as Map)));
      } catch (e) {
        // 跳过无法解析的条目，避免单条脏数据阻断整页列表。
        debugPrint('列表解码跳过一条: $e');
      }
    }
    return result;
  }

  /// 兼容 Gitee 列表接口返回「纯数组」或「包裹对象」两种格式。
  dynamic _extractList(dynamic data) {
    if (data is List) return data;
    if (data is Map) {
      return data['list'] ??
          data['data'] ??
          data['items'] ??
          data['records'] ??
          data['result'];
    }
    return null;
  }

  /// OAuth2 授权码模式：用授权回调里的 code 换取 access_token。
  Future<void> loginWithCode(String code) async {
    final response = await dioV5.post<Map<String, dynamic>>(
      'oauth/token',
      data: {
        'grant_type': 'authorization_code',
        'code': code,
        'client_id': CLIENT_ID,
        'client_secret': CLIENT_SECRET,
        'redirect_uri': OAUTH_REDIRECT_URI,
      },
      options: _options(noCache: true),
    );
    await OAuth().storeToken(response.data!);
    Global.netCache.cache.clear();
  }

  Future<Map<String, dynamic>> refreshToken(String refreshToken) async {
    final response = await dioV5.post<Map<String, dynamic>>(
      'oauth/token',
      data: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': CLIENT_ID,
        'client_secret': CLIENT_SECRET,
        'scope': 'user_info projects notes gists',
      },
      options: _options(noCache: true),
    );
    return response.data!;
  }

  Future<User> userInfo() async {
    final response = await dioV5.get<Map<String, dynamic>>(
      'api/v5/user',
      queryParameters: _query(null),
      options: _options(noCache: true),
    );
    return User.fromJson(response.data!);
  }

  /// 用公开接口获取完整用户资料（邮箱/主页等字段，/user 接口可能因 scope 返回不完整）。
  Future<User> userDetail(String login) async {
    final response = await dioV5.get<Map<String, dynamic>>(
      'api/v5/users/${_encodeSegment(login)}',
      queryParameters: _query(null),
      options: _options(noCache: true),
    );
    return User.fromJson(response.data!);
  }

  Future<List<DynamicNews>> receivedEvents({
    Map<String, dynamic>? queryParameters,
    bool refresh = false,
  }) async {
    final login = Global.profile.user?.login;
    if (!OAuth().isAuthorized || login == null || login.isEmpty) return [];
    final response = await dioV5.get(
      'api/v5/users/${_encodeSegment(login)}/received_events',
      queryParameters: _query({'per_page': perPage, ...?queryParameters}),
      options: _options(refresh: refresh),
    );
    return _list(response.data, DynamicNews.fromJson);
  }

  Future<String?> notificationCount(bool unread) async {
    if (!OAuth().isAuthorized) return null;
    final response = await dioV5.get(
      'api/v5/notifications/count',
      queryParameters: _query({'unread': unread}),
      options: _options(noCache: true),
    );
    return response.data['notification_count']?.toString();
  }

  Future<List<NotifyMessages>> messagesAll(
    bool unread, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (!OAuth().isAuthorized) return [];
    final response = await dioV5.get(
      'api/v5/notifications/messages',
      queryParameters: _query({
        'per_page': perPage,
        ...?queryParameters,
        'unread': unread,
      }),
      options: _options(noCache: true),
    );
    return _list(response.data, NotifyMessages.fromJson);
  }

  Future<List<Notifications>> notificationsAll(
    bool unread, {
    Map<String, dynamic>? queryParameters,
  }) async {
    if (!OAuth().isAuthorized) return [];
    final response = await dioV5.get(
      'api/v5/notifications/threads',
      queryParameters: _query({
        'per_page': perPage,
        ...?queryParameters,
        'unread': unread,
        'type': 'all',
      }),
      options: _options(noCache: true),
    );
    return _list(response.data, Notifications.fromJson);
  }

  Future<List<Repo>> getRepoStarList({int page = 1}) async {
    if (!OAuth().isAuthorized) return [];
    final response = await dioV5.get(
      'api/v5/user/starred',
      queryParameters: _query({
        'per_page': perPage,
        'page': page,
      }),
      options: _options(noCache: true),
    );
    return _list(response.data, Repo.fromJson);
  }

  Future<List<Repo>> getRepoList(int page) async {
    if (!OAuth().isAuthorized) return [];
    final response = await dioV5.get(
      'api/v5/user/repos',
      queryParameters: _query({
        'per_page': perPage,
        'page': page,
        'type': 'all',
        'sort': 'updated',
      }),
      options: _options(noCache: true),
    );
    return _list(response.data, Repo.fromJson);
  }

  Future<List<RepoV3>> getRepoListV3({
    required TabTitleHome tab,
    Map<String, dynamic>? queryParameters,
    bool refresh = false,
  }) async {
    final path = switch (tab) {
      TabTitleHome.Recommend => 'featured',
      TabTitleHome.Popular => 'popular',
      TabTitleHome.Recent => 'latest',
    };
    final response = await dioV3.get(
      'projects/$path/',
      queryParameters: {'per_page': perPage, ...?queryParameters},
      options: _options(refresh: refresh),
    );
    return _list(response.data, RepoV3.fromJson);
  }

  Future<List<Repo>> searchRepos({
    required String keyWords,
    Map<String, dynamic>? queryParameters,
    bool refresh = false,
  }) async {
    final response = await dioV5.get(
      'api/v5/search/repositories',
      queryParameters: _query({
        'page': 1,
        'per_page': perPage,
        ...?queryParameters,
        'q': keyWords.trim(),
      }),
      options: _options(refresh: refresh),
    );
    return _list(response.data, Repo.fromJson);
  }

  Future<List<User>> searchUsers({
    required String keyWords,
    Map<String, dynamic>? queryParameters,
    bool refresh = false,
  }) async {
    final response = await dioV5.get(
      'api/v5/search/users',
      queryParameters: _query({
        'page': 1,
        'per_page': perPage,
        ...?queryParameters,
        'q': keyWords.trim(),
      }),
      options: _options(refresh: refresh),
    );
    return _list(response.data, User.fromJson);
  }
}

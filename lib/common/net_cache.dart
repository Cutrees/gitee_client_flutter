import 'dart:collection';

import 'package:dio/dio.dart';

import '../index.dart';

class _CacheObject {
  _CacheObject(this.response)
    : timeStamp = DateTime.now().millisecondsSinceEpoch;
  final Response<dynamic> response;
  final int timeStamp;
}

class NetCache extends Interceptor {
  final cache = LinkedHashMap<String, _CacheObject>();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (Global.profile.cache?.enable != true) {
      handler.next(options);
      return;
    }
    final key = options.extra['cacheKey'] as String? ?? options.uri.toString();
    if (options.extra['refresh'] == true) {
      if (options.extra['list'] == true) {
        cache.removeWhere(
          (_, value) =>
              value.response.requestOptions.baseUrl == options.baseUrl &&
              value.response.requestOptions.path == options.path,
        );
      } else {
        delete(key);
      }
    } else if (options.extra['noCache'] != true &&
        options.method.toUpperCase() == 'GET') {
      final cached = cache[key];
      if (cached != null) {
        final maxAge = Global.profile.cache?.maxAge ?? 0;
        if ((DateTime.now().millisecondsSinceEpoch - cached.timeStamp) / 1000 <
            maxAge) {
          final response = cached.response;
          handler.resolve(
            Response<dynamic>(
              requestOptions: options,
              data: response.data,
              statusCode: response.statusCode,
              statusMessage: response.statusMessage,
              headers: response.headers,
              extra: response.extra,
            ),
          );
          return;
        }
        cache.remove(key);
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    final options = response.requestOptions;
    final maxCount = Global.profile.cache?.maxCount?.toInt() ?? 0;
    if (Global.profile.cache?.enable == true &&
        maxCount > 0 &&
        options.extra['noCache'] != true &&
        options.method.toUpperCase() == 'GET' &&
        response.statusCode == 200) {
      final key =
          options.extra['cacheKey'] as String? ?? options.uri.toString();
      cache.remove(key);
      while (cache.length >= maxCount) {
        cache.remove(cache.keys.first);
      }
      cache[key] = _CacheObject(response);
    }
    handler.next(response);
  }

  void delete(String key) => cache.remove(key);
}

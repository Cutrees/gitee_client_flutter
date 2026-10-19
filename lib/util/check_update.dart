import 'dart:ffi';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:open_filex/open_filex.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart';

import '../index.dart';

/// 用 Gitee 发行版 Atom 订阅获取最新 tag（普通网页接口，不受匿名 API 限流影响）。
Future<String> getLatestTag() async {
  final response = await Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ),
  ).get(
    appTagsAtomUrl,
    options: Options(responseType: ResponseType.plain),
  );

  final dom.Document doc = html_parser.parse(response.data.toString());
  final dom.Element? firstEntry = doc.querySelector('entry');
  final String? tag = firstEntry?.querySelector('title')?.text.trim();
  if (tag == null || tag.isEmpty) {
    throw '检查更新失败：无法解析最新版本信息';
  }
  return tag;
}

/// 检查更新：对比当前版本与最新 tag，有新版本则弹窗提示下载。
Future<void> checkUpdate(BuildContext context, {bool silent = false}) async {
  try {
    final PackageInfo packageInfo = await PackageInfo.fromPlatform();
    final String currentVersion = packageInfo.version;
    final String latestTag = await getLatestTag();
    if (!context.mounted) return;
    if (latestTag == 'v$currentVersion' || latestTag == currentVersion) {
      if (!silent) showToast('已是最新版');
    } else {
      _showUpdateDialog(context, latestTag);
    }
  } catch (_) {
    if (!silent) showToast('无法获取更新信息，请稍后重试');
  }
}

/// 应用启动后自动检查更新（延迟 4 秒，6 小时节流，避免频繁请求触发限流）。
Future<void> autoCheckUpdate() async {
  await Future.delayed(const Duration(seconds: 4));
  final prefs = await SharedPreferences.getInstance();
  final now = DateTime.now().millisecondsSinceEpoch;
  final last = prefs.getInt('last_check_update_time');
  if (last != null && now - last < const Duration(hours: 6).inMilliseconds) {
    return;
  }
  await prefs.setInt('last_check_update_time', now);
  final context = navigatorKey.currentContext;
  if (context == null) return;
  await checkUpdate(context, silent: true);
}

void _showUpdateDialog(BuildContext context, String latestTag) {
  final String abi = Abi.current().architectureName;
  final String downloadUrl =
      '$appReleaseUrl/releases/download/$latestTag/app-$abi-release.apk';
  showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('发现新版本'),
      content: Text('最新版本：$latestTag'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(dialogContext);
            downloadAndInstallApk(context, downloadUrl);
          },
          child: const Text('下载更新'),
        ),
      ],
    ),
  );
}

/// 下载 APK 并调起系统安装。应用内用 Dio 下载字节流，避免浏览器给 APK 追加 .zip 后缀。
Future<void> downloadAndInstallApk(BuildContext context, String url) async {
  final Directory tempDir = await getTemporaryDirectory();
  final String apkPath =
      '${tempDir.path}/update_${DateTime.now().millisecondsSinceEpoch}.apk';

  final Dio dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(minutes: 10),
    ),
  );

  final ValueNotifier<double> progress = ValueNotifier<double>(-1);
  bool dialogShown = false;
  if (context.mounted) {
    dialogShown = true;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ValueListenableBuilder<double>(
        valueListenable: progress,
        builder: (context, value, _) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('正在下载更新...'),
              const SizedBox(height: 16),
              LinearProgressIndicator(value: value < 0 ? null : value),
              const SizedBox(height: 12),
              Text(value < 0 ? '准备中...' : '${(value * 100).toStringAsFixed(0)}%'),
            ],
          ),
        ),
      ),
    );
  }

  try {
    await dio.download(
      url,
      apkPath,
      onReceiveProgress: (received, total) {
        progress.value = total > 0 ? received / total : 0;
      },
    );
    progress.value = 1.0;
    if (dialogShown && context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }

    final OpenResult result = await OpenFilex.open(
      apkPath,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      throw '打开安装包失败：${result.message}';
    }
  } catch (_) {
    if (dialogShown && context.mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
    showToast('下载更新失败，请稍后重试');
  }
}

extension _AbiName on Abi {
  String get architectureName {
    return switch (this) {
      Abi.androidArm64 => 'arm64-v8a',
      Abi.androidArm => 'armeabi-v7a',
      Abi.androidX64 => 'x86_64',
      Abi.androidIA32 => 'x86',
      _ => 'arm64-v8a',
    };
  }
}

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewRoute extends StatefulWidget {
  const WebViewRoute({super.key, this.url});
  final String? url;

  @override
  State<WebViewRoute> createState() => _WebViewRouteState();
}

class _WebViewRouteState extends State<WebViewRoute> {
  WebViewController? _controller;
  String _title = '';
  String? _error;
  int _progress = 0;
  bool _giteePage = false;

  static bool _isGitee(Uri uri) =>
      uri.scheme == 'https' && uri.host == 'gitee.com';

  @override
  void initState() {
    super.initState();
    final uri = Uri.tryParse(widget.url ?? '');
    if (uri == null ||
        !['https', 'http'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      _error = '链接无效';
      return;
    }
    _giteePage = _isGitee(uri);
    final controller = WebViewController();
    _controller = controller;
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (url) {
            if (mounted) {
              setState(() {
                _error = null;
                _progress = 0;
                _giteePage = _isGitee(Uri.parse(url));
              });
            }
          },
          onPageFinished: (_) async {
            final title = await controller.getTitle();
            if (mounted) setState(() => _title = title ?? '');
          },
          onWebResourceError: (error) {
            if (mounted && error.isForMainFrame == true) {
              setState(() => _error = '页面加载失败，请重试');
            }
          },
          onNavigationRequest: (request) {
            final target = Uri.tryParse(request.url);
            return target != null && ['https', 'http'].contains(target.scheme)
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
        ),
      )
      ..loadRequest(uri);
  }

  Future<void> _login() async {
    final proceed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('网页登录'),
        content: const Text(
          '应用授权和 Gitee 网页登录相互独立。请在 Gitee 官方网页完成一次登录，'
          '后续应用内网页会保留该会话。登录后点击“返回原页面”。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('前往登录'),
          ),
        ],
      ),
    );
    if (proceed == true && mounted) {
      await _controller?.loadRequest(Uri.https('gitee.com', '/login'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final error = _error;
    return Scaffold(
      appBar: AppBar(
        title: Text(_title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (controller != null) ...[
            if (_giteePage)
              IconButton(
                tooltip: '网页登录',
                onPressed: _login,
                icon: const Icon(Icons.login),
              ),
            IconButton(
              tooltip: '返回原页面',
              onPressed: () => controller.loadRequest(Uri.parse(widget.url!)),
              icon: const Icon(Icons.home_outlined),
            ),
            IconButton(
              tooltip: '刷新',
              onPressed: controller.reload,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ],
      ),
      body: error != null
          ? Center(child: Text(error))
          : controller == null
          ? const SizedBox.shrink()
          : Column(
              children: [
                if (_progress < 100)
                  LinearProgressIndicator(value: _progress / 100),
                Expanded(child: WebViewWidget(controller: controller)),
              ],
            ),
    );
  }
}

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
    final controller = WebViewController();
    _controller = controller;
    controller
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onPageStarted: (_) {
            if (mounted) setState(() => _error = null);
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

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final error = _error;
    return Scaffold(
      appBar: AppBar(
        title: Text(_title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          if (controller != null)
            IconButton(
              onPressed: controller.reload,
              icon: const Icon(Icons.refresh),
            ),
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

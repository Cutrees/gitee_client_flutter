import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gitee_client_flutter/index.dart';
import 'package:webview_flutter/platform_interface.dart';
import 'package:webview_flutter/webview_flutter.dart';

class WebViewRoute extends StatefulWidget {
  WebViewRoute({Key key, this.url}) : super(key: ValueKey(url));
  final String url;

  @override
  _WebViewRouteState createState() => _WebViewRouteState();
}

class _WebViewRouteState extends State<WebViewRoute> {
  final Completer<WebViewController> _controller = Completer<WebViewController>();
  String _title;

  @override
  Widget build(BuildContext context) {
    print("Url --------> ${widget.url ?? ""}");
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _title ?? "",
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 13),
        ),
      ),
      body: Builder(builder: (BuildContext context) {
        //todo 2020年9月23日 注销重登后会有黑屏现象
        return WebView(
          initialUrl: widget?.url ?? "",
          javascriptMode: JavascriptMode.unrestricted,
          onWebViewCreated: (WebViewController webViewController) {
            if (!_controller.isCompleted) {
              _controller.complete(webViewController);
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (!_controller.isCompleted) {
              _controller.completeError(error);
            }
            print('Page onWebResourceError: ${error?.description}');
          },
          onPageStarted: (String url) {
            print('Page started loading: $url');
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
            //更新标题
            _controller.future.then((c) => c.getTitle()).then((value) {
              if (!mounted) return;
              setState(() {
                _title = value;
              });
            });
          },
          gestureNavigationEnabled: true,
          // TODO(iskakaushik): Remove this when collection literals makes it to stable.
          // ignore: prefer_collection_literals
          javascriptChannels: <JavascriptChannel>[
            //_toasterJavascriptChannel(context),
          ].toSet(),
          navigationDelegate: (NavigationRequest request) {
            //站内子页面(如仓库的 issues/tree 等)需要正常跳转，不能在WebView内被拦截
            print('allowing navigation to ${request.url}');
            return NavigationDecision.navigate;
          },
        );
      }),
      //floatingActionButton: favoriteButton(),
    );
  }

  JavascriptChannel _toasterJavascriptChannel(BuildContext context) {
    return JavascriptChannel(
        name: 'Toaster',
        onMessageReceived: (JavascriptMessage message) {
          Scaffold.of(context).showSnackBar(
            SnackBar(content: Text(message.message)),
          );
        });
  }

  Widget favoriteButton() {
    return FutureBuilder<WebViewController>(
        future: _controller.future,
        builder: (BuildContext context, AsyncSnapshot<WebViewController> controller) {
          if (controller.hasData) {
            return FloatingActionButton(
              onPressed: () async {
                final String url = await controller.data.currentUrl();
                Scaffold.of(context).showSnackBar(
                  SnackBar(content: Text('Favorited $url')),
                );
              },
              child: const Icon(Icons.favorite),
            );
          }
          return Container();
        });
  }
}

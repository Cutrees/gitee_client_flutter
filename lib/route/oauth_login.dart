import '../index.dart';

/// Gitee 网页授权登录页：内嵌 WebView 打开 Gitee 授权页，
/// 用户在官方页面登录并授权后，网页会话（Cookie）与 API token 同时生效，
/// 从而可以访问私有仓库的网页内容。
class OAuthLoginRoute extends StatefulWidget {
  const OAuthLoginRoute({super.key});

  @override
  State<OAuthLoginRoute> createState() => _OAuthLoginRouteState();
}

class _OAuthLoginRouteState extends State<OAuthLoginRoute> {
  late final WebViewController _controller;
  bool _exchanging = false;

  String get _authorizeUrl => '$OAUTH_AUTHORIZE_URL'
      '?client_id=$CLIENT_ID'
      '&redirect_uri=${Uri.encodeComponent(OAUTH_REDIRECT_URI)}'
      '&response_type=code'
      '&scope=${Uri.encodeComponent(OAUTH_SCOPE)}';

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(onNavigationRequest: _onNavigationRequest),
      )
      ..loadRequest(Uri.parse(_authorizeUrl));
  }

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    if (request.url.startsWith(OAUTH_REDIRECT_URI)) {
      final uri = Uri.parse(request.url);
      final code = uri.queryParameters['code'];
      if (code != null && code.isNotEmpty) _handleCode(code);
      return NavigationDecision.prevent;
    }
    return NavigationDecision.navigate;
  }

  Future<void> _handleCode(String code) async {
    if (_exchanging) return;
    _exchanging = true;
    try {
      await GiteeApi().loginWithCode(code);
      final user = await GiteeApi().userInfo();
      User detail;
      try {
        detail = await GiteeApi().userDetail(user.login ?? '');
      } catch (_) {
        detail = user;
      }
      if (!mounted) return;
      context.read<UserModel>().user = detail;
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (_) {
      if (mounted) showToast('登录失败，请重试');
    } finally {
      _exchanging = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Gitee 网页登录')),
      body: WebViewWidget(controller: _controller),
    );
  }
}

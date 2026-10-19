import '../index.dart';
import '../util/check_update.dart';

class LaunchWidget extends StatefulWidget {
  const LaunchWidget({super.key});
  @override
  State<LaunchWidget> createState() => _LaunchState();
}

class _LaunchState extends State<LaunchWidget> {
  bool _ready = false;
  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    final hadUser = Global.profile.user != null;
    try {
      await OAuth().prepare();
    } catch (e) {
      // OAuth 初始化失败不阻塞启动，直接进入主页。
      debugPrint('OAuth 初始化失败: $e');
    }
    if (!mounted) return;
    setState(() => _ready = true);
    // 登录态因 token 过期被清除时，明确提示用户，而不是静默显示「未登录」。
    if (hadUser && Global.profile.user == null) {
      showToast('登录已过期，请重新登录');
    }
    // 用户资料刷新放到后台异步执行，避免网络请求阻塞启动画面。
    if (OAuth().isAuthorized) _refreshUser();
    autoCheckUpdate();
  }

  Future<void> _refreshUser() async {
    try {
      final user = await GiteeApi().userInfo();
      try {
        final detail = await GiteeApi().userDetail(user.login ?? '');
        Global.profile.user = detail;
      } catch (_) {
        Global.profile.user = user;
      }
      await Global.saveProfile();
    } catch (_) {
      // 刷新用户资料失败时保留本地缓存。
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(
          child: Text(
            '码云 Gitee',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
          ),
        ),
      );
    }
    return const MainRoute();
  }
}

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';

import '../index.dart' hide Connectivity, ConnectivityResult;

class LoginRoute extends StatefulWidget {
  const LoginRoute({super.key});
  @override
  State<LoginRoute> createState() => _LoginRouteState();
}

class _LoginRouteState extends State<LoginRoute> {
  final _nameController = TextEditingController();
  final _pwdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _pwdShow = false;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = Global.profile.lastLogin ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pwdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(gm.login)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            children: [
              TextFormField(
                enabled: !_loading,
                autofocus: _nameController.text.isEmpty,
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: gm.userName,
                  prefixIcon: const Icon(Icons.person),
                ),
                validator: (value) => (value?.trim().isNotEmpty ?? false)
                    ? null
                    : gm.userNameRequired,
              ),
              TextFormField(
                enabled: !_loading,
                autofocus: _nameController.text.isNotEmpty,
                controller: _pwdController,
                obscureText: !_pwdShow,
                decoration: InputDecoration(
                  labelText: gm.password,
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _pwdShow ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () => setState(() => _pwdShow = !_pwdShow),
                  ),
                ),
                validator: (value) =>
                    (value?.isNotEmpty ?? false) ? null : gm.passwordRequired,
                onFieldSubmitted: (_) => _onLogin(),
              ),
              const SizedBox(height: 25),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _loading ? null : _onLogin,
                  child: _loading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(),
                        )
                      : Text(gm.login),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _loading
                      ? null
                      : () => Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const OAuthLoginRoute(),
                            ),
                          ),
                  icon: const Icon(Icons.open_in_browser),
                  label: const Text('使用网页登录（可访问私有仓库）'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onLogin() async {
    if (_loading || !(_formKey.currentState?.validate() ?? false)) return;
    final account = _nameController.text.trim();
    final password = _pwdController.text;
    final model = context.read<UserModel>();
    setState(() => _loading = true);
    try {
      final connections = await Connectivity().checkConnectivity();
      if (!mounted) return;
      if (connections.contains(ConnectivityResult.none)) {
        showToast(networkNone);
        return;
      }
      await GiteeApi().login(account, password);
      final user = await GiteeApi().userInfo();
      try {
        final detail = await GiteeApi().userDetail(user.login ?? account);
        model.user = detail;
      } catch (_) {
        model.user = user;
      }
      if (mounted) Navigator.of(context).pop();
    } on DioException {
      if (OAuth().isAuthorized) await OAuth().resetToken();
      if (mounted) showToast('登录失败，请检查账号、密码或网络后重试');
    } catch (_) {
      if (OAuth().isAuthorized) await OAuth().resetToken();
      if (mounted) showToast('登录失败，请稍后重试');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

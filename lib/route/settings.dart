import '../index.dart';

class SettingsRoute extends StatelessWidget {
  const SettingsRoute({super.key});

  @override
  Widget build(BuildContext context) {
    final model = context.watch<UserModel>();
    final user = model.user;
    final gm = GmLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user?.name ?? user?.login ?? gm.login),
            accountEmail: Text(user?.email ?? ''),
            currentAccountPicture: getAvatarCircle(user?.avatar_url),
            onDetailsPressed: user == null
                ? () => navToPage(context, page_login)
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.color_lens),
            title: Text(gm.theme),
            onTap: () => navToPage(context, page_theme),
          ),
          ListTile(
            leading: const Icon(Icons.language),
            title: Text(gm.language),
            onTap: () => navToPage(context, page_language),
          ),
          if (model.isLogin)
            ListTile(
              leading: const Icon(Icons.power_settings_new),
              title: Text(gm.logout),
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (dialogContext) => AlertDialog(
                    content: Text(gm.logoutTip),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, false),
                        child: Text(gm.cancel),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        child: Text(gm.yes),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  model.user = null;
                  await OAuth().logout();
                }
              },
            ),
        ],
      ),
    );
  }
}

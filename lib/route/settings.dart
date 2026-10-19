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
          const _SectionTitle('账号'),
          _AccountCard(user: user),
          const _SectionTitle('通用'),
          ListTile(
            leading: const Icon(Icons.color_lens_outlined),
            title: Text(gm.theme),
            subtitle: const Text('更换应用主题颜色'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => navToPage(context, page_theme),
          ),
          const _SectionTitle('关于'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('关于应用'),
            onTap: () => _showAbout(context),
          ),
        ],
      ),
    );
  }

  void _showAbout(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('码云 Gitee'),
        content: const Text('一个简洁的 Gitee 安卓客户端。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('确定'),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({required this.user});
  final User? user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.outlineVariant),
      ),
      color: scheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            getAvatarCircle(user?.avatar_url, radius: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.name ?? user?.login ?? '未登录',
                    style: textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user == null ? '登录后可同步关注动态' : (user?.login ?? ''),
                    style: textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            if (user == null)
              FilledButton(
                onPressed: () => navToPage(context, page_login),
                child: const Text('登录'),
              )
            else
              TextButton(
                onPressed: () => _logout(context),
                child: const Text('退出登录'),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    final gm = GmLocalizations.of(context);
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
      context.read<UserModel>().user = null;
      await OAuth().logout();
    }
  }
}

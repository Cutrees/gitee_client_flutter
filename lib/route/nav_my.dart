import '../index.dart';

class MyRoute extends StatefulWidget {
  const MyRoute({super.key});
  @override
  State<MyRoute> createState() => _MyRouteState();
}

class _MyRouteState extends State<MyRoute>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = context.watch<UserModel>().user;
    if (user == null) {
      return Scaffold(
        body: loginPrompt(context),
      );
    }
    final avatar = user.avatar_url ?? user.portrait_url;
    return Scaffold(
      appBar: AppBar(title: Text(GmLocalizations.of(context).navMe)),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => navToPage2(
                      context: context,
                      page: PhotoViewPage(avatar),
                    ),
                    child: getAvatarCircle(avatar, radius: 36),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name ?? user.login ?? '未知用户',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            _FollowStat(
                              label: '关注',
                              count: user.following,
                              onTap: () => navToPage2(
                                context: context,
                                page: UserFollowRoute(
                                  login: user.login ?? '',
                                  initialIndex: 1,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            _FollowStat(
                              label: '粉丝',
                              count: user.followers,
                              onTap: () => navToPage2(
                                context: context,
                                page: UserFollowRoute(
                                  login: user.login ?? '',
                                  initialIndex: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPersistentHeader(
            pinned: true,
            delegate: MySliverPersistentHeaderDelegate(
              minHeight: 48,
              maxHeight: 48,
              child: Material(
                color: Theme.of(context).colorScheme.surface,
                child: TabBar(
                  controller: _tabController,
                  tabs: const [
                    Tab(text: '仓库'),
                    Tab(text: '动态'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            RepoListWidget(0, key: ValueKey('${user.id}-repos')),
            DynamicRoute(),
          ],
        ),
      ),
    );
  }
}

class _FollowStat extends StatelessWidget {
  const _FollowStat({
    required this.label,
    required this.count,
    required this.onTap,
  });

  final String label;
  final num? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(
          '$label ${count ?? 0}',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

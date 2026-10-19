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
        body: Center(
          child: ElevatedButton(
            onPressed: () => navToPage(context, page_login),
            child: Text(GmLocalizations.of(context).login),
          ),
        ),
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
                    child: Text(
                      user.name ?? user.login ?? '未知用户',
                      style: Theme.of(context).textTheme.titleLarge,
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

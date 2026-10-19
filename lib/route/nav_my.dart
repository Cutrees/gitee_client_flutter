import '../index.dart';

class MyRoute extends StatefulWidget {
  const MyRoute({super.key});
  @override
  State<MyRoute> createState() => _PersonDetailState();
}

class _PersonDetailState extends State<MyRoute>
    with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final TabController _tabController;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    final created = DateTime.tryParse(user.created_at ?? '');
    final createdText = created == null
        ? '未知'
        : '${created.year}-${created.month.toString().padLeft(2, '0')}-${created.day.toString().padLeft(2, '0')}';
    final avatar = user.avatar_url ?? user.portrait_url;
    return Scaffold(
      appBar: AppBar(title: Text(GmLocalizations.of(context).navMe)),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => navToPage2(
                          context: context,
                          page: PhotoViewPage(avatar),
                        ),
                        child: getAvatarCircle(avatar, radius: 80),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name ?? user.login ?? '未知用户',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            Text(
                              user.email ?? '暂无邮箱',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              user.blog ?? '暂无个人主页',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text('创建于：$createdText'),
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
                    Tab(text: '动态'),
                    Tab(text: '仓库'),
                    Tab(text: '星标'),
                  ],
                ),
              ),
            ),
          ),
        ],
        body: TabBarView(
          controller: _tabController,
          children: [
            DynamicRoute(),
            RepoListWidget(0, key: ValueKey('${user.id}-repos')),
            RepoListWidget(1, key: ValueKey('${user.id}-stars')),
          ],
        ),
      ),
    );
  }
}

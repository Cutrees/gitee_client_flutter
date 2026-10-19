import '../index.dart';
import '../util/exploration_paging.dart';

class HomeRoute extends StatefulWidget {
  const HomeRoute({super.key});
  @override
  State<HomeRoute> createState() => _HomeRouteState();
}

class _HomeRouteState extends State<HomeRoute>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Future<String?>? _notificationCount;
  num? _userId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: TabTitleHome.values.length,
      vsync: this,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.watch<UserModel>().user;
    if (_userId != user?.id) {
      _userId = user?.id;
      _notificationCount = user == null
          ? null
          : GiteeApi().notificationCount(true);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel>();
    final gm = GmLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(gm.home),
        bottom: TabBar(
          controller: _tabController,
          tabs: TabTitleHome.values.map((tab) => Tab(text: tab.title)).toList(),
        ),
        actions: [
          IconButton(
            icon: const Hero(tag: hero_tag_search, child: Icon(Icons.search)),
            onPressed: () =>
                navToPage2(context: context, page: SearchPageRoute()),
          ),
          BadgeWidget<String?>(
            future: _notificationCount,
            centerIconData: Icons.notifications_none,
            smallTextMarginRight: 12,
            smallTextMarginTop: 12,
            onPressed: () async {
              if (!user.isLogin) {
                await navToPage(context, page_login);
                return;
              }
              await navToPage2(context: context, page: NotificationsRoute());
              if (mounted && context.read<UserModel>().isLogin) {
                setState(
                  () => _notificationCount = GiteeApi().notificationCount(true),
                );
              }
            },
          ),
        ],
      ),
      body: user.isLogin
          ? TabBarView(
              controller: _tabController,
              children: TabTitleHome.values
                  .map((tab) => _HomeListWidget(tab))
                  .toList(),
            )
          : loginPrompt(context),
    );
  }
}

class _HomeListWidget extends StatefulWidget {
  _HomeListWidget(this.tab) : super(key: ValueKey(tab));
  final TabTitleHome tab;
  @override
  State<_HomeListWidget> createState() => _HomeListWidgetState();
}

class _HomeListWidgetState extends State<_HomeListWidget>
    with AutomaticKeepAliveClientMixin {
  late final _paging = ExplorationPaging(
    (page, refresh) => GiteeApi().getRepoListV3(
      tab: widget.tab,
      refresh: refresh,
      queryParameters: {'page': page},
    ),
  );

  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return InfiniteListView<RepoV3>(
      onRetrieveData: _paging.load,
      emptyBuilder: listNoDataView,
      itemBuilder: (list, index, context) => RepoListItemWidgetV3(list[index]),
    );
  }
}

import '../index.dart';

/// 粉丝 / 关注列表页：顶部 TabBar 可切换，点用户名打开其主页。
class UserFollowRoute extends StatefulWidget {
  const UserFollowRoute({
    super.key,
    required this.login,
    this.initialIndex = 0,
  });

  final String login;
  final int initialIndex;

  @override
  State<UserFollowRoute> createState() => _UserFollowRouteState();
}

class _UserFollowRouteState extends State<UserFollowRoute>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialIndex.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.login),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: '关注'), Tab(text: '粉丝')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _UserFollowList(login: widget.login, following: true),
          _UserFollowList(login: widget.login, following: false),
        ],
      ),
    );
  }
}

class _UserFollowList extends StatelessWidget {
  const _UserFollowList({required this.login, required this.following});

  final String login;
  final bool following;

  @override
  Widget build(BuildContext context) {
    return InfiniteListView<User>(
      pageSize: 20,
      onRetrieveData: (page, items, refresh) async {
        final data = following
            ? await GiteeApi().userFollowing(login, page: page)
            : await GiteeApi().userFollowers(login, page: page);
        items.addAll(data);
        return data.length == 20;
      },
      emptyBuilder: listNoDataView,
      itemBuilder: (list, index, context) => _userTile(context, list[index]),
      separatorBuilder: (list, index, context) => const Divider(height: 1),
    );
  }

  Widget _userTile(BuildContext context, User user) {
    final login = user.login ?? '';
    final name = user.name;
    final url = user.html_url ??
        (login.isEmpty ? null : '${BASE_URL}${Uri.encodeComponent(login)}');
    return ListTile(
      leading: getAvatarCircle(
        user.avatar_url ?? user.portrait_url,
        radius: 40,
      ),
      title: Text(name == null || name.isEmpty ? login : name),
      subtitle: Text(login.isEmpty ? '' : '@$login'),
      onTap: url != null && checkUrl(url)
          ? () => navToWeb(context: context, url: url)
          : null,
    );
  }
}

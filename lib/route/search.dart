import '../index.dart';

class SearchPageRoute extends StatefulWidget {
  @override
  State<SearchPageRoute> createState() => _SearchPageRouteState();
}

class _SearchPageRouteState extends State<SearchPageRoute>
    with SingleTickerProviderStateMixin {
  final _editController = TextEditingController();
  late final TabController _tabController;
  late final List<String> _history;
  String _searchWords = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _history = List.of(
      Global.prefs.getStringList(PREFS_SEARCH_HISTORY) ?? <String>[],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _editController.dispose();
    super.dispose();
  }

  Future<void> _beginSearch() async {
    final words = _editController.text.trim();
    if (words.isEmpty) {
      showToast('搜索内容不能为空');
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _editController.text = words;
      _searchWords = words;
      _history.remove(words);
      _history.insert(0, words);
    });
    await Global.prefs.setStringList(PREFS_SEARCH_HISTORY, _history);
  }

  Future<void> _clearHistory() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: const Text('确定要清空所有搜索历史记录吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('确定'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(_history.clear);
    await Global.prefs.setStringList(PREFS_SEARCH_HISTORY, _history);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: TextField(
          controller: _editController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => _beginSearch(),
          decoration: InputDecoration(
            hintText: '搜索仓库或用户',
            border: InputBorder.none,
            suffixIcon: IconButton(
              onPressed: _editController.clear,
              icon: const Icon(Icons.clear),
            ),
          ),
        ),
        actions: [TextButton(onPressed: _beginSearch, child: const Text('搜索'))],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '仓库'),
            Tab(text: '用户'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Expanded(child: Text('搜索历史')),
                IconButton(
                  tooltip: '清空搜索历史',
                  onPressed: _clearHistory,
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 44,
            child: _history.isEmpty
                ? const Center(child: Text('暂时没有搜索记录'))
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _history.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) => ActionChip(
                      label: Text(_history[index]),
                      onPressed: () {
                        _editController.text = _history[index];
                        _beginSearch();
                      },
                    ),
                  ),
          ),
          Expanded(
            child: _searchWords.isEmpty
                ? Center(
                    child: Icon(
                      Icons.search,
                      size: 90,
                      color: Theme.of(context).primaryColor,
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _SearchResultList<Repo>(
                        key: ValueKey('repos:$_searchWords'),
                        retrieve: (page, refresh) => GiteeApi().searchRepos(
                          keyWords: _searchWords,
                          refresh: refresh,
                          queryParameters: {
                            'page': page,
                            'per_page': GiteeApi.perPage,
                          },
                        ),
                        itemBuilder: (context, repo) => ListTile(
                          leading: getAvatarCircle(
                            repo.owner?.avatar_url ?? repo.owner?.portrait_url,
                            radius: 40,
                          ),
                          title: Text(repo.full_name ?? repo.name ?? ''),
                          subtitle: Text(repo.description ?? ''),
                          trailing: Text(repo.language ?? ''),
                          onTap: () {
                            final url = repo.html_url;
                            if (url != null && checkUrl(url))
                              navToWeb(context: context, url: url);
                          },
                        ),
                      ),
                      _SearchResultList<User>(
                        key: ValueKey('users:$_searchWords'),
                        retrieve: (page, refresh) => GiteeApi().searchUsers(
                          keyWords: _searchWords,
                          refresh: refresh,
                          queryParameters: {
                            'page': page,
                            'per_page': GiteeApi.perPage,
                          },
                        ),
                        itemBuilder: (context, user) {
                          final login = user.login ?? '';
                          final name = user.name;
                          final url =
                              user.html_url ??
                              (login.isEmpty
                                  ? null
                                  : '${BASE_URL}${Uri.encodeComponent(login)}');
                          return ListTile(
                            leading: getAvatarCircle(
                              user.avatar_url ?? user.portrait_url,
                              radius: 40,
                            ),
                            title: Text(
                              name == null || name.isEmpty ? login : name,
                            ),
                            subtitle: Text(login.isEmpty ? '' : '@$login'),
                            onTap: url != null && checkUrl(url)
                                ? () => navToWeb(context: context, url: url)
                                : null,
                          );
                        },
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _SearchResultList<T> extends StatefulWidget {
  const _SearchResultList({
    super.key,
    required this.retrieve,
    required this.itemBuilder,
  });
  final Future<List<T>> Function(int page, bool refresh) retrieve;
  final Widget Function(BuildContext context, T item) itemBuilder;

  @override
  State<_SearchResultList<T>> createState() => _SearchResultListState<T>();
}

class _SearchResultListState<T> extends State<_SearchResultList<T>>
    with AutomaticKeepAliveClientMixin {
  final List<T> _items = [];
  int _nextPage = 1;
  int _generation = 0;
  bool _loading = false;
  bool _hasMore = true;
  bool _failed = false;
  bool _retryRefresh = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (!refresh && (_loading || !_hasMore)) return;
    final generation = refresh ? ++_generation : _generation;
    final page = refresh ? 1 : _nextPage;
    setState(() {
      _loading = true;
      _failed = false;
    });
    try {
      final data = await widget.retrieve(page, refresh);
      if (!mounted || generation != _generation) return;
      setState(() {
        if (refresh) _items.clear();
        _items.addAll(data);
        _nextPage = page + 1;
        _hasMore = data.length >= GiteeApi.perPage;
      });
    } catch (_) {
      if (!mounted || generation != _generation) return;
      setState(() {
        _failed = true;
        _retryRefresh = refresh;
      });
    } finally {
      if (mounted && generation == _generation)
        setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshIndicator(
      onRefresh: () => _load(refresh: true),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.metrics.extentAfter < 200 &&
              !_failed &&
              _items.isNotEmpty)
            _load();
          return false;
        },
        child: ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _items.length + 1,
          itemBuilder: (context, index) {
            if (index < _items.length)
              return widget.itemBuilder(context, _items[index]);
            if (_loading)
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            if (_failed)
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    const Text('搜索失败，请检查网络后重试'),
                    TextButton(
                      onPressed: () =>
                          _load(refresh: _retryRefresh || _items.isEmpty),
                      child: const Text('重试'),
                    ),
                  ],
                ),
              );
            if (_items.isEmpty)
              return Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const Text('没有搜索结果'),
                    TextButton(
                      onPressed: () => _load(refresh: true),
                      child: const Text('刷新'),
                    ),
                  ],
                ),
              );
            if (_hasMore)
              return TextButton(onPressed: _load, child: const Text('加载更多'));
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('没有更多结果')),
            );
          },
        ),
      ),
    );
  }
}

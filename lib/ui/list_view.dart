import 'package:flutter/material.dart';

class InfiniteListView<T> extends StatefulWidget {
  const InfiniteListView({
    super.key,
    required this.onRetrieveData,
    required this.itemBuilder,
    required this.emptyBuilder,
    this.separatorBuilder,
    this.pageSize = 20,
  }) : assert(pageSize > 0);

  final Future<bool> Function(int page, List<T> items, bool refresh)
  onRetrieveData;
  final Widget Function(List<T> items, int index, BuildContext context)
  itemBuilder;
  final Widget Function(VoidCallback refresh, BuildContext context)
  emptyBuilder;
  final Widget Function(List<T> items, int index, BuildContext context)?
  separatorBuilder;
  final int pageSize;

  @override
  State<InfiniteListView<T>> createState() => _InfiniteListViewState<T>();
}

class _InfiniteListViewState<T> extends State<InfiniteListView<T>> {
  final _controller = ScrollController();
  List<T> _items = [];
  int _page = 1;
  int _request = 0;
  bool _loading = false;
  bool _hasMore = true;
  bool _failed = false;
  bool _retryRefresh = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_loadIfNeeded);
    _load();
  }

  Future<void> _load({bool refresh = false}) async {
    if (!mounted || (!refresh && (_loading || !_hasMore))) return;
    final request = ++_request;
    final page = refresh ? 1 : _page;
    // Each request owns its list, so stale callbacks cannot mutate visible data.
    final items = refresh ? <T>[] : List<T>.of(_items);
    setState(() {
      _loading = true;
      _failed = false;
      _retryRefresh = refresh;
    });
    try {
      final hasMore = await widget.onRetrieveData(page, items, refresh);
      if (!mounted || request != _request) return;
      setState(() {
        _items = List<T>.of(items);
        _page = page + 1;
        _hasMore = hasMore;
        _loading = false;
      });
      _scheduleLoad();
    } catch (_) {
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  Future<void> _refresh() => _load(refresh: true);

  void _retry() {
    _load(refresh: _retryRefresh);
  }

  void _loadIfNeeded() {
    if (mounted &&
        _controller.hasClients &&
        _controller.position.extentAfter < 200 &&
        !_failed) {
      _load();
    }
  }

  void _scheduleLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadIfNeeded());
  }

  @override
  void dispose() {
    ++_request;
    _controller.dispose();
    super.dispose();
  }

  Widget _status() {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_failed) {
      return Center(
        child: TextButton(onPressed: _retry, child: const Text('加载失败，点击重试')),
      );
    }
    return Center(
      child: TextButton(onPressed: () => _load(), child: const Text('加载更多')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final separated = widget.separatorBuilder != null;
    final itemCount = _items.isEmpty
        ? 0
        : separated
        ? _items.length * 2 - 1
        : _items.length;
    return RefreshIndicator(
      onRefresh: _refresh,
      child: NotificationListener<ScrollMetricsNotification>(
        onNotification: (_) {
          _scheduleLoad();
          return false;
        },
        child: CustomScrollView(
          controller: _controller,
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            if (_items.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _loading || _failed
                    ? _status()
                    : widget.emptyBuilder(() => _refresh(), context),
              )
            else ...[
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  if (separated && index.isOdd) {
                    return widget.separatorBuilder!(
                      _items,
                      index ~/ 2,
                      context,
                    );
                  }
                  return widget.itemBuilder(
                    _items,
                    separated ? index ~/ 2 : index,
                    context,
                  );
                }, childCount: itemCount),
              ),
              if (_loading || _failed || _hasMore)
                SliverToBoxAdapter(child: _status()),
            ],
          ],
        ),
      ),
    );
  }
}

Widget listNoDataView(VoidCallback refresh, BuildContext context) {
  return Material(
    color: Theme.of(context).colorScheme.surface,
    child: InkWell(
      splashColor: Theme.of(context).secondaryHeaderColor,
      onTap: refresh,
      child: Center(
        child: Padding(
          padding: EdgeInsets.only(top: 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.event_busy,
                color: Theme.of(context).primaryColor,
                size: 150,
              ),
              Padding(
                padding: EdgeInsets.only(top: 0),
                child: Text(
                  "没有数据",
                  style: TextStyle(
                    color: Theme.of(context).primaryColor,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

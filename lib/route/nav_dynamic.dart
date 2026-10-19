import '../index.dart';

class DynamicRoute extends StatelessWidget {
  const DynamicRoute({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel>();
    return Scaffold(
      appBar: AppBar(title: Text(GmLocalizations.of(context).navDynamic)),
      body: !user.isLogin
          ? Center(
              child: ElevatedButton(
                onPressed: () => navToPage(context, page_login),
                child: Text(GmLocalizations.of(context).login),
              ),
            )
          : InfiniteListView<DynamicNews>(
              onRetrieveData: (page, items, refresh) async {
                final data = await GiteeApi().receivedEvents(
                  queryParameters: {'page': page, 'per_page': 20},
                );
                items.addAll(data);
                return data.length == 20;
              },
              emptyBuilder: listNoDataView,
              itemBuilder: (list, index, context) =>
                  _DynamicNewsItemWidget(list[index]),
            ),
    );
  }
}

class _DynamicNewsItemWidget extends StatelessWidget {
  _DynamicNewsItemWidget(this.news) : super(key: ValueKey(news.id));
  final DynamicNews news;

  String get _subtitle {
    final payload = news.payload;
    switch (DynamicType.INSTANCE.getPrefix(news.type)) {
      case DynamicType.MemberEvent:
        return news.repo?.human_name ?? news.repo?.full_name ?? '';
      case DynamicType.IssueEvent:
      case DynamicType.PullRequestEvent:
        final number = payload?.number;
        return [
          if (number != null) '#$number',
          payload?.title ?? '',
        ].join(' ').trim();
      case DynamicType.PullRequestCommentEvent:
        return payload?.pull_request?.title ?? payload?.comment?.body ?? '';
      case DynamicType.PushEvent:
        final commits = payload?.commits;
        return commits != null && commits.isNotEmpty
            ? commits.first.message ?? ''
            : '';
      default:
        return payload?.comment?.body ?? payload?.body ?? '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = news.payload?.html_url ?? news.repo?.html_url;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          ListTile(
            leading: getAvatarRect(news.actor?.avatar_url, width: 35),
            title: Text(news.actor?.name ?? news.actor?.login ?? '未知用户'),
            subtitle: Text(_subtitle.isEmpty ? '暂无内容' : _subtitle),
            trailing: Text(
              (news.type ?? '').replaceAll('Event', ''),
              style: const TextStyle(fontSize: 10),
            ),
            onTap: url == null || url.isEmpty
                ? null
                : () => navToWeb(context: context, url: url),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

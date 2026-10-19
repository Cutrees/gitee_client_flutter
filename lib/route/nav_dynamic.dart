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
                  refresh: refresh,
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

  String get _action {
    switch (news.type) {
      case 'PushEvent':
        return '推送了代码';
      case 'StarEvent':
        return 'Star 了';
      case 'WatchEvent':
        return '关注了';
      case 'ForkEvent':
        return 'Fork 了';
      case 'CreateEvent':
        return '创建了';
      case 'IssueEvent':
        return '提出了 Issue';
      case 'PullRequestEvent':
        return '发起了 PR';
      case 'IssueCommentEvent':
      case 'CommitCommentEvent':
        return '评论了';
      case 'MemberEvent':
        return '加入了';
      case 'FollowEvent':
        return '关注了';
      default:
        return (news.type ?? '').replaceAll('Event', '');
    }
  }

  String get _detail {
    final payload = news.payload;
    final repoName = news.repo?.human_name ?? news.repo?.full_name ?? '';
    switch (news.type) {
      case 'PushEvent':
        final commits = payload?.commits;
        final msg = commits != null && commits.isNotEmpty
            ? commits.first.message ?? ''
            : '';
        return [repoName, msg].where((e) => e.isNotEmpty).join(' · ');
      case 'IssueEvent':
      case 'PullRequestEvent':
        final number = payload?.number ??
            payload?.issue?.number ??
            payload?.pull_request?.number?.toString();
        final title = payload?.title ??
            payload?.issue?.title ??
            payload?.pull_request?.title ??
            '';
        return [repoName, if (number != null) '#$number', title]
            .where((e) => e.isNotEmpty)
            .join(' · ');
      default:
        final body = payload?.comment?.body ?? payload?.body ?? '';
        return [repoName, body].where((e) => e.isNotEmpty).join(' · ');
    }
  }

  @override
  Widget build(BuildContext context) {
    final payload = news.payload;
    final url = payload?.html_url ??
        payload?.issue?.html_url ??
        payload?.pull_request?.html_url ??
        payload?.comment?.html_url ??
        news.repo?.html_url ??
        news.actor?.html_url;
    final actor = news.actor?.name ?? news.actor?.login ?? '未知用户';
    final detail = _detail;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        children: [
          ListTile(
            leading: getAvatarRect(news.actor?.avatar_url, width: 35),
            title: Text('$actor $_action'),
            subtitle: detail.isEmpty
                ? null
                : Text(detail, maxLines: 2, overflow: TextOverflow.ellipsis),
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

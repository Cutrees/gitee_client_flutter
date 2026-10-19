import '../index.dart';

class RepoListItemWidgetV3 extends StatelessWidget {
  RepoListItemWidgetV3(this.repo) : super(key: ValueKey(repo.id));
  final RepoV3 repo;

  @override
  Widget build(BuildContext context) {
    final path = repo.path_with_namespace;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            leading: getAvatarRect(
              repo.owner?.avatar_url ?? repo.owner?.portrait_url,
              width: 35,
            ),
            title: Text(repo.name_with_namespace ?? repo.name ?? '未命名仓库'),
            subtitle: Text(
              repo.description ?? GmLocalizations.of(context).noDescription,
            ),
            onTap: path == null || path.isEmpty
                ? null
                : () => navToWeb(
                    context: context,
                    url: Uri.parse(BASE_URL).resolve(path).toString(),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(72, 0, 16, 12),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                IconText(
                  '${repo.watches_count ?? 0}',
                  icon: const Icon(MyIcons.watch, size: 15),
                ),
                IconText(
                  '${repo.stars_count ?? 0}',
                  icon: const Icon(MyIcons.star, size: 15),
                ),
                IconText(
                  '${repo.forks_count ?? 0}',
                  icon: const Icon(MyIcons.branch, size: 15),
                ),
                if (repo.language?.isNotEmpty ?? false)
                  IconText(
                    repo.language,
                    icon: const Icon(MyIcons.tag, size: 15),
                  ),
              ],
            ),
          ),
          const Divider(height: 1),
        ],
      ),
    );
  }
}

class RepoListWidget extends StatefulWidget {
  RepoListWidget(this.tab, {Key? key}) : super(key: key ?? ValueKey(tab));
  final int tab;

  @override
  State<RepoListWidget> createState() => _RepoListWidgetState();
}

class _RepoListWidgetState extends State<RepoListWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return MediaQuery.removePadding(
      removeTop: true,
      context: context,
      child: InfiniteListView<Repo>(
        pageSize: 20,
        onRetrieveData: (page, items, refresh) async {
          final data = widget.tab == 0
              ? await GiteeApi().getRepoList(page)
              : await GiteeApi().getRepoStarList(page: page);
          items.addAll(data);
          return data.length == 20;
        },
        emptyBuilder: listNoDataView,
        itemBuilder: (list, index, context) => RepoListItemWidget(list[index]),
        separatorBuilder: (list, index, context) => const SizedBox(height: 5),
      ),
    );
  }
}

class RepoListItemWidget extends StatelessWidget {
  RepoListItemWidget(this.repo) : super(key: ValueKey(repo.id));
  final Repo repo;

  @override
  Widget build(BuildContext context) {
    final url = repo.html_url;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: ListTile(
        leading: getAvatarRect(
          repo.owner?.avatar_url ?? repo.owner?.portrait_url,
          width: 35,
        ),
        title: Text(repo.full_name ?? repo.name ?? '未命名仓库'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(repo.description ?? GmLocalizations.of(context).noDescription),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                IconText(
                  '${repo.watchers_count ?? 0}',
                  icon: const Icon(MyIcons.watch, size: 15),
                ),
                IconText(
                  '${repo.stargazers_count ?? 0}',
                  icon: const Icon(MyIcons.star, size: 15),
                ),
                IconText(
                  '${repo.forks_count ?? 0}',
                  icon: const Icon(MyIcons.branch, size: 15),
                ),
              ],
            ),
          ],
        ),
        trailing: Text(repo.language ?? ''),
        onTap: url == null || url.isEmpty
            ? null
            : () => navToWeb(context: context, url: url),
      ),
    );
  }
}

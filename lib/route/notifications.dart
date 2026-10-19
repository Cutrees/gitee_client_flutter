import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html;

import '../index.dart';

class NotificationsRoute extends StatefulWidget {
  const NotificationsRoute({super.key});
  @override
  State<NotificationsRoute> createState() => _NotificationsRouteState();
}

class _NotificationsRouteState extends State<NotificationsRoute>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('消息'),
      bottom: TabBar(
        controller: _tabController,
        tabs: const [
          Tab(text: '私信'),
          Tab(text: '通知'),
        ],
      ),
    ),
    body: TabBarView(
      controller: _tabController,
      children: const [
        NotificationListWidget(type: 0),
        NotificationListWidget(type: 1),
      ],
    ),
  );
}

class NotificationListWidget extends StatefulWidget {
  const NotificationListWidget({super.key, this.type = 0});
  final int type;
  @override
  State<NotificationListWidget> createState() => _NotificationListWidgetState();
}

class _NotificationListWidgetState extends State<NotificationListWidget>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return InfiniteListView<Object>(
      onRetrieveData: (page, items, refresh) async {
        final List<Object> data = widget.type == 0
            ? await GiteeApi().messagesAll(
                false,
                queryParameters: {'page': page, 'per_page': 20},
              )
            : await GiteeApi().notificationsAll(
                false,
                queryParameters: {'page': page, 'per_page': 20},
              );
        items.addAll(data);
        return data.length == 20;
      },
      emptyBuilder: listNoDataView,
      itemBuilder: (list, index, context) {
        final item = list[index];
        if (item is NotifyMessages) return _MessageItemWidget(item);
        if (item is Notifications) return _NotificationItemWidget(item);
        return const SizedBox.shrink();
      },
      separatorBuilder: (list, index, context) => const Divider(height: 1),
    );
  }
}

class _MessageItemWidget extends StatelessWidget {
  _MessageItemWidget(this.message) : super(key: ValueKey(message.id));
  final NotifyMessages message;

  Future<void> _openLink(BuildContext context, String? url) async {
    final uri = Uri.tryParse(url ?? '');
    if (uri == null ||
        !['https', 'http'].contains(uri.scheme) ||
        uri.host.isEmpty)
      return;
    final external = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        content: const Text('选择打开链接方式'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(GmLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('浏览器打开'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('应用内打开'),
          ),
        ],
      ),
    );
    if (!context.mounted || external == null) return;
    if (external) {
      try {
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
            context.mounted) {
          showToast('无法打开链接');
        }
      } catch (_) {
        if (context.mounted) showToast('无法打开链接');
      }
    } else {
      await navToWeb(context: context, url: uri.toString());
    }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.sender?.name ?? message.sender?.login ?? '未知用户',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        if (message.content?.isNotEmpty ?? false)
          _MessageContentWidget(
            content: message.content!,
            onLinkTap: (url) => _openLink(context, url),
          )
        else
          const Text('暂无内容'),
        if (message.html_url?.isNotEmpty ?? false)
          TextButton(
            onPressed: () => _openLink(context, message.html_url),
            child: const Text('查看私信'),
          ),
      ],
    ),
  );
}

class _MessageContentWidget extends StatelessWidget {
  const _MessageContentWidget({required this.content, required this.onLinkTap});

  final String content;
  final ValueChanged<String> onLinkTap;

  @override
  Widget build(BuildContext context) {
    final linkColor = Theme.of(context).colorScheme.primary;

    InlineSpan render(dom.Node node, {bool insideLink = false}) {
      if (node is dom.Text) return TextSpan(text: node.data);
      if (node is! dom.Element) return const TextSpan();
      final tag = node.localName;
      if (['script', 'style', 'iframe', 'object'].contains(tag)) {
        return const TextSpan();
      }
      if (tag == 'br') return const TextSpan(text: '\n');
      if (tag == 'img') return TextSpan(text: node.attributes['alt'] ?? '');
      final href = node.attributes['href'];
      final isLink = tag == 'a' && href != null && !insideLink;
      final children = node.nodes
          .map((child) => render(child, insideLink: insideLink || isLink))
          .toList();
      final span = TextSpan(
        style: switch (tag) {
          'b' || 'strong' => const TextStyle(fontWeight: FontWeight.bold),
          'i' || 'em' => const TextStyle(fontStyle: FontStyle.italic),
          'u' => const TextStyle(decoration: TextDecoration.underline),
          's' ||
          'del' => const TextStyle(decoration: TextDecoration.lineThrough),
          'code' || 'pre' => const TextStyle(fontFamily: 'monospace'),
          _ => null,
        },
        children: [
          if (tag == 'li') const TextSpan(text: '• '),
          ...children,
          if ([
            'p',
            'div',
            'li',
            'pre',
            'blockquote',
            'h1',
            'h2',
            'h3',
          ].contains(tag))
            const TextSpan(text: '\n'),
        ],
      );
      if (!isLink) return span;
      return WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: InkWell(
          onTap: () => onLinkTap(href),
          child: Text.rich(
            span,
            style: TextStyle(
              color: linkColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      );
    }

    return Text.rich(
      TextSpan(
        children: html.parseFragment(content).nodes.map(render).toList(),
      ),
    );
  }
}

class _NotificationItemWidget extends StatelessWidget {
  _NotificationItemWidget(this.notification)
    : super(key: ValueKey(notification.id));
  final Notifications notification;
  @override
  Widget build(BuildContext context) {
    final url = notification.html_url;
    final date = DateTime.tryParse(notification.updated_at ?? '');
    final dateText = date == null
        ? ''
        : date.toLocal().toString().split('.').first;
    final content = (html.parseFragment(notification.content ?? '').text ?? '')
        .trim();
    return ListTile(
      title: Text(
        notification.subject?.title?.isNotEmpty == true
            ? notification.subject!.title!
            : content.isEmpty
            ? '暂无内容'
            : content,
        maxLines: 3,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        [
          if (notification.subject?.title?.isNotEmpty == true) content,
          dateText,
          notification.repository?.full_name ?? '',
        ].where((value) => value.isNotEmpty).join(' · '),
      ),
      trailing: notification.unread == true
          ? Icon(
              Icons.circle,
              size: 10,
              color: Theme.of(context).colorScheme.primary,
            )
          : null,
      onTap: url == null || url.isEmpty
          ? null
          : () => navToWeb(context: context, url: url),
    );
  }
}

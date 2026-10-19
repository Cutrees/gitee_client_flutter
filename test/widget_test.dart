import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gitee_client_flutter/models/issue.dart';
import 'package:gitee_client_flutter/models/notifications.dart';
import 'package:gitee_client_flutter/models/notifyMessages.dart';
import 'package:gitee_client_flutter/models/repo.dart';
import 'package:gitee_client_flutter/models/repoV3.dart';
import 'package:gitee_client_flutter/models/user.dart';
import 'package:gitee_client_flutter/ui/list_view.dart';
import 'package:gitee_client_flutter/util/exploration_paging.dart';

void main() {
  group('探索换批', () {
    test('刷新取下一批，后续分页连续，末尾回到第一页', () async {
      final calls = <(int, bool)>[];
      final paging = ExplorationPaging((page, refresh) async {
        calls.add((page, refresh));
        return page <= 4 ? [RepoV3()..id = page] : [];
      });
      final initial = <RepoV3>[];
      await paging.load(1, initial, false);
      await paging.load(2, initial, false);
      final refreshed = <RepoV3>[];
      await paging.load(1, refreshed, true);
      expect(refreshed.single.id, 3);
      await paging.load(2, refreshed, false);
      expect(refreshed.map((repo) => repo.id), [3, 4]);
      final wrapped = <RepoV3>[];
      await paging.load(1, wrapped, true);
      expect(wrapped.single.id, 1);
      expect(calls, [
        (1, false),
        (2, false),
        (3, true),
        (4, false),
        (5, true),
        (1, true),
      ]);
    });

    test('刷新失败不推进批次', () async {
      var fail = true;
      final paging = ExplorationPaging((page, refresh) async {
        if (refresh && fail) throw StateError('网络异常');
        return [RepoV3()..id = page];
      });
      await paging.load(1, [], false);
      await expectLater(paging.load(1, [], true), throwsStateError);
      fail = false;
      final items = <RepoV3>[];
      await paging.load(1, items, true);
      expect(items.single.id, 2);
    });
  });

  group('Gitee JSON models', () {
    test('用户搜索数组保留头像和数字计数，允许缺少个人信息', () {
      final response =
          jsonDecode('''[
        {"id":435,"login":"git","name":"git",
         "avatar_url":"https://example.com/avatar.png",
         "public_repos":12,"public_gists":0,"followers":10,
         "following":2,"stared":0,"watched":7,"weibo":null}
      ]''')
              as List<dynamic>;
      final user = User.fromJson(response.single as Map<String, dynamic>);

      expect(user.login, 'git');
      expect(user.avatar_url, 'https://example.com/avatar.png');
      expect(user.portrait_url, isNull);
      expect(user.weibo, isNull);
      expect(user.public_repos, 12);
      expect(user.public_gists, 0);
      expect(user.followers, 10);
      expect(user.following, 2);
      expect(user.stared, 0);
      expect(user.watched, 7);
      final restored = User.fromJson(jsonDecode(jsonEncode(user.toJson())));
      expect(restored.avatar_url, user.avatar_url);
      expect(restored.portrait_url, isNull);
      expect(restored.watched, 7);
    });

    test('Repo 数字计数和用户列表不会按对象解析', () {
      final repo = Repo.fromJson({
        'id': 42,
        'forks_count': 0,
        'stargazers_count': 123456,
        'watchers_count': 7,
        'open_issues_count': 3,
        'assignees_number': 1,
        'testers_number': 1,
        'owner': {'id': 1, 'login': 'owner'},
        'assignees': [
          {'id': 2, 'login': 'assignee'},
        ],
        'testers': [
          {'id': 3, 'login': 'tester'},
        ],
      });

      expect(repo.forks_count, 0);
      expect(repo.stargazers_count, 123456);
      expect(repo.watchers_count, 7);
      expect(repo.open_issues_count, 3);
      expect(repo.assignees_number, 1);
      expect(repo.testers_number, 1);
      expect(repo.owner?.login, 'owner');
      expect(repo.assignees?.single.login, 'assignee');
      expect(repo.testers?.single.login, 'tester');
      final restored = Repo.fromJson(jsonDecode(jsonEncode(repo.toJson())));
      expect(restored.stargazers_count, 123456);
      expect(restored.assignees?.single.id, 2);
    });

    test('Issue 负责人、里程碑及父仓库对象支持 JSON 往返', () {
      final milestone = <String, dynamic>{
        'id': 30692,
        'title': 'B-SIG-FrontEnd',
        'state': 'closed',
        'due_on': '2030-12-31',
      };
      final parent = <String, dynamic>{
        'id': 10,
        'full_name': 'upstream/project',
        'owner': {'id': 1, 'login': 'upstream'},
      };
      final issue = Issue.fromJson({
        'number': 'IDLK8I',
        'assignee': {'id': 6574868, 'login': 'hwcaifubi'},
        'milestone': milestone,
        'repository': {'id': 11, 'parent': parent},
      });

      expect(issue.assignee, isA<User>());
      expect(issue.assignee?.login, 'hwcaifubi');
      expect(issue.milestone, milestone);
      expect(issue.repository?.parent, parent);
      final restored = Issue.fromJson(jsonDecode(jsonEncode(issue.toJson())));
      expect(restored.assignee?.id, 6574868);
      expect(restored.milestone, milestone);
      expect(restored.repository?.parent, parent);
    });

    test('未分配 Issue 和非 fork 仓库允许 null 或省略对象', () {
      for (final json in <Map<String, dynamic>>[
        {},
        {'assignee': null, 'milestone': null},
      ]) {
        final issue = Issue.fromJson(json);
        expect(issue.assignee, isNull);
        expect(issue.milestone, isNull);
      }
      expect(Repo.fromJson({}).parent, isNull);
      expect(Repo.fromJson({'parent': null}).parent, isNull);
    });

    test('首页 V3 保留 fork? wire key、计数和匿名状态 null', () {
      final repo = RepoV3.fromJson({
        'id': 50900283,
        'name': 'workbuddy-credit',
        'fork?': false,
        'forks_count': 1,
        'stars_count': 2,
        'watches_count': 3,
        'stared': null,
        'watched': null,
      });

      expect(repo.fork, isFalse);
      expect(repo.forks_count, 1);
      expect(repo.stars_count, 2);
      expect(repo.watches_count, 3);
      expect(repo.stared, isNull);
      expect(repo.watched, isNull);
      expect(repo.toJson()['fork?'], isFalse);
      expect(RepoV3.fromJson({'fork?': true}).fork, isTrue);
    });

    test('通知解析参与者、仓库、主题和命名空间', () {
      final notification = Notifications.fromJson({
        'id': 5,
        'content': '新的评论',
        'type': 'Issue',
        'unread': true,
        'mute': false,
        'actor': {'id': 1, 'login': 'reviewer'},
        'repository': {'id': 2, 'stargazers_count': 8},
        'subject': {'title': '修复问题', 'type': 'Issue'},
        'namespaces': [
          {'id': 3, 'path': 'team'},
        ],
      });

      expect(notification.unread, isTrue);
      expect(notification.mute, isFalse);
      expect(notification.actor?.login, 'reviewer');
      expect(notification.repository?.stargazers_count, 8);
      expect(notification.subject?.title, '修复问题');
      expect(notification.namespaces?.single.path, 'team');
      final restored = Notifications.fromJson(
        jsonDecode(jsonEncode(notification.toJson())),
      );
      expect(restored.actor?.id, 1);
      expect(restored.subject?.type, 'Issue');
      expect(restored.namespaces?.single.id, 3);
      final sparse = Notifications.fromJson({'id': 6, 'actor': null});
      expect(sparse.actor, isNull);
      expect(sparse.repository, isNull);
      expect(sparse.subject, isNull);
      expect(sparse.namespaces, isNull);
    });

    test('私信保留发送者、未读状态及内容并兼容缺少发送者', () {
      final message = NotifyMessages.fromJson({
        'id': 7,
        'sender': {'id': 4, 'login': 'sender'},
        'unread': false,
        'content': '你好',
        'updated_at': '2026-10-19T08:00:00+08:00',
      });

      expect(message.sender?.login, 'sender');
      expect(message.unread, isFalse);
      expect(message.content, '你好');
      final restored = NotifyMessages.fromJson(
        jsonDecode(jsonEncode(message.toJson())),
      );
      expect(restored.sender?.id, 4);
      expect(restored.content, '你好');
      expect(restored.updated_at, message.updated_at);
      expect(NotifyMessages.fromJson({'sender': null}).sender, isNull);
      expect(NotifyMessages.fromJson({}).unread, isNull);
    });
  });

  testWidgets('刷新成功后忽略旧分页结果，不污染数据或分页状态', (tester) async {
    final paging = Completer<bool>();
    final refreshing = Completer<bool>();
    final calls = <(int, bool)>[];
    List<String>? pagingItems;
    List<String>? refreshItems;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: InfiniteListView<String>(
            onRetrieveData: (page, items, refresh) async {
              calls.add((page, refresh));
              if (refresh) {
                refreshItems = items;
                return refreshing.future;
              }
              if (page == 1) {
                items.add('initial');
                return true;
              }
              pagingItems = items;
              return paging.future;
            },
            itemBuilder: (items, index, context) => Text(items[index]),
            emptyBuilder: (refresh, context) => const Text('empty'),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump();
    expect(calls, [(1, false), (2, false)]);
    expect(pagingItems, ['initial']);

    final refresh = tester
        .widget<RefreshIndicator>(find.byType(RefreshIndicator))
        .onRefresh();
    expect(calls.last, (1, true));
    expect(refreshItems, isEmpty);
    refreshItems!.add('fresh');
    refreshing.complete(false);
    await refresh;
    await tester.pump();
    expect(find.text('fresh'), findsOneWidget);

    pagingItems!.add('stale');
    paging.complete(true);
    await tester.pumpAndSettle();
    expect(find.text('fresh'), findsOneWidget);
    expect(find.text('initial'), findsNothing);
    expect(find.text('stale'), findsNothing);
    expect(find.text('加载更多'), findsNothing);
    expect(calls, [(1, false), (2, false), (1, true)]);
    expect(tester.takeException(), isNull);
  });
}

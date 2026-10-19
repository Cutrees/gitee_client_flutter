import '../index.dart';

const ACCESS_TOKEN = 'access_token';
const BASE_URL = 'https://gitee.com/';
const BASE_URL_V3 = '${BASE_URL}api/v3/';
const CLIENT_ID = String.fromEnvironment(
  'GITEE_CLIENT_ID',
  defaultValue:
      '47c4bab7e3de5fee929d8d50f65721513476e7467aa7c30661810f53615fae28',
);
const CLIENT_SECRET = String.fromEnvironment(
  'GITEE_CLIENT_SECRET',
  defaultValue:
      '0cff85e8decb0b93cd856952c85f41a1e8636040b7f4ffdea8788dbbe632421b',
);

const fontIconFontCN = 'iconFontCN';
const fontMaterialIcons = 'MaterialIcons';
const String networkMobile = '当前处于移动网络';
const String networkWifi = '当前处于WIFI网络';
const String networkNone = '请检查网络连接';
const colorNotifyTitle = Color(0xFF00415E);

const sem_watch = '\u{f06e}';
const sem_empty_watch = '\uf070';
const sem_star = '\uf005';
const sem_empty_star = '\uf006';
const sem_fork = '\uf126';
const sem_tag = '\uf02b';
const sem_lock = '\uf023';
const sem_user = '\uf007';
const sem_wait = '\uf017';
const sem_loading = '\uf110';
const sem_folder = '\uf07b';
const sem_file_text = '\uf0f6';
const sem_download_disk = '\uf019';

const PREFS_PROFILE = 'profile';
const PREFS_SEARCH_HISTORY = 'search_history';
const page_main = 'page_main';
const page_login = 'page_login';
const page_theme = 'page_theme';
const page_language = 'page_language';
final routers = <String, WidgetBuilder>{
  page_main: (context) => MainRoute(),
  page_login: (context) => LoginRoute(),
  page_theme: (context) => ThemeChangeRoute(),
  page_language: (context) => LanguageRoute(),
};
const hero_tag_search = 'tag_search';
const image_avatar_default = 'static/image/avatar_default.png';

enum TabTitleHome { Recommend, Popular, Recent }

extension TabTitleHomeExtension on TabTitleHome {
  String get title => const ['推荐项目', '热门项目', '最近更新'][index];
}

enum DynamicType {
  INSTANCE,
  UNKNOWN,
  MemberEvent,
  IssueEvent,
  IssueCommentEvent,
  PullRequestEvent,
  PullRequestCommentEvent,
  PushEvent,
  ProjectCommentEvent,
}

extension DynamicTypeExtension on DynamicType {
  DynamicType getPrefix(String? type) {
    for (final value in DynamicType.values) {
      if (value.name == type) return value;
    }
    return DynamicType.UNKNOWN;
  }
}

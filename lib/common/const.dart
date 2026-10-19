import '../index.dart';

const ACCESS_TOKEN = 'access_token';
const BASE_URL = 'https://gitee.com/';
const BASE_URL_V3 = '${BASE_URL}api/v3/';
const CLIENT_ID = String.fromEnvironment(
  'GITEE_CLIENT_ID',
  defaultValue:
      '4bc4cdf54620e5b492d688aefedf9aed39f1df292c3072a01b9faae3dedc95c4',
);
const CLIENT_SECRET = String.fromEnvironment(
  'GITEE_CLIENT_SECRET',
  defaultValue:
      'c901cf26cbff2871838aec2389317dcc5923ae722a2ab447727aa7c987f9e270',
);

const OAUTH_AUTHORIZE_URL = 'https://gitee.com/oauth/authorize';
const OAUTH_TOKEN_URL = 'https://gitee.com/oauth/token';
const OAUTH_REDIRECT_URI = 'astra://callback';
const OAUTH_SCOPE = 'user_info projects notes gists';

const authorName = '铜树';
const appReleaseUrl = 'https://gitee.com/cutree/gitee_client_flutter';
const appTagsAtomUrl = 'https://gitee.com/cutree/gitee_client_flutter/tags.atom';

const fontIconFontCN = 'iconFontCN';
const String networkMobile = '当前处于移动网络';
const String networkWifi = '当前处于WIFI网络';
const String networkNone = '请检查网络连接';

const PREFS_PROFILE = 'profile';
const PREFS_SEARCH_HISTORY = 'search_history';
const page_main = 'page_main';
const page_login = 'page_login';
const page_theme = 'page_theme';
final routers = <String, WidgetBuilder>{
  page_main: (context) => MainRoute(),
  page_login: (context) => LoginRoute(),
  page_theme: (context) => ThemeChangeRoute(),
};
const hero_tag_search = 'tag_search';
const image_avatar_default = 'static/image/avatar_default.png';

enum TabTitleHome { Recommend, Popular, Recent }

extension TabTitleHomeExtension on TabTitleHome {
  String get title => const ['推荐项目', '热门项目', '最近更新'][index];
}

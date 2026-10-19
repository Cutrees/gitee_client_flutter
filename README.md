# gitee_client_flutter

🚀**码云客户端**[Gitee Flutter Client](https://github.com/javakam/gitee_client_flutter)<br>
🚀**Flutter中文网** <https://book.flutterchina.club/><br>
🚀**Flutter中文网 随书源码** <https://github.com/wendux/flutter_in_action_source_code><br>
🚀**gsy_github_app_flutter** <https://github.com/CarGuo/gsy_github_app_flutter><br>
🚀**FlutterGithub** <https://github.com/MrHGJ/FlutterGithub><br>

## 安装包(Apk)
**码云客户端**[Gitee Flutter Client Apk](https://github.com/javakam/gitee_client_flutter/blob/master/apk/gitee_client_flutter.apk?raw=true)

## 安卓端使用说明

- 应用 OAuth 授权与 Gitee 网页 Cookie 会话独立。内置网页右上角提供“网页登录”入口，在官方网页完成一次登录后，由 Android WebView 保留会话；“返回原页面”可回到打开的仓库。当前未实现 OAuth 到网页会话的自动换取。
- 退出应用账号时同时清除内置网页 Cookie，避免留下上一个账号的网页登录状态。
- 探索页下拉刷新从上次已加载批次之后获取新一批，并继续顺序分页；接口返回空批次后回到开头。服务端数据量有限时仍可能再次看到已有仓库。
- 开发期间不主动构建 APK，仅在明确要求打包时构建；日常使用静态分析与针对性测试验证改动。

### 安卓验证记录（2026-10-19）

- AMM AN00 / Android 16：调试版构建、覆盖安装与启动成功；全项目静态分析通过，16 项自动测试通过。
- 修正通知 HTML 正文提取时的空安全编译错误。
- Flutter 调试连接受本机沙箱限制；ADB 确认应用进程存活，但 UI 自动化未能获取空闲界面。本轮未确认探索实际换批和网页登录会话效果，仍需交互回归。

## 项目结构
```
├─common    常量,常用方法,网络及缓存,全局配置,oauth认证
├─event     EventBus组件
├─l10n      国际化
├─models    Json文件对应的实体类
├─route     所有路由页面
├─states    保存APP中需要跨组件共享的状态类
├─ui        自定义组件 
└─util      工具类
index.dart
main.dart
```
### 效果图

| 首页 | 动态 | 我的 |
|:---:|:---:|:---:|
| <img src="https://raw.githubusercontent.com/javakam/gitee_client_flutter/master/screenshot/device1.png" width="288" height="610"/> | <img src="https://raw.githubusercontent.com/javakam/gitee_client_flutter/master/screenshot/device2.png" width="288" height="610"/> | <img src="https://raw.githubusercontent.com/javakam/gitee_client_flutter/master/screenshot/device3.png" width="288" height="610"/> |

| 搜索 | 消息 |
|:---:|:---:|
| <img src="https://raw.githubusercontent.com/javakam/gitee_client_flutter/master/screenshot/device4.png" width="288" height="610"/> | <img src="https://raw.githubusercontent.com/javakam/gitee_client_flutter/master/screenshot/device5.png" width="288" height="610"/>

## 国际化
dart -> arb

```
flutter pub pub run intl_translation:extract_to_arb --output-dir=target/directory
      my_program.dart mor;e_of_my_program.dart
my: 
flutter pub pub run intl_translation:extract_to_arb --output-dir=l10n-arb \ lib/l10n/localization_intl.dart
```
arb -> dart

```
flutter pub pub run intl_translation:generate_from_arb --output-dir=lib/l10n --no-use-deferred-loading lib/l10n/localization_intl.dart l10n-arb/intl_*.arb
```

根目录下创建一个intl.sh的脚本，内容为：
```
flutter pub pub run intl_translation:extract_to_arb --output-dir=l10n-arb lib/l10n/localization_intl.dart
flutter pub pub run intl_translation:generate_from_arb --output-dir=lib/l10n --no-use-deferred-loading lib/l10n/localization_intl.dart l10n-arb/intl_*.arb
```
Linux: 然后授予执行权限： `chmod +x intl.sh` , 执行intl.sh： `./intl.sh` <br>

Windows: Android Studio 中直接运行 `intl.sh`

### 使用`json_model`构建`json_serializable`实体类

🍎仅需一条指令 👉 `flutter packages pub run json_model`

🍎网页版 👉 <https://caijinglong.github.io/json2dart/index_ch.html>

- `json`结构字段问题:

```dart
//repoV3.dart
@JsonKey(name: "fork?")
bool fork;

//payload.dart / payload.g.dart
@JsonKey(name: "_links")
Links links;
// number 字段 为动态类型
String number;
..number = (json['number'] as Object)?.toString()

//pullRequest.dart
@JsonKey(name: "_links")
Links links;
```

- 接口版本`V3`和`V5`:`api v5`头像`avatar_url`;`v3`头像`portrait_url`

`User` -> `models/user.dart`
```dart
String avatar_url;        //
@JsonKey(name: "avatar_url")
String portrait_url;
```

## 枚举 enum 
<https://medium.com/flutter/enums-with-extensions-dart-460c42ea51f7>

```dart
///方式一
const tab_title_home = <String>["推荐项目", "热门项目", "最近更新"];

///方式二(推荐)
enum TabTitleHome {
  Recommend,
  Popular,
  Recent,
}

extension TabTitleHomeExtension on TabTitleHome {
  //eg: Recommend
  String get name => describeEnum(this);

  List<String> get  _titles => <String>["推荐项目", "热门项目", "最近更新"];

  String get _titles => titles.elementAt(this.index);
}
```

应用:
```dart
List<String> _tabs = tab_title_home.toList();
List<String> _tabs = TabTitleHome.Recommend.titles;//_titles -> titles
List<String> _tabs = TabTitleHome.values.map((e) => e.title).toList();//推荐
```

## flukit 框架使用

```dart
///========================== flukit ==============================
///
/// after_layout.dart
/// animated_rotation_box.dart
/// gradient_button.dart
/// gradient_circular_progress_indicator.dart
/// infinite_listview.dart
/// pull_refresh.dart
/// quick_scrollbar.dart
/// scale_view.dart
/// swiper.dart
/// turn_box.dart
/// utils.dart
///

///========================== GradientButton ==============================
///
///flukit-1.0.2\lib\src\gradient_button.dart 👉 颜色渐变的按钮
///
///GradientButton是由DecoratedBox、Padding、Center、InkWell等组件组合而成。
/// 然而作为一个按钮它还并不完整，比如没有禁用状态，可以根据实际需要来完善。
///
///Usage:
///     GradientButton(
///       height: 50.0,
///       colors: [Colors.lightBlue[300], Colors.blueAccent],
///       child: Text("Submit"),
///       onPressed: onTap,
///     ),

///========================== TurnBox ==============================
///
///flukit-1.0.2\lib\src\turn_box.dart 👉 旋转控件
///
///TurnBox，它不仅可以以任意角度来旋转其子节点，而且可以在角度发生变化时执行一个动画以过渡到新状态，同时可以手动指定动画速度。
///   1.通过组合RotationTransition和child来实现的旋转效果。
///   2.在didUpdateWidget中，我们判断要旋转的角度是否发生了变化，如果变了，则执行一个过渡动画。
///
///RotatedBox，它可以旋转子组件，但是它有两个缺点：
///一是只能将其子节点以90度的倍数旋转；二是当旋转的角度发生变化时，旋转角度更新过程没有动画。
///
///Usage:
///   TurnBox(
///     turns: _turns,  // `1/8`  旋转的“圈”数,一圈为360度，如0.25圈即90度
///     duration: 500,  //过渡动画执行的总时长
///     child: Icon(Icons.refresh,size: 50),
///   ),

///========================== GradientCircularProgressIndicator ==============================
///
///flukit-1.0.2\lib\src\gradient_circular_progress_indicator.dart 👉 圆形背景渐变进度条
///
/*
1.支持多种背景渐变色。2.任意弧度；进度条可以不是整圆。3.可以自定义粗细、两端是否圆角等样式。

eg:
1.
GradientCircularProgressIndicator(
  // No gradient
  colors: [Colors.blue, Colors.blue],
  radius: 50.0,
  strokeWidth: 3.0,
  value: _animationController.value,
),

2.
SizedBox(
  height: 108.0,
  width: 200.0,
  child: Stack(
    alignment: AlignmentDirectional.center,
    children: [
      TurnBox(
        turns: -0.25,
        child: GradientCircularProgressIndicator(
            colors: [Colors.red,Colors.blue,Colors.red],
            radius: 50.0,
            strokeWidth: 5.0,
            strokeCapRound: true,
            totalAngle: math.pi,
            value: CurvedAnimation(parent: _animationController, curve: Curves.linear).value),
      ),
      Center(
        child: Text(
          ///toInt 会出现达不到 100% 的问题
          '${(_animationController.value * 100).ceil()}%',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ),
    ],
  ),
),
 */
```

## BUG

##### 1. `There are multiple heroes that share the same tag within a subtree.`

- Fixed:

```dart
//首页底部导航测试时候,初始化了两个 RepoListRoute ,导致 tag 被注册了两次...￣□￣｜｜
_pageList = List();
_pageList.add(RepoListRoute());
_pageList.add(LanguageRoute());
_pageList.add(RepoListRoute());//改用其他页面路由即可
```
##### 2. `Invalid argument(s): No host specified in URI xxx.png`
`cached_network_image: ^2.3.2+1` -> `CachedNetworkImage` 

- Fixed:

```dart
Widget getAvatarCircle(String url, {double radius = 30.0, BoxFit fit = BoxFit.cover,}) {
  var placeholder = Image.asset(image_avatar_default,width: radius,height: radius);//默认头像
  if (checkUrl(url)) {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: url,width: radius,height:radius,fit:fit,
        placeholder: (context, url) => placeholder,
        errorWidget: (context, url, error) => placeholder,
      ),
    );
  } else {
    return ClipOval(child: placeholder);
  }
}
```

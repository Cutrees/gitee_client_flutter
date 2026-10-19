# 码云 Gitee 客户端

一个简洁的 Gitee 安卓客户端，基于 Flutter 开发，使用 Gitee OpenAPI v5 与 OAuth2 授权码登录。

## 当前功能

- **登录**：OAuth2 授权码模式（内嵌 WebView 授权），网页会话与 API token 同时生效，可访问私有仓库。
- **首页**：探索仓库（推荐 / 热门 / 最近更新），下拉刷新获取新一批，上滑无限加载。
- **我的**：我的仓库列表 + 关注动态（两个 Tab，默认仓库）。
- **通知**：系统通知与私信列表。
- **设置**：账号卡片（登录 / 退出）、主题颜色切换、关于应用。
- **底部导航**：首页 / 我的 / 设置，支持点击与横向拖动切换。

## 技术栈

- Flutter + Dart 3（空安全）
- Provider（状态管理）
- Dio（网络请求）+ json_serializable（模型）
- webview_flutter（网页与 OAuth 授权）

## 使用说明

- 登录使用 Gitee 官方授权页，账号密码仅在 Gitee 页面输入。
- 应用 OAuth 授权与 Gitee 网页 Cookie 会话独立；通过授权码登录后两者同时生效，可直接访问私有仓库网页。
- 退出账号时同时清除网页 Cookie。
- 开发期间不主动构建 APK，仅在明确要求打包时构建。

## 项目结构

```
lib/
├─ common/   常量、网络与缓存、OAuth、全局配置
├─ l10n/     国际化
├─ models/   JSON 实体类
├─ route/    页面路由（首页 / 我的 / 设置 / 登录 / 动态 / 通知 / 搜索）
├─ states/   跨组件共享状态
├─ ui/       自定义组件（无限列表、WebView、仓库列表项等）
└─ util/     工具类（探索分页等）
```

## 拓展功能规划（之后可能开发）

以下功能当前未实现，属于后续可选的拓展方向：

- **仓库详情**：README 渲染、文件树浏览、代码高亮、提交记录、分支 / 标签、发行版。
- **Issue / Pull Request**：列表、详情、评论（创建 / 评论需登录）。
- **收藏与关注**：Star / Watch 仓库、关注用户、我 Star 的仓库列表。
- **搜索增强**：仓库搜索、用户搜索、用户主页。
- **通知完善**：标记已读、通知详情跳转。
- **个人邮箱 / 主页展示**：当前已隐藏，受 Gitee 隐私设置影响（邮箱需在 Gitee 后台公开）。

## 构建与打包

```bash
flutter pub get
flutter run                          # 调试
flutter build apk --release           # 打包 release APK
```

> 打包前需在 Gitee OAuth 应用后台配置回调地址 `astra://callback`，并将 client_id / client_secret 通过 `--dart-define=GITEE_CLIENT_ID=...` 传入（或使用 `lib/common/const.dart` 中的默认值）。

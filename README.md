# 码云 Gitee 客户端

一个 Flutter 编写的 Gitee 安卓客户端，通过 Gitee OpenAPI v5 访问仓库、动态、通知等数据。

## 功能

- **登录**：OAuth2 授权码模式，内嵌 WebView 授权，登录后网页会话与 API 同时生效，可直接访问私有仓库。
- **首页**：探索仓库（推荐 / 热门 / 最近更新），支持下拉刷新与上滑无限加载。
- **我的**：我的仓库列表 + 关注动态。
- **通知**：系统通知与私信。
- **设置**：账号卡片（登录 / 退出）、主题色、关于。

## 技术栈

Flutter + Dart 3（空安全）、Provider、Dio、json_serializable、webview_flutter。

## 登录说明

- 账号密码仅在 Gitee 官方授权页输入。
- 授权码登录后，WebView 内保留 Gitee 会话，私有仓库网页可直接访问。
- 退出登录时同时清除网页 Cookie。

## 待开发（拓展方向）

以下功能尚未实现，作为后续可选方向：

- 仓库详情（README / 文件树 / 代码高亮 / 提交 / 分支 / 发行版）
- Issue 与 Pull Request（列表 / 详情 / 评论）
- 收藏与关注（Star / Watch / 关注用户 / 我 Star 的仓库）
- 搜索增强（仓库搜索 / 用户搜索 / 用户主页）
- 通知完善（标记已读 / 详情跳转）
- 个人邮箱与主页展示（受 Gitee 隐私设置影响）

## 构建运行

```bash
flutter pub get
flutter run
```

OAuth 的 client_id / client_secret 在 `lib/common/const.dart` 中配置，回调地址为 `astra://callback`（需与 Gitee OAuth 应用后台一致）。

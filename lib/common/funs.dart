import 'dart:convert';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:gitee_client_flutter/common/const.dart';
import 'package:gitee_client_flutter/ui/web_view.dart';

bool checkUrl(String? url) =>
    url != null && (url.startsWith('https://') || url.startsWith('http://'));

Widget getAvatarCircle(
  String? url, {
  double radius = 30.0,
  BoxFit fit = BoxFit.cover,
}) {
  final placeholder = Image.asset(
    image_avatar_default,
    width: radius,
    height: radius,
  );
  return ClipOval(
    child: checkUrl(url)
        ? CachedNetworkImage(
            imageUrl: url!,
            width: radius,
            height: radius,
            fit: fit,
            placeholder: (context, url) => placeholder,
            errorWidget: (context, url, error) => placeholder,
          )
        : placeholder,
  );
}

Widget getAvatarRect(
  String? url, {
  double width = 30.0,
  double? height,
  BoxFit fit = BoxFit.cover,
  BorderRadius? borderRadius,
}) {
  final placeholder = Image.asset(
    image_avatar_default,
    width: width,
    height: height,
  );
  return ClipRRect(
    borderRadius: borderRadius ?? BorderRadius.circular(30),
    child: checkUrl(url)
        ? CachedNetworkImage(
            imageUrl: url!,
            width: width,
            height: height,
            fit: fit,
            placeholder: (context, url) => placeholder,
            errorWidget: (context, url, error) => placeholder,
          )
        : placeholder,
  );
}

void showToast(
  String text, {
  ToastGravity gravity = ToastGravity.CENTER,
  Toast toastLength = Toast.LENGTH_SHORT,
}) {
  Fluttertoast.showToast(
    msg: text,
    toastLength: toastLength,
    gravity: gravity,
    backgroundColor: Colors.grey[600],
    fontSize: 15.0,
  );
}

void showLoading(BuildContext context, [String? text]) {
  showDialog<void>(
    barrierDismissible: false,
    context: context,
    builder: (context) => Center(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(3),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
        ),
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.all(16),
        constraints: const BoxConstraints(minHeight: 120, minWidth: 180),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              height: 30,
              width: 30,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Text(
                text ?? 'Loading...',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Color getThemePrimaryColor(BuildContext context) =>
    Theme.of(context).primaryColor;
double getStatusBarHeight() {
  final view = PlatformDispatcher.instance.views.first;
  return view.padding.top / view.devicePixelRatio;
}

double getScreenWidth(BuildContext context) =>
    MediaQuery.of(context).size.width;
double getScreenHeight(BuildContext context) =>
    MediaQuery.of(context).size.height;
String encodeBase64(String data) => base64Encode(utf8.encode(data));
String decodeBase64(String data) => utf8.decode(base64Decode(data));

String calculateFileSize(int fileByte) {
  if (fileByte < 1024) return '$fileByte B';
  if (fileByte < 1024 * 1024) return '${_keepDecimal(fileByte / 1024)} KB';
  if (fileByte < 1024 * 1024 * 1024)
    return '${_keepDecimal(fileByte / 1024 / 1024)} M';
  return '${_keepDecimal(fileByte / 1024 / 1024 / 1024)} G';
}

String _keepDecimal(double data) {
  final parts = data.toString().split('.');
  if (parts.length == 1) return parts.first;
  final decimal = parts[1];
  return '${parts.first}.${decimal.length > 2 ? decimal.substring(0, 2) : decimal}';
}

void toast(String? text) => toastOriginal(text, ToastGravity.CENTER);
void toastTop(String? text) => toastOriginal(text, ToastGravity.TOP);
void toastBottom(String? text) => toastOriginal(text, ToastGravity.BOTTOM);
void toastOriginal(String? text, ToastGravity gravity) {
  if (text == null) return;
  Fluttertoast.showToast(
    msg: text,
    toastLength: Toast.LENGTH_SHORT,
    gravity: gravity,
    timeInSecForIosWeb: 1,
    backgroundColor: Colors.black54,
    textColor: Colors.white,
    fontSize: 13,
  );
}

Future<T?> navToPage<T extends Object?>(
  BuildContext context,
  String routeName, {
  Object? arguments,
}) => Navigator.of(context).pushNamed<T>(routeName, arguments: arguments);

Future<T?> navToPage2<T extends Object?>({
  required BuildContext context,
  required Widget page,
}) => navToPage3<T>(
  context: context,
  page: MaterialPageRoute<T>(builder: (context) => page),
);

Future<T?> navToPage3<T extends Object?>({
  required BuildContext context,
  required Route<T> page,
}) => Navigator.push<T>(context, page);

Future<void> navToWeb({
  required BuildContext context,
  required String url,
}) async {
  await navToPage3<void>(
    context: context,
    page: MaterialPageRoute<void>(builder: (context) => WebViewRoute(url: url)),
  );
}

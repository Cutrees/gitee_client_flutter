import 'package:flutter_test/flutter_test.dart';
import 'package:gitee_client_flutter/util/date_label.dart';

void main() {
  group('DateLabel', () {
    test('1分钟内显示刚刚', () {
      final date = DateTime.now().subtract(Duration(seconds: 10));
      expect(DateLabel(date).toString(), '刚刚');
    });

    test('1天内显示时刻', () {
      final date = DateTime.now().subtract(Duration(minutes: 30));
      expect(RegExp(r'^\d{2}:\d{2}$').hasMatch(DateLabel(date).toString()), isTrue);
    });

    test('刚好1天前显示昨天，而不是当天的时刻', () {
      final date = DateTime.now().subtract(Duration(days: 1, hours: 1));
      expect(DateLabel(date).toString(), '昨天');
    });

    test('一周内显示天数', () {
      final date = DateTime.now().subtract(Duration(days: 3));
      expect(DateLabel(date).toString(), '3天前');
    });

    test('超过一周显示月/日', () {
      final date = DateTime.now().subtract(Duration(days: 30));
      expect(RegExp(r'^\d{2}/\d{2}$').hasMatch(DateLabel(date).toString()), isTrue);
    });

    test('超过一年显示完整日期', () {
      final date = DateTime.now().subtract(Duration(days: 400));
      expect(RegExp(r'^\d{4}/\d{2}/\d{2}$').hasMatch(DateLabel(date).toString()), isTrue);
    });
  });
}

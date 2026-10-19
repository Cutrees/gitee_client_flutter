import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';
import 'package:intl/src/intl_helpers.dart';

import 'messages_messages.dart' as english;
import 'messages_zh_CN.dart' as chinese;

MessageLookupByLibrary _lookup(String locale) =>
    locale.startsWith('zh') ? chinese.messages : english.messages;

Future<bool> initializeMessages(String localeName) async {
  final locale =
      Intl.verifiedLocale(
        localeName,
        (name) => ['zh', 'zh_CN', 'en', 'en_US', 'messages'].contains(name),
        onFailure: (_) => 'en',
      ) ??
      'en';
  initializeInternalMessageLookup(() => CompositeMessageLookup());
  messageLookup.addLocale(locale, _lookup);
  return true;
}

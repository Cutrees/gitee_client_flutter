import '../index.dart';

class LanguageRoute extends StatelessWidget {
  const LanguageRoute({super.key});
  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.primary;
    final model = context.watch<LocaleModel>();
    Widget languageItem(String label, String? value) => ListTile(
      title: Text(
        label,
        style: TextStyle(color: model.locale == value ? color : null),
      ),
      trailing: model.locale == value ? Icon(Icons.done, color: color) : null,
      onTap: () => model.locale = value,
    );
    final gm = GmLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(gm.language)),
      body: ListView(
        children: [
          languageItem('中文简体', 'zh_CN'),
          languageItem('English', 'en_US'),
          languageItem(gm.auto, null),
        ],
      ),
    );
  }
}

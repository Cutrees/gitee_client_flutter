import 'package:flutter_localizations/flutter_localizations.dart';

import 'index.dart';

void main() => Global.init().then((_) => runApp(const MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeModel>(create: (_) => ThemeModel()),
        ChangeNotifierProvider<LocaleModel>(create: (_) => LocaleModel()),
        ChangeNotifierProvider<UserModel>(create: (_) => UserModel()),
      ],
      child: Consumer2<ThemeModel, LocaleModel>(
        builder: (context, themeModel, localeModel, child) {
          final seedColor = themeModel.seedColor;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.light,
              ),
              useMaterial3: true,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: seedColor,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              visualDensity: VisualDensity.adaptivePlatformDensity,
            ),
            themeMode: ThemeMode.system,
            onGenerateTitle: (context) => GmLocalizations.of(context).title,
            home: LaunchWidget(),
            locale: localeModel.getLocale(),
            supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GmLocalizationsDelegate(),
            ],
            localeResolutionCallback: (locale, supportedLocales) {
              final configuredLocale = localeModel.getLocale();
              if (configuredLocale != null) return configuredLocale;
              return supportedLocales.contains(locale)
                  ? locale
                  : const Locale('zh', 'CN');
            },
            routes: routers,
          );
        },
      ),
    );
  }
}

import 'package:flutter_localizations/flutter_localizations.dart';

import 'index.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Global.init();
  } catch (e) {
    debugPrint('Global.init 失败: $e');
    // 初始化失败也不阻塞启动，确保进入应用，避免卡在原生启动画面。
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeModel>(create: (_) => ThemeModel()),
        ChangeNotifierProvider<UserModel>(create: (_) => UserModel()),
      ],
      child: Consumer<ThemeModel>(
        builder: (context, themeModel, child) {
          final seedColor = themeModel.seedColor;
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            navigatorKey: navigatorKey,
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
            supportedLocales: const [Locale('zh', 'CN'), Locale('en', 'US')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GmLocalizationsDelegate(),
            ],
            localeResolutionCallback: (locale, supportedLocales) {
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

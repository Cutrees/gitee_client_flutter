import '../index.dart';

class LaunchWidget extends StatefulWidget {
  const LaunchWidget({super.key});
  @override
  State<LaunchWidget> createState() => _LaunchState();
}

class _LaunchState extends State<LaunchWidget> {
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _prepare();
  }

  Future<void> _prepare() async {
    try {
      await OAuth().prepare();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(page_main);
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: _failed
          ? TextButton(
              onPressed: () {
                setState(() => _failed = false);
                _prepare();
              },
              child: const Text('初始化失败，点击重试'),
            )
          : const Text(
              '码云 Gitee',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 25),
            ),
    ),
  );
}

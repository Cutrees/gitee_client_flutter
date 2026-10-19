import 'dart:async';
import 'package:flutter/services.dart';

import 'package:connectivity_plus/connectivity_plus.dart';

import '../index.dart' hide Connectivity, ConnectivityResult;

class MainRoute extends StatefulWidget {
  const MainRoute({super.key});

  @override
  State<MainRoute> createState() => _MainRouteState();
}

class _MainRouteState extends State<MainRoute> {
  late final PageController _pageController;
  late final List<Widget> _pageList;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  int _selectedIndex = 0;
  int? _dragTarget;
  DateTime? _lastPressedAt;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageList = [HomeRoute(), MyRoute(), SettingsRoute()];
    _subscription = Connectivity().onConnectivityChanged.listen((results) {
      if (!mounted) return;
      if (results.contains(ConnectivityResult.wifi)) {
        showToast(networkWifi);
      } else if (results.contains(ConnectivityResult.mobile)) {
        showToast(networkMobile);
      } else if (results.isEmpty ||
          results.every((result) => result == ConnectivityResult.none)) {
        showToast(networkNone);
      }
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gm = GmLocalizations.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final navItems = [
      (gm.navHome, Icons.home_outlined, Icons.home),
      (gm.navMe, Icons.person_outline, Icons.person),
      ('设置', Icons.settings_outlined, Icons.settings),
    ];

    return Scaffold(
      body: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _handlePop();
        },
        child: PageView.builder(
          controller: _pageController,
          itemCount: _pageList.length,
          physics: const ClampingScrollPhysics(),
          onPageChanged: (index) {
            if (mounted) setState(() => _selectedIndex = index);
          },
          itemBuilder: (_, index) => _KeptAlivePage(child: _pageList[index]),
        ),
      ),
      bottomNavigationBar: LayoutBuilder(
        builder: (context, constraints) {
          final itemWidth = constraints.maxWidth / _pageList.length;
          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (details) {
              final index = (details.localPosition.dx / itemWidth)
                  .floor()
                  .clamp(0, _pageList.length - 1);
              if (index != _selectedIndex && index != _dragTarget) {
                _dragTarget = index;
                if (reduceMotion) {
                  _pageController.jumpToPage(index);
                } else {
                  _pageController.animateToPage(
                    index,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                  );
                }
              }
            },
            onHorizontalDragEnd: (_) => _dragTarget = null,
            onHorizontalDragCancel: () => _dragTarget = null,
            child: NavigationBar(
              selectedIndex: _selectedIndex,
              animationDuration: reduceMotion ? Duration.zero : null,
              onDestinationSelected: _onItemTapped,
              destinations: navItems
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.$2),
                      selectedIcon: Icon(item.$3),
                      label: item.$1,
                    ),
                  )
                  .toList(),
            ),
          );
        },
      ),
    );
  }

  void _handlePop() {
    final now = DateTime.now();
    if (_lastPressedAt == null ||
        now.difference(_lastPressedAt!) > const Duration(seconds: 2)) {
      _lastPressedAt = now;
      showToast('再点击一次退出应用');
      return;
    }
    SystemNavigator.pop();
  }

  Future<void> _onItemTapped(int index) async {
    if (!_pageController.hasClients) return;
    final page = _pageController.page;
    if (page == index.toDouble()) return;
    Feedback.forTap(context);
    if (MediaQuery.of(context).disableAnimations) {
      _pageController.jumpToPage(index);
      return;
    }
    await _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
    );
  }
}

class _KeptAlivePage extends StatefulWidget {
  const _KeptAlivePage({required this.child});

  final Widget child;

  @override
  State<_KeptAlivePage> createState() => _KeptAlivePageState();
}

class _KeptAlivePageState extends State<_KeptAlivePage>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}

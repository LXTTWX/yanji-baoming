import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yanji/widgets/app_bottom_navigation.dart';

/// 应用脚手架（集成底部导航栏和GoRouter）
class AppScaffold extends StatelessWidget {
  /// 导航Shell
  final StatefulNavigationShell navigationShell;

  /// 构造函数
  const AppScaffold({super.key, required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: AppBottomNavigation(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => _onTap(context, index),
      ),
    );
  }

  /// 处理底部导航点击
  void _onTap(BuildContext context, int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

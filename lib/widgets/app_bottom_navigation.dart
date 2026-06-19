import 'package:flutter/material.dart';
import 'package:yanji/core/constants/color_constants.dart';

/// 底部导航栏组件
///
/// 极简设计，仅 3 个 Tab：健身、守护、我的。
/// 选中状态赤陶色，未选中浅褐灰。
class AppBottomNavigation extends StatelessWidget {
  /// 当前选中索引
  final int currentIndex;

  /// 页面切换回调
  final ValueChanged<int> onTap;

  /// 构造函数
  const AppBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth * 0.06;
    final fontSize = screenWidth * 0.035;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.borderLight, width: 1),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.08,
            vertical: screenWidth * 0.02,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTab(
                icon: Icons.fitness_center_outlined,
                activeIcon: Icons.fitness_center,
                label: '健身',
                index: 0,
                iconSize: iconSize,
                fontSize: fontSize,
              ),
              _buildTab(
                icon: Icons.favorite_outline,
                activeIcon: Icons.favorite,
                label: '守护',
                index: 1,
                iconSize: iconSize,
                fontSize: fontSize,
              ),
              _buildTab(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: '我的',
                index: 2,
                iconSize: iconSize,
                fontSize: fontSize,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 构建单个 Tab
  Widget _buildTab({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required double iconSize,
    required double fontSize,
  }) {
    final isSelected = currentIndex == index;
    final color = isSelected ? AppColors.terracotta : AppColors.taupe;

    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: iconSize * 0.6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              size: iconSize,
              color: color,
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                color: color,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

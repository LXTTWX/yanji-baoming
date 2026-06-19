import 'package:flutter/material.dart';
import 'package:yanji/core/constants/color_constants.dart';

/// 家檐安记设计系统
///
/// 统一管理字体样式、卡片样式、间距等设计 token，
/// 确保所有页面视觉一致性。
class DesignSystem {
  DesignSystem._();

  // ==================== 字体族 ====================

  /// 衬线体（主标题/大数字）- 传达温度与品质感
  static const String serif = 'serif';

  /// 无衬线体（正文/UI 文字）
  static const String sans = 'sans-serif';

  /// 等宽体（数据数字）- 强调严谨
  static const String mono = 'monospace';

  // ==================== 文字样式 ====================

  /// 页面大标题（衬线体）
  static TextStyle pageTitle({Color? color}) => TextStyle(
        fontFamily: serif,
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.charcoal,
        height: 1.3,
      );

  /// 页面副标题（小字浅灰）
  static TextStyle pageSubtitle({Color? color}) => TextStyle(
        fontFamily: sans,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.taupe,
        height: 1.4,
      );

  /// 卡片标题（衬线体）
  static TextStyle cardTitle({Color? color}) => TextStyle(
        fontFamily: serif,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.charcoal,
        height: 1.3,
      );

  /// 卡片小标题
  static TextStyle cardSubtitle({Color? color, double size = 13}) => TextStyle(
        fontFamily: sans,
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.taupe,
      );

  /// 正文
  static TextStyle body({Color? color, double size = 15}) => TextStyle(
        fontFamily: sans,
        fontSize: size,
        fontWeight: FontWeight.w400,
        color: color ?? AppColors.charcoal,
        height: 1.5,
      );

  /// 数据数字（等宽体）
  static TextStyle dataNumber({Color? color, double size = 24}) => TextStyle(
        fontFamily: mono,
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.charcoal,
      );

  /// 大数字（衬线体）
  static TextStyle bigNumber({Color? color, double size = 32}) => TextStyle(
        fontFamily: serif,
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? AppColors.charcoal,
      );

  /// 标签文字
  static TextStyle label({Color? color, double size = 12}) => TextStyle(
        fontFamily: sans,
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? AppColors.taupe,
      );

  // ==================== 卡片样式 ====================

  /// 标准卡片装饰
  static BoxDecoration cardDecoration({Color? backgroundColor}) => BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      );

  /// 警示卡片装饰（左侧带红色竖条）
  static BoxDecoration alertCardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderLight, width: 1),
        boxShadow: const [
          BoxShadow(
            color: AppColors.cardShadow,
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      );

  // ==================== 间距 ====================

  /// 页面水平内边距
  static double pagePadding(BuildContext context) =>
      MediaQuery.of(context).size.width * 0.05;

  /// 卡片内边距
  static double cardPadding(BuildContext context) =>
      MediaQuery.of(context).size.width * 0.05;

  /// 卡片间距
  static double cardSpacing(BuildContext context) =>
      MediaQuery.of(context).size.width * 0.04;
}

/// 状态标签组件
///
/// 小圆角标签，用于显示状态（入门/需关注/稳定等）。
class StatusTag extends StatelessWidget {
  final String text;
  final Color color;
  final Color? backgroundColor;

  const StatusTag({
    super.key,
    required this.text,
    required this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

/// 家檐安记风格卡片
class HomeCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final Widget? leftAccent;

  const HomeCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.onTap,
    this.leftAccent,
  });

  @override
  Widget build(BuildContext context) {
    final cardPad = DesignSystem.cardPadding(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: padding ?? EdgeInsets.all(cardPad),
        decoration: DesignSystem.cardDecoration(backgroundColor: backgroundColor),
        child: Stack(
          children: [
            if (leftAccent != null)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: leftAccent!,
              ),
            child,
          ],
        ),
      ),
    );
  }
}

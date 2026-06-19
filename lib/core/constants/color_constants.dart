import 'package:flutter/material.dart';

/// 全局颜色常量（简约主题专用，业务页面通用引用）
///
/// 设计原则：选择在浅色/深色背景下均具备良好对比度的中性蓝绿色调。
class AppColors {
  // 主色调
  static const Color primary = Color(0xFF4A90A4);
  static const Color primaryLight = Color(0xFF6BB5C9);
  static const Color primaryDark = Color(0xFF357A8C);

  // 辅助色
  static const Color accent = Color(0xFFF5A623);
  static const Color accentLight = Color(0xFFFFD080);

  // 功能色
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFF9800);
  static const Color error = Color(0xFFE53935);
  static const Color info = Color(0xFF2196F3);

  // 医学参考色
  static const Color healthNormal = Color(0xFF4CAF50);
  static const Color healthWarning = Color(0xFFFF9800);
  static const Color healthDanger = Color(0xFFE53935);

  // 背景色
  static const Color background = Color(0xFFF5F5F5);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color card = Color(0xFFFFFFFF);

  // 文字色
  static const Color textPrimary = Color(0xFF333333);
  static const Color textSecondary = Color(0xFF666666);
  static const Color textHint = Color(0xFF999999);
  static const Color textLight = Color(0xFFFFFFFF);

  // 分割线
  static const Color divider = Color(0xFFE0E0E0);

  // ==================== 家檐安记设计规范色 ====================
  // 去医疗器械化，传递家庭陪伴温度的暖色系

  /// 页面背景：奶油白
  static const Color cream = Color(0xFFF9F5F0);

  /// 主强调色：赤陶色（行动/进度/高亮）
  static const Color terracotta = Color(0xFFC66B3D);
  static const Color terracottaLight = Color(0xFFE8A07A);

  /// 成功/稳定状态色：鼠尾草绿
  static const Color sage = Color(0xFF7A8B5C);
  static const Color sageLight = Color(0xFFA8B589);

  /// 警示/异常状态色：暗玫瑰红
  static const Color rose = Color(0xFFC64A4A);
  static const Color roseLight = Color(0xFFE8B0B0);

  /// 待办/提醒状态色：琥珀色
  static const Color amber = Color(0xFFE8A857);
  static const Color amberLight = Color(0xFFF5D4A0);

  /// 主文本色：深炭黑
  static const Color charcoal = Color(0xFF2D2418);

  /// 次要文本色：浅褐灰
  static const Color taupe = Color(0xFF8B7355);

  /// 极淡边框色
  static const Color borderLight = Color(0xFFF0EBE3);

  /// 卡片阴影色
  static const Color cardShadow = Color(0x0A2D2418);
}

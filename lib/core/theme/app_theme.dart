import 'package:flutter/material.dart';
import 'package:yanji/core/constants/color_constants.dart';
import 'package:yanji/data/models/color_scheme_config.dart';

/// 应用亮度模式枚举（亮色/暗色）
enum AppBrightnessMode {
  /// 亮色
  light,

  /// 暗色
  dark,
}

/// 色盲辅助模式枚举
enum ColorBlindMode {
  /// 关闭
  off,

  /// 红色盲（Protanopia）
  protanopia,

  /// 绿色盲（Deuteranopia）
  deuteranopia,

  /// 蓝黄色盲（Tritanopia）
  tritanopia,
}

/// 无障碍主题配置
///
/// 汇总所有影响主题生成的无障碍参数，由 [ThemeProvider] 构造后传入。
class AccessibilityConfig {
  /// 高对比度模式（禁用半透明、提升前景/背景对比度）
  final bool highContrast;

  /// 色盲辅助模式
  final ColorBlindMode colorBlindMode;

  /// 减少动画（页面切换/装饰动效降级为瞬切）
  final bool reduceMotion;

  /// 简化布局（移除阴影、降低圆角、减少装饰）
  final bool simplifiedLayout;

  /// 可点击区域放大（所有交互元素触控区下限提升）
  final bool enlargedTouchTarget;

  /// 长辈模式（叠加影响触控区与字号）
  final bool elderMode;

  /// 用户自定义字体缩放（0.8~1.8）
  final double userFontScale;

  const AccessibilityConfig({
    this.highContrast = false,
    this.colorBlindMode = ColorBlindMode.off,
    this.reduceMotion = false,
    this.simplifiedLayout = false,
    this.enlargedTouchTarget = false,
    this.elderMode = false,
    this.userFontScale = 1.0,
  });

  /// 默认配置
  const AccessibilityConfig.disabled()
      : highContrast = false,
        colorBlindMode = ColorBlindMode.off,
        reduceMotion = false,
        simplifiedLayout = false,
        enlargedTouchTarget = false,
        elderMode = false,
        userFontScale = 1.0;
}

/// 应用主题入口
///
/// 设计要点：
/// - 仅保留清新简约风格（亮色/暗色两套）
/// - 支持自定义背景色和卡片色（覆盖默认配色）
/// - 支持无障碍配置（高对比度/色盲/减少动画/简化布局/触控放大）
/// - 所有页面通过 `Theme.of(context)` 自动适配
class AppTheme {
  const AppTheme._();

  /// 根据亮度模式与自定义颜色获取对应 [ThemeData]
  ///
  /// [mode] 亮度模式
  /// [customBg] 自定义背景色，null 表示使用默认（旧参数，优先级低于 [bgScheme]）
  /// [customCard] 自定义卡片色，null 表示使用默认（旧参数，优先级低于 [cardScheme]）
  /// [bgScheme] 背景颜色方案（纯色/渐变），null 时回退到 [customBg]
  /// [cardScheme] 卡片颜色方案（纯色/渐变），null 时回退到 [customCard]
  /// [accessibility] 无障碍配置，默认关闭所有特性
  static ThemeData getTheme(
    AppBrightnessMode mode, {
    Color? customBg,
    Color? customCard,
    ColorSchemeConfig? bgScheme,
    ColorSchemeConfig? cardScheme,
    AccessibilityConfig accessibility = const AccessibilityConfig.disabled(),
  }) {
    // 解析最终生效的背景色和卡片色
    // 优先级：bgScheme > customBg > 默认
    // 渐变模式下卡片色取混合色（Card 组件不支持渐变，降级为纯色）
    final effectiveBgScheme = bgScheme ??
        (customBg != null
            ? ColorSchemeConfig.fromArgb(customBg.toARGB32())
            : null);
    final effectiveCardScheme = cardScheme ??
        (customCard != null
            ? ColorSchemeConfig.fromArgb(customCard.toARGB32())
            : null);

    final base = mode == AppBrightnessMode.light
        ? _simpleLight(effectiveBgScheme, effectiveCardScheme, accessibility)
        : _simpleDark(effectiveBgScheme, effectiveCardScheme, accessibility);
    return _applySimpleComponents(base, mode, accessibility);
  }

  /// 构建全局背景装饰 Widget
  ///
  /// 在 [MaterialApp.builder] 中作为 [Stack] 底层使用。
  /// 支持纯色和渐变背景。
  /// 高对比度或简化布局模式下禁用渐变，使用纯色以确保清晰。
  static Widget buildBackground(
    AppBrightnessMode mode, {
    Color? customBg,
    ColorSchemeConfig? bgScheme,
    AccessibilityConfig accessibility = const AccessibilityConfig.disabled(),
  }) {
    return _BackgroundBox(
      mode: mode,
      customBg: customBg,
      bgScheme: bgScheme,
      accessibility: accessibility,
    );
  }

  // ==================== 色盲配色映射 ====================

  /// 根据色盲模式返回替换后的关键色
  ///
  /// 参考 Okabe-Ito 色盲友好色板：
  /// - 红色盲：红→蓝(#0072B2)，绿→黄(#F0E442)
  /// - 绿色盲：红→蓝(#0072B2)，绿→橙(#E69F00)
  /// - 蓝黄色盲：蓝→红(#D55E00)，黄→绿(#009E73)
  static _ColorBlindPalette _resolveColorBlindPalette(
      ColorBlindMode mode, AppBrightnessMode brightness) {
    final isLight = brightness == AppBrightnessMode.light;
    switch (mode) {
      case ColorBlindMode.protanopia:
        return _ColorBlindPalette(
          primary: const Color(0xFF0072B2),
          primaryLight: const Color(0xFF56B4E9),
          success: const Color(0xFFF0E442),
          warning: const Color(0xFFE69F00),
          error: const Color(0xFF0072B2),
          info: const Color(0xFF56B4E9),
          accent: const Color(0xFFE69F00),
        );
      case ColorBlindMode.deuteranopia:
        return _ColorBlindPalette(
          primary: const Color(0xFF0072B2),
          primaryLight: const Color(0xFF56B4E9),
          success: const Color(0xFFE69F00),
          warning: const Color(0xFFE69F00),
          error: const Color(0xFF0072B2),
          info: const Color(0xFF56B4E9),
          accent: const Color(0xFFCC79A7),
        );
      case ColorBlindMode.tritanopia:
        return _ColorBlindPalette(
          primary: const Color(0xFF009E73),
          primaryLight: const Color(0xFF56B4E9),
          success: const Color(0xFF009E73),
          warning: const Color(0xFFF0E442),
          error: const Color(0xFFD55E00),
          info: const Color(0xFF009E73),
          accent: const Color(0xFFCC79A7),
        );
      case ColorBlindMode.off:
        return _ColorBlindPalette(
          primary: isLight ? AppColors.primary : AppColors.primaryLight,
          primaryLight: AppColors.primaryLight,
          success: AppColors.success,
          warning: AppColors.warning,
          error: AppColors.error,
          info: AppColors.info,
          accent: AppColors.accent,
        );
    }
  }

  // ==================== 简约主题 ====================

  /// 简约-亮色：干净清爽的 Material 3 风格
  ///
  /// [bgScheme] 背景颜色方案，null 表示使用默认
  /// [cardScheme] 卡片颜色方案，null 表示使用默认
  /// [a] 无障碍配置
  static ThemeData _simpleLight(
      ColorSchemeConfig? bgScheme, ColorSchemeConfig? cardScheme, AccessibilityConfig a) {
    final palette = _resolveColorBlindPalette(a.colorBlindMode, AppBrightnessMode.light);
    final bgColor = bgScheme?.effectiveColor ??
        (a.highContrast ? const Color(0xFFFFFFFF) : AppColors.background);
    final cardColor = cardScheme?.effectiveColor ??
        (a.highContrast ? const Color(0xFFFFFFFF) : AppColors.card);
    final textPrimary =
        a.highContrast ? const Color(0xFF000000) : AppColors.textPrimary;
    final textSecondary =
        a.highContrast ? const Color(0xFF1A1A1A) : AppColors.textSecondary;
    final textHint =
        a.highContrast ? const Color(0xFF333333) : AppColors.textHint;
    final dividerColor =
        a.highContrast ? const Color(0xFF000000) : AppColors.divider;

    final scheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: Brightness.light,
      surface: cardColor,
      primary: palette.primary,
      error: palette.error,
    );

    final minButtonHeight = _resolveMinButtonHeight(a);
    final cardRadius = a.simplifiedLayout ? 8.0 : 14.0;
    final cardElevation = a.simplifiedLayout || a.highContrast ? 0.0 : 1.0;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: bgColor,
      canvasColor: bgColor,
      appBarTheme: AppBarTheme(
        backgroundColor: a.highContrast ? const Color(0xFF000000) : palette.primary,
        foregroundColor: a.highContrast ? const Color(0xFFFFFFFF) : AppColors.textLight,
        elevation: a.simplifiedLayout ? 0 : 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: a.highContrast ? const Color(0xFFFFFFFF) : AppColors.textLight,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x1A000000),
        elevation: cardElevation,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: a.highContrast
              ? BorderSide(color: dividerColor, width: 1.5)
              : BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              a.highContrast ? const Color(0xFF000000) : palette.primary,
          foregroundColor:
              a.highContrast ? const Color(0xFFFFFFFF) : AppColors.textLight,
          minimumSize: Size(88, minButtonHeight),
          elevation: a.simplifiedLayout ? 0 : 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: a.highContrast
                ? BorderSide(color: dividerColor, width: 1.5)
                : BorderSide.none,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primary,
          minimumSize: Size(64, minButtonHeight),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primary,
          minimumSize: Size(64, minButtonHeight),
          side: BorderSide(color: palette.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: cardColor,
        indicatorColor: palette.primary.withValues(alpha: 0.2),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: a.highContrast ? 1.5 : 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: textPrimary),
      textTheme: _buildSimpleTextTheme(textPrimary, textSecondary, textHint, a),
      pageTransitionsTheme: _resolvePageTransitions(a),
    );
  }

  /// 简约-暗色：深灰底，浅蓝主色
  ///
  /// [bgScheme] 背景颜色方案，null 表示使用默认
  /// [cardScheme] 卡片颜色方案，null 表示使用默认
  /// [a] 无障碍配置
  static ThemeData _simpleDark(
      ColorSchemeConfig? bgScheme, ColorSchemeConfig? cardScheme, AccessibilityConfig a) {
    final palette = _resolveColorBlindPalette(a.colorBlindMode, AppBrightnessMode.dark);
    final bgColor = bgScheme?.effectiveColor ??
        (a.highContrast ? const Color(0xFF000000) : const Color(0xFF1A2230));
    final cardColor = cardScheme?.effectiveColor ??
        (a.highContrast ? const Color(0xFF0A0A0A) : const Color(0xFF272F3A));
    final textPrimary =
        a.highContrast ? const Color(0xFFFFFFFF) : const Color(0xFFE2E8F0);
    final textSecondary =
        a.highContrast ? const Color(0xFFE5E5E5) : const Color(0xFF94A3B8);
    final textHint =
        a.highContrast ? const Color(0xFFCCCCCC) : const Color(0xFF64748B);
    final dividerColor =
        a.highContrast ? const Color(0xFFFFFFFF) : const Color(0xFF3A4250);

    final scheme = ColorScheme.fromSeed(
      seedColor: palette.primaryLight,
      brightness: Brightness.dark,
      surface: cardColor,
      primary: palette.primaryLight,
      error: palette.error,
    );

    final minButtonHeight = _resolveMinButtonHeight(a);
    final cardRadius = a.simplifiedLayout ? 8.0 : 14.0;
    final cardElevation = a.simplifiedLayout || a.highContrast ? 0.0 : 2.0;

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: bgColor,
      canvasColor: bgColor,
      appBarTheme: AppBarTheme(
        backgroundColor:
            a.highContrast ? const Color(0xFF000000) : const Color(0xFF1F2937),
        foregroundColor: const Color(0xFFFFFFFF),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Color(0xFFFFFFFF),
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        surfaceTintColor: Colors.transparent,
        shadowColor: const Color(0x66000000),
        elevation: cardElevation,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(cardRadius),
          side: a.highContrast
              ? BorderSide(color: dividerColor, width: 1.5)
              : BorderSide.none,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              a.highContrast ? const Color(0xFFFFFFFF) : palette.primaryLight,
          foregroundColor:
              a.highContrast ? const Color(0xFF000000) : const Color(0xFF10212A),
          minimumSize: Size(88, minButtonHeight),
          elevation: a.simplifiedLayout ? 0 : 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: a.highContrast
                ? BorderSide(color: dividerColor, width: 1.5)
                : BorderSide.none,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: palette.primaryLight,
          minimumSize: Size(64, minButtonHeight),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: palette.primaryLight,
          minimumSize: Size(64, minButtonHeight),
          side: BorderSide(color: palette.primaryLight, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: bgColor,
        indicatorColor: palette.primaryLight.withValues(alpha: 0.3),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
      dividerTheme: DividerThemeData(
        color: dividerColor,
        thickness: a.highContrast ? 1.5 : 1,
        space: 1,
      ),
      iconTheme: IconThemeData(color: textPrimary),
      textTheme: _buildSimpleTextTheme(textPrimary, textSecondary, textHint, a),
      pageTransitionsTheme: _resolvePageTransitions(a),
    );
  }

  /// 计算按钮最小高度
  ///
  /// 普通模式 48dp；长辈模式 56dp；触控放大叠加 +4dp。
  static double _resolveMinButtonHeight(AccessibilityConfig a) {
    var h = a.elderMode ? 56.0 : 48.0;
    if (a.enlargedTouchTarget) {
      h += 4.0;
    }
    return h;
  }

  /// 计算页面切换主题
  ///
  /// 减少动画模式下，所有平台使用无动画瞬切。
  static PageTransitionsTheme _resolvePageTransitions(AccessibilityConfig a) {
    if (a.reduceMotion) {
      return const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _NoTransitionBuilder(),
          TargetPlatform.iOS: _NoTransitionBuilder(),
          TargetPlatform.windows: _NoTransitionBuilder(),
          TargetPlatform.macOS: _NoTransitionBuilder(),
          TargetPlatform.linux: _NoTransitionBuilder(),
          TargetPlatform.fuchsia: _NoTransitionBuilder(),
        },
      );
    }
    return const PageTransitionsTheme();
  }

  /// 构建简约主题文字样式
  ///
  /// 高对比度模式下加粗 body 文本以提升可读性。
  static TextTheme _buildSimpleTextTheme(
      Color primary, Color secondary, Color hint, AccessibilityConfig a) {
    final bodyWeight = a.highContrast ? FontWeight.w600 : FontWeight.normal;
    return TextTheme(
      headlineLarge: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      bodyLarge: TextStyle(fontSize: 16, color: primary, fontWeight: bodyWeight),
      bodyMedium:
          TextStyle(fontSize: 14, color: secondary, fontWeight: bodyWeight),
      bodySmall: TextStyle(fontSize: 12, color: hint, fontWeight: bodyWeight),
    );
  }

  /// 应用简约主题的组件级覆盖（导航栏/输入框/开关/对话框等）
  ///
  /// [a] 无障碍配置：影响输入框/开关/对话框的尺寸与对比度
  static ThemeData _applySimpleComponents(
      ThemeData base, AppBrightnessMode mode, AccessibilityConfig a) {
    final minInteractive = a.elderMode ? 56.0 : (a.enlargedTouchTarget ? 48.0 : 40.0);

    return base.copyWith(
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: mode == AppBrightnessMode.light
            ? (a.highContrast ? const Color(0xFFFAFAFA) : const Color(0xFFF5F7FA))
            : (a.highContrast ? const Color(0xFF111111) : const Color(0xFF2A3340)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: a.highContrast
              ? BorderSide(color: base.colorScheme.onSurface, width: 1.5)
              : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: a.highContrast
                ? base.colorScheme.onSurface
                : base.colorScheme.outline.withValues(alpha: 0.3),
            width: a.highContrast ? 1.5 : 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: base.colorScheme.primary, width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return base.colorScheme.primary;
          }
          return base.colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return base.colorScheme.primary.withValues(alpha: 0.4);
          }
          return base.colorScheme.surfaceContainerHighest;
        }),
        materialTapTargetSize: a.enlargedTouchTarget || a.elderMode
            ? MaterialTapTargetSize.padded
            : MaterialTapTargetSize.shrinkWrap,
      ),
      checkboxTheme: CheckboxThemeData(
        materialTapTargetSize: a.enlargedTouchTarget || a.elderMode
            ? MaterialTapTargetSize.padded
            : MaterialTapTargetSize.shrinkWrap,
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return base.colorScheme.primary;
          }
          return Colors.transparent;
        }),
        side: BorderSide(
          color: base.colorScheme.outline,
          width: a.highContrast ? 2 : 1.5,
        ),
      ),
      radioTheme: RadioThemeData(
        materialTapTargetSize: a.enlargedTouchTarget || a.elderMode
            ? MaterialTapTargetSize.padded
            : MaterialTapTargetSize.shrinkWrap,
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return base.colorScheme.primary;
          }
          return base.colorScheme.outline;
        }),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: base.cardTheme.color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(a.simplifiedLayout ? 8 : 16),
          side: a.highContrast
              ? BorderSide(color: base.colorScheme.outline, width: 1.5)
              : BorderSide.none,
        ),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: base.colorScheme.onSurface,
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: base.cardTheme.color,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          minimumSize: Size(minInteractive, minInteractive),
          tapTargetSize: a.enlargedTouchTarget || a.elderMode
              ? MaterialTapTargetSize.padded
              : MaterialTapTargetSize.shrinkWrap,
        ),
      ),
      listTileTheme: ListTileThemeData(
        minVerticalPadding: a.enlargedTouchTarget || a.elderMode ? 14 : 8,
        minLeadingWidth: a.enlargedTouchTarget || a.elderMode ? 40 : 24,
      ),
      sliderTheme: SliderThemeData(
        thumbColor: base.colorScheme.primary,
        activeTrackColor: base.colorScheme.primary,
        inactiveTrackColor: base.colorScheme.surfaceContainerHighest,
      ),
    );
  }
}

/// 色盲配色替换后的关键色集合
class _ColorBlindPalette {
  final Color primary;
  final Color primaryLight;
  final Color success;
  final Color warning;
  final Color error;
  final Color info;
  final Color accent;

  const _ColorBlindPalette({
    required this.primary,
    required this.primaryLight,
    required this.success,
    required this.warning,
    required this.error,
    required this.info,
    required this.accent,
  });
}

/// 无动画页面切换 Builder（减少动画模式专用）
class _NoTransitionBuilder extends PageTransitionsBuilder {
  const _NoTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }
}

/// 全局背景装饰 Widget
///
/// 支持三种背景模式：
/// 1. 自定义颜色方案（纯色/渐变）
/// 2. 自定义纯色（旧参数，向后兼容）
/// 3. 默认渐变
///
/// 高对比度或简化布局模式下禁用渐变，使用纯色以确保清晰。
class _BackgroundBox extends StatelessWidget {
  final AppBrightnessMode mode;
  final Color? customBg;
  final ColorSchemeConfig? bgScheme;
  final AccessibilityConfig accessibility;

  const _BackgroundBox({
    required this.mode,
    this.customBg,
    this.bgScheme,
    this.accessibility = const AccessibilityConfig.disabled(),
  });

  @override
  Widget build(BuildContext context) {
    final isLight = mode == AppBrightnessMode.light;

    // 优先使用颜色方案
    if (bgScheme != null) {
      // 高对比度或简化布局：禁用渐变，使用纯色
      if (accessibility.highContrast || accessibility.simplifiedLayout) {
        return ColoredBox(
          color: bgScheme!.effectiveColor,
          child: const SizedBox.expand(),
        );
      }
      // 渐变模式
      if (bgScheme!.isGradient) {
        return DecoratedBox(
          decoration: BoxDecoration(gradient: bgScheme!.linearGradient),
          child: const SizedBox.expand(),
        );
      }
      // 纯色模式
      return ColoredBox(
        color: bgScheme!.solidColor,
        child: const SizedBox.expand(),
      );
    }

    // 旧参数：自定义纯色
    if (customBg != null) {
      return ColoredBox(color: customBg!, child: const SizedBox.expand());
    }

    // 高对比度或简化布局：禁用渐变，使用纯色背景
    if (accessibility.highContrast || accessibility.simplifiedLayout) {
      final solidColor = isLight
          ? (accessibility.highContrast ? const Color(0xFFFFFFFF) : const Color(0xFFF5F7FA))
          : (accessibility.highContrast ? const Color(0xFF000000) : const Color(0xFF1A2230));
      return ColoredBox(color: solidColor, child: const SizedBox.expand());
    }

    // 默认背景：简约渐变
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isLight
              ? [const Color(0xFFF5F7FA), const Color(0xFFE8EDF2)]
              : [const Color(0xFF1A2230), const Color(0xFF0F1620)],
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:yanji/core/theme/app_theme.dart';
import 'package:yanji/data/models/color_scheme_config.dart';
import 'package:yanji/data/repositories/app_config_repository.dart';

/// 主题状态管理
///
/// 负责：
/// - 当前亮度模式 [AppBrightnessMode]（亮色/暗色）
/// - 长辈模式、字体缩放
/// - 自定义背景色与卡片色（支持纯色/渐变，实时生效，持久化存储）
/// - 全局背景装饰 Widget
/// - 无障碍配置（高对比度/色盲/减少动画/简化布局/触控放大/跟随系统）
class ThemeProvider extends ChangeNotifier {
  final AppConfigRepository _configRepository = AppConfigRepository();

  AppBrightnessMode _brightnessMode = AppBrightnessMode.light;
  bool _elderMode = false;
  double _fontScale = 1.0;
  Color? _customBgColor;
  Color? _customCardColor;
  ColorSchemeConfig? _bgScheme;
  ColorSchemeConfig? _cardScheme;

  // 无障碍状态
  bool _highContrast = false;
  ColorBlindMode _colorBlindMode = ColorBlindMode.off;
  bool _reduceMotion = false;
  bool _simplifiedLayout = false;
  bool _enlargedTouchTarget = false;
  bool _followSystemAccessibility = false;
  double _userFontScale = 1.0;
  bool _semanticLabelsEnabled = true;

  // 系统无障碍状态（由 main.dart 通过 setSystemAccessibility 注入）
  double _systemTextScale = 1.0;
  bool _systemHighContrast = false;
  bool _systemReduceMotion = false;

  /// 当前亮度模式
  AppBrightnessMode get brightnessMode => _brightnessMode;

  /// 是否长辈模式
  bool get elderMode => _elderMode;

  /// 字体缩放比例（最终生效值，已叠加长辈模式与系统设置）
  double get fontScale => _fontScale;

  /// 自定义背景色（null表示使用默认，旧接口，向后兼容）
  Color? get customBgColor => _customBgColor;

  /// 自定义卡片色（null表示使用默认，旧接口，向后兼容）
  Color? get customCardColor => _customCardColor;

  /// 背景颜色方案（null表示使用默认）
  ColorSchemeConfig? get bgScheme => _bgScheme;

  /// 卡片颜色方案（null表示使用默认）
  ColorSchemeConfig? get cardScheme => _cardScheme;

  /// 高对比度模式（已合并系统设置）
  bool get highContrast => _highContrast || _systemHighContrast;

  /// 色盲辅助模式
  ColorBlindMode get colorBlindMode => _colorBlindMode;

  /// 减少动画（已合并系统设置）
  bool get reduceMotion => _reduceMotion || _systemReduceMotion;

  /// 简化布局
  bool get simplifiedLayout => _simplifiedLayout;

  /// 可点击区域放大
  bool get enlargedTouchTarget => _enlargedTouchTarget;

  /// 跟随系统无障碍设置
  bool get followSystemAccessibility => _followSystemAccessibility;

  /// 用户自定义字体缩放
  double get userFontScale => _userFontScale;

  /// 屏幕朗读详细描述
  bool get semanticLabelsEnabled => _semanticLabelsEnabled;

  /// 构造当前无障碍配置
  ///
  /// 合并用户设置与系统设置：当 [followSystemAccessibility] 开启时，
  /// 系统的高对比度/减少动画/字体缩放会叠加到用户设置上。
  AccessibilityConfig get accessibilityConfig => AccessibilityConfig(
        highContrast: highContrast,
        colorBlindMode: _colorBlindMode,
        reduceMotion: reduceMotion,
        simplifiedLayout: _simplifiedLayout,
        enlargedTouchTarget: _enlargedTouchTarget,
        elderMode: _elderMode,
        userFontScale: _userFontScale,
      );

  /// 获取当前主题数据
  ///
  /// 同时考虑亮度模式 + 自定义颜色方案 + 字体缩放 + 无障碍配置，
  /// 业务页面只需 `Theme.of(context)` 即可拿到正确样式。
  ThemeData get theme {
    final baseTheme = AppTheme.getTheme(
      _brightnessMode,
      customBg: _customBgColor,
      customCard: _customCardColor,
      bgScheme: _bgScheme,
      cardScheme: _cardScheme,
      accessibility: accessibilityConfig,
    );
    return baseTheme.copyWith(
      textTheme: baseTheme.textTheme.apply(
        fontSizeFactor: _fontScale,
      ),
    );
  }

  /// 全局背景装饰 Widget
  ///
  /// 在 [MaterialApp.builder] 中作为 [Stack] 底层使用，
  /// 上层为路由 Navigator。Scaffold 背景透明，透出此装饰层。
  Widget get backgroundWidget => AppTheme.buildBackground(
        _brightnessMode,
        customBg: _customBgColor,
        bgScheme: _bgScheme,
        accessibility: accessibilityConfig,
      );

  /// 初始化配置
  Future<void> init() async {
    final config = await _configRepository.getConfig();
    _brightnessMode = AppBrightnessMode.values[config.brightnessMode];
    _elderMode = config.elderMode;
    _userFontScale = config.userFontScale;
    _customBgColor = config.customBackgroundColor != null
        ? Color(config.customBackgroundColor!)
        : null;
    _customCardColor = config.customCardColor != null
        ? Color(config.customCardColor!)
        : null;
    // 加载颜色方案：优先使用新字段，为空时从旧字段迁移
    if (config.backgroundScheme != null) {
      _bgScheme = ColorSchemeConfig.fromJson(config.backgroundScheme!);
    } else if (_customBgColor != null) {
      _bgScheme = ColorSchemeConfig.fromArgb(_customBgColor!.toARGB32());
    } else {
      _bgScheme = null;
    }
    if (config.cardScheme != null) {
      _cardScheme = ColorSchemeConfig.fromJson(config.cardScheme!);
    } else if (_customCardColor != null) {
      _cardScheme = ColorSchemeConfig.fromArgb(_customCardColor!.toARGB32());
    } else {
      _cardScheme = null;
    }
    _highContrast = config.highContrastMode;
    _colorBlindMode = ColorBlindMode.values[config.colorBlindMode.clamp(0, 3)];
    _reduceMotion = config.reduceMotion;
    _simplifiedLayout = config.simplifiedLayout;
    _enlargedTouchTarget = config.enlargedTouchTarget;
    _followSystemAccessibility = config.followSystemAccessibility;
    _semanticLabelsEnabled = config.semanticLabelsEnabled;
    _recomputeFontScale();
    notifyListeners();
  }

  /// 由 main.dart 注入系统无障碍状态
  ///
  /// 当 [followSystemAccessibility] 开启时，会触发重新计算字体缩放与通知刷新。
  void setSystemAccessibility({
    required double textScale,
    required bool highContrast,
    required bool reduceMotion,
  }) {
    _systemTextScale = textScale;
    _systemHighContrast = highContrast;
    _systemReduceMotion = reduceMotion;
    if (_followSystemAccessibility) {
      _recomputeFontScale();
      notifyListeners();
    }
  }

  /// 重新计算最终字体缩放
  ///
  /// 规则：base = followSystem ? systemTextScale : userFontScale
  /// 最终 fontScale = base * (elderMode ? 1.2 : 1.0)，并限制在 [0.8, 1.8]。
  void _recomputeFontScale() {
    final base = _followSystemAccessibility ? _systemTextScale : _userFontScale;
    final combined = base * (_elderMode ? 1.2 : 1.0);
    _fontScale = combined.clamp(0.8, 1.8);
  }

  /// 切换亮度模式（亮色/暗色）
  Future<void> setBrightnessMode(AppBrightnessMode mode) async {
    _brightnessMode = mode;
    await _configRepository.updateBrightnessMode(mode.index);
    notifyListeners();
  }

  /// 切换长辈模式
  ///
  /// 长辈模式开启时，字体缩放叠加 1.2 倍；关闭时恢复用户设置。
  Future<void> toggleElderMode() async {
    _elderMode = !_elderMode;
    await _configRepository.updateElderMode(_elderMode);
    _recomputeFontScale();
    notifyListeners();
  }

  /// 设置自定义背景色（null表示恢复默认）
  Future<void> setCustomBackgroundColor(Color? color) async {
    _customBgColor = color;
    await _configRepository.updateCustomBackgroundColor(color?.toARGB32());
    // 同步更新颜色方案为纯色模式
    if (color != null) {
      _bgScheme = ColorSchemeConfig.fromArgb(color.toARGB32());
      await _configRepository.updateBackgroundScheme(_bgScheme!.toJson());
    } else {
      _bgScheme = null;
      await _configRepository.updateBackgroundScheme(null);
    }
    notifyListeners();
  }

  /// 设置自定义卡片色（null表示恢复默认）
  Future<void> setCustomCardColor(Color? color) async {
    _customCardColor = color;
    await _configRepository.updateCustomCardColor(color?.toARGB32());
    // 同步更新颜色方案为纯色模式
    if (color != null) {
      _cardScheme = ColorSchemeConfig.fromArgb(color.toARGB32());
      await _configRepository.updateCardScheme(_cardScheme!.toJson());
    } else {
      _cardScheme = null;
      await _configRepository.updateCardScheme(null);
    }
    notifyListeners();
  }

  /// 设置背景颜色方案（null表示恢复默认）
  Future<void> setBackgroundScheme(ColorSchemeConfig? scheme) async {
    _bgScheme = scheme;
    // 同步旧字段（纯色模式下写入，渐变模式下写入混合色）
    if (scheme != null) {
      _customBgColor = scheme.effectiveColor;
      await _configRepository.updateCustomBackgroundColor(
          scheme.effectiveColor.toARGB32());
      await _configRepository.updateBackgroundScheme(scheme.toJson());
    } else {
      _customBgColor = null;
      await _configRepository.updateCustomBackgroundColor(null);
      await _configRepository.updateBackgroundScheme(null);
    }
    notifyListeners();
  }

  /// 设置卡片颜色方案（null表示恢复默认）
  Future<void> setCardScheme(ColorSchemeConfig? scheme) async {
    _cardScheme = scheme;
    // 同步旧字段
    if (scheme != null) {
      _customCardColor = scheme.effectiveColor;
      await _configRepository.updateCustomCardColor(
          scheme.effectiveColor.toARGB32());
      await _configRepository.updateCardScheme(scheme.toJson());
    } else {
      _customCardColor = null;
      await _configRepository.updateCustomCardColor(null);
      await _configRepository.updateCardScheme(null);
    }
    notifyListeners();
  }

  /// 重置所有自定义颜色为默认
  Future<void> resetCustomColors() async {
    _customBgColor = null;
    _customCardColor = null;
    _bgScheme = null;
    _cardScheme = null;
    await _configRepository.updateCustomBackgroundColor(null);
    await _configRepository.updateCustomCardColor(null);
    await _configRepository.updateBackgroundScheme(null);
    await _configRepository.updateCardScheme(null);
    notifyListeners();
  }

  // ==================== 无障碍设置 ====================

  /// 更新高对比度模式
  Future<void> setHighContrast(bool value) async {
    _highContrast = value;
    await _configRepository.updateHighContrastMode(value);
    notifyListeners();
  }

  /// 更新色盲辅助模式
  Future<void> setColorBlindMode(ColorBlindMode mode) async {
    _colorBlindMode = mode;
    await _configRepository.updateColorBlindMode(mode.index);
    notifyListeners();
  }

  /// 更新减少动画
  Future<void> setReduceMotion(bool value) async {
    _reduceMotion = value;
    await _configRepository.updateReduceMotion(value);
    notifyListeners();
  }

  /// 更新简化布局
  Future<void> setSimplifiedLayout(bool value) async {
    _simplifiedLayout = value;
    await _configRepository.updateSimplifiedLayout(value);
    notifyListeners();
  }

  /// 更新可点击区域放大
  Future<void> setEnlargedTouchTarget(bool value) async {
    _enlargedTouchTarget = value;
    await _configRepository.updateEnlargedTouchTarget(value);
    notifyListeners();
  }

  /// 更新跟随系统无障碍设置
  ///
  /// 开启后立即用当前系统状态重新计算字体缩放。
  Future<void> setFollowSystemAccessibility(bool value) async {
    _followSystemAccessibility = value;
    await _configRepository.updateFollowSystemAccessibility(value);
    _recomputeFontScale();
    notifyListeners();
  }

  /// 更新用户自定义字体缩放（0.8~1.8）
  Future<void> setUserFontScale(double value) async {
    _userFontScale = value.clamp(0.8, 1.8);
    await _configRepository.updateUserFontScale(_userFontScale);
    _recomputeFontScale();
    notifyListeners();
  }

  /// 更新屏幕朗读详细描述
  Future<void> setSemanticLabelsEnabled(bool value) async {
    _semanticLabelsEnabled = value;
    await _configRepository.updateSemanticLabelsEnabled(value);
    notifyListeners();
  }
}

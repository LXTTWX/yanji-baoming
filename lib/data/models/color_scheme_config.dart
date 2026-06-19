import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';

/// 颜色方案模式
enum ColorSchemeMode {
  /// 纯色
  solid,
  /// 渐变
  gradient,
}

/// 颜色方案配置
///
/// 支持两种模式：
/// - [ColorSchemeMode.solid]：纯色，仅使用 [solidColor]
/// - [ColorSchemeMode.gradient]：渐变，使用起始色、结束色、角度、强度
///
/// 序列化为 JSON 字符串存储到 Hive，避免扩展字段。
class ColorSchemeConfig {
  /// 颜色模式
  final ColorSchemeMode mode;

  /// 纯色模式的颜色
  final Color solidColor;

  /// 渐变起始色
  final Color gradientStart;

  /// 渐变结束色
  final Color gradientEnd;

  /// 渐变角度（0-360度，0=从左到右，90=从上到下）
  final double gradientAngle;

  /// 渐变强度（0.0-1.0，控制颜色浓度/不透明度）
  final double gradientIntensity;

  /// 默认配置（浅灰纯色）
  static const ColorSchemeConfig defaultBackground = ColorSchemeConfig(
    mode: ColorSchemeMode.solid,
    solidColor: Color(0xFFF5F7FA),
  );

  /// 默认卡片配置（白色纯色）
  static const ColorSchemeConfig defaultCard = ColorSchemeConfig(
    mode: ColorSchemeMode.solid,
    solidColor: Color(0xFFFFFFFF),
  );

  /// 构造函数
  const ColorSchemeConfig({
    this.mode = ColorSchemeMode.solid,
    this.solidColor = const Color(0xFFFFFFFF),
    this.gradientStart = const Color(0xFFE3F2FD),
    this.gradientEnd = const Color(0xFFF3E5F5),
    this.gradientAngle = 45,
    this.gradientIntensity = 1.0,
  });

  /// 从旧的单色值创建（向后兼容迁移）
  factory ColorSchemeConfig.fromArgb(int argb) {
    return ColorSchemeConfig(
      mode: ColorSchemeMode.solid,
      solidColor: Color(argb),
    );
  }

  /// 从 JSON 字符串反序列化
  factory ColorSchemeConfig.fromJson(String jsonStr) {
    try {
      final map = json.decode(jsonStr) as Map<String, dynamic>;
      return ColorSchemeConfig(
        mode: (map['mode'] as int? ?? 0) == 1
            ? ColorSchemeMode.gradient
            : ColorSchemeMode.solid,
        solidColor: Color(map['solidColor'] as int? ?? 0xFFFFFFFF),
        gradientStart: Color(map['gradientStart'] as int? ?? 0xFFE3F2FD),
        gradientEnd: Color(map['gradientEnd'] as int? ?? 0xFFF3E5F5),
        gradientAngle: (map['gradientAngle'] as num?)?.toDouble() ?? 45,
        gradientIntensity:
            ((map['gradientIntensity'] as num?)?.toDouble() ?? 1.0)
                .clamp(0.1, 1.0),
      );
    } catch (_) {
      return const ColorSchemeConfig();
    }
  }

  /// 序列化为 JSON 字符串
  String toJson() {
    return json.encode({
      'mode': mode == ColorSchemeMode.gradient ? 1 : 0,
      'solidColor': solidColor.toARGB32(),
      'gradientStart': gradientStart.toARGB32(),
      'gradientEnd': gradientEnd.toARGB32(),
      'gradientAngle': gradientAngle,
      'gradientIntensity': gradientIntensity,
    });
  }

  /// 复制并修改
  ColorSchemeConfig copyWith({
    ColorSchemeMode? mode,
    Color? solidColor,
    Color? gradientStart,
    Color? gradientEnd,
    double? gradientAngle,
    double? gradientIntensity,
  }) {
    return ColorSchemeConfig(
      mode: mode ?? this.mode,
      solidColor: solidColor ?? this.solidColor,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
      gradientAngle: gradientAngle ?? this.gradientAngle,
      gradientIntensity: gradientIntensity ?? this.gradientIntensity,
    );
  }

  /// 获取渐变方向（起始 Alignment）
  ///
  /// 将角度转换为 LinearGradient 的 begin Alignment。
  /// 0度=从左到右，90度=从上到下，180度=从右到左，270度=从下到上。
  Alignment get gradientBeginAlignment {
    final rad = gradientAngle * pi / 180;
    return Alignment(cos(rad) * -1, sin(rad) * -1);
  }

  /// 获取渐变结束方向
  Alignment get gradientEndAlignment {
    final rad = gradientAngle * pi / 180;
    return Alignment(cos(rad), sin(rad));
  }

  /// 构建渐变颜色列表（应用强度/透明度）
  ///
  /// [intensity] 为 1.0 时完全不透明，为 0.5 时半透明。
  List<Color> get gradientColors {
    return [
      gradientStart.withValues(alpha: gradientIntensity),
      gradientEnd.withValues(alpha: gradientIntensity),
    ];
  }

  /// 构建线性渐变对象
  LinearGradient get linearGradient {
    return LinearGradient(
      begin: gradientBeginAlignment,
      end: gradientEndAlignment,
      colors: gradientColors,
    );
  }

  /// 获取用于 Card 降级渲染的混合色
  ///
  /// Flutter 的 CardTheme.color 不支持渐变，
  /// 渐变模式下取起始色和结束色按强度加权平均作为降级纯色。
  Color get blendColor {
    if (mode == ColorSchemeMode.solid) return solidColor;
    // 按强度混合：强度越高，颜色越接近起始色；强度越低，越接近结束色
    final t = gradientIntensity.clamp(0.0, 1.0);
    return Color.lerp(gradientEnd, gradientStart, t) ?? solidColor;
  }

  /// 获取实际生效的纯色（纯色模式直接返回，渐变模式返回混合色）
  Color get effectiveColor => blendColor;

  /// 是否为渐变模式
  bool get isGradient => mode == ColorSchemeMode.gradient;

  /// 判断颜色是否为浅色（用于选择前景文字颜色）
  bool get isLightColor => effectiveColor.computeLuminance() > 0.5;
}

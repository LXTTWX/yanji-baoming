import 'dart:math';
import 'package:flutter/material.dart';
import 'package:yanji/data/models/color_scheme_config.dart';

/// 颜色方案编辑器对话框
///
/// 提供完整的颜色方案编辑功能：
/// - 模式切换（纯色/渐变）
/// - HSV 色盘选择器（色相环 + 饱和度/亮度方块）
/// - 渐变控制（起始色、结束色、方向、强度）
/// - 预设色板快捷选择
/// - 实时预览
class ColorSchemeEditorDialog extends StatefulWidget {
  /// 标题
  final String title;

  /// 初始颜色方案
  final ColorSchemeConfig initialScheme;

  /// 是否为背景色（影响默认预设和预览样式）
  final bool isBackground;

  /// 构造函数
  const ColorSchemeEditorDialog({
    super.key,
    required this.title,
    required this.initialScheme,
    this.isBackground = true,
  });

  @override
  State<ColorSchemeEditorDialog> createState() =>
      _ColorSchemeEditorDialogState();
}

class _ColorSchemeEditorDialogState extends State<ColorSchemeEditorDialog> {
  late ColorSchemeConfig _scheme;

  @override
  void initState() {
    super.initState();
    _scheme = widget.initialScheme;
  }

  /// 切换模式
  void _switchMode(ColorSchemeMode mode) {
    setState(() {
      _scheme = _scheme.copyWith(mode: mode);
    });
  }

  /// 更新纯色
  void _setSolidColor(Color color) {
    setState(() {
      _scheme = _scheme.copyWith(solidColor: color);
    });
  }

  /// 更新渐变起始色
  void _setGradientStart(Color color) {
    setState(() {
      _scheme = _scheme.copyWith(gradientStart: color);
    });
  }

  /// 更新渐变结束色
  void _setGradientEnd(Color color) {
    setState(() {
      _scheme = _scheme.copyWith(gradientEnd: color);
    });
  }

  /// 更新渐变角度
  void _setGradientAngle(double angle) {
    setState(() {
      _scheme = _scheme.copyWith(gradientAngle: angle);
    });
  }

  /// 更新渐变强度
  void _setGradientIntensity(double intensity) {
    setState(() {
      _scheme = _scheme.copyWith(gradientIntensity: intensity);
    });
  }

  /// 选择预设色板
  void _selectPreset(ColorSchemeConfig preset) {
    setState(() {
      _scheme = preset;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sw = MediaQuery.of(context).size.width;
    final padding = sw * 0.04;

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
          maxWidth: sw * 0.92,
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 标题栏
              _buildHeader(theme, padding),
              SizedBox(height: padding * 0.5),
              // 预览区
              _buildPreview(theme, padding),
              SizedBox(height: padding * 0.5),
              // 模式切换
              _buildModeSelector(theme, padding),
              SizedBox(height: padding * 0.5),
              // 内容区（根据模式显示不同控件）
              Flexible(
                child: SingleChildScrollView(
                  child: _scheme.isGradient
                      ? _buildGradientControls(theme, padding)
                      : _buildSolidControls(theme, padding),
                ),
              ),
              SizedBox(height: padding * 0.5),
              // 预设色板
              _buildPresetPalette(theme, padding),
              SizedBox(height: padding * 0.5),
              // 操作按钮
              _buildActions(theme, padding),
            ],
          ),
        ),
      ),
    );
  }

  /// 标题栏
  Widget _buildHeader(ThemeData theme, double padding) {
    return Row(
      children: [
        Icon(Icons.palette, color: theme.colorScheme.primary),
        SizedBox(width: padding * 0.3),
        Expanded(
          child: Text(widget.title,
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  /// 预览区
  Widget _buildPreview(ThemeData theme, double padding) {
    return Container(
      width: double.infinity,
      height: padding * 3.5,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        gradient: _scheme.isGradient ? _scheme.linearGradient : null,
        color: _scheme.isGradient ? null : _scheme.solidColor,
      ),
      child: Center(
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: padding * 0.6, vertical: padding * 0.3),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            _scheme.isGradient ? '渐变预览' : '纯色预览',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _scheme.effectiveColor,
            ),
          ),
        ),
      ),
    );
  }

  /// 模式切换器
  Widget _buildModeSelector(ThemeData theme, double padding) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildModeTab(
              theme,
              padding,
              icon: Icons.circle,
              label: '纯色',
              isSelected: !_scheme.isGradient,
              onTap: () => _switchMode(ColorSchemeMode.solid),
            ),
          ),
          Expanded(
            child: _buildModeTab(
              theme,
              padding,
              icon: Icons.gradient,
              label: '渐变',
              isSelected: _scheme.isGradient,
              onTap: () => _switchMode(ColorSchemeMode.gradient),
            ),
          ),
        ],
      ),
    );
  }

  /// 模式标签
  Widget _buildModeTab(ThemeData theme, double padding,
      {required IconData icon,
      required String label,
      required bool isSelected,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: padding * 0.4),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 18,
                color: isSelected
                    ? Colors.white
                    : theme.colorScheme.onSurfaceVariant),
            SizedBox(width: padding * 0.2),
            Text(label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : theme.colorScheme.onSurfaceVariant,
                )),
          ],
        ),
      ),
    );
  }

  /// 纯色模式控件
  Widget _buildSolidControls(ThemeData theme, double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('选择颜色',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant)),
        SizedBox(height: padding * 0.4),
        HsvColorPicker(
          currentColor: _scheme.solidColor,
          onColorChanged: _setSolidColor,
        ),
      ],
    );
  }

  /// 渐变模式控件
  Widget _buildGradientControls(ThemeData theme, double padding) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 起始色
        Text('起始色',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant)),
        SizedBox(height: padding * 0.3),
        HsvColorPicker(
          currentColor: _scheme.gradientStart,
          onColorChanged: _setGradientStart,
        ),
        SizedBox(height: padding * 0.5),
        // 结束色
        Text('结束色',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant)),
        SizedBox(height: padding * 0.3),
        HsvColorPicker(
          currentColor: _scheme.gradientEnd,
          onColorChanged: _setGradientEnd,
        ),
        SizedBox(height: padding * 0.5),
        // 渐变方向
        Text('渐变方向：${_scheme.gradientAngle.round()}°',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant)),
        SizedBox(height: padding * 0.2),
        _buildAngleSelector(theme, padding),
        SizedBox(height: padding * 0.5),
        // 渐变强度
        Text('渐变强度：${(_scheme.gradientIntensity * 100).round()}%',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant)),
        SizedBox(height: padding * 0.2),
        Slider(
          value: _scheme.gradientIntensity,
          min: 0.1,
          max: 1.0,
          divisions: 18,
          onChanged: _setGradientIntensity,
        ),
      ],
    );
  }

  /// 角度选择器（8个方向 + 自定义滑块）
  Widget _buildAngleSelector(ThemeData theme, double padding) {
    const angles = [0, 45, 90, 135, 180, 225, 270, 315];
    return Wrap(
      spacing: padding * 0.3,
      runSpacing: padding * 0.3,
      children: [
        for (final angle in angles)
          GestureDetector(
            onTap: () => _setGradientAngle(angle.toDouble()),
            child: Container(
              width: padding * 1.8,
              height: padding * 1.8,
              decoration: BoxDecoration(
                color: (_scheme.gradientAngle.round() == angle)
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: (_scheme.gradientAngle.round() == angle)
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Center(
                child: Transform.rotate(
                  angle: angle * pi / 180,
                  child: Icon(Icons.arrow_forward,
                      size: 18,
                      color: (_scheme.gradientAngle.round() == angle)
                          ? Colors.white
                          : theme.colorScheme.onSurfaceVariant),
                ),
              ),
            ),
          ),
        // 自定义角度滑块
        SizedBox(
          width: double.infinity,
          child: Slider(
            value: _scheme.gradientAngle,
            min: 0,
            max: 360,
            divisions: 72,
            onChanged: _setGradientAngle,
          ),
        ),
      ],
    );
  }

  /// 预设色板
  Widget _buildPresetPalette(ThemeData theme, double padding) {
    final presets = widget.isBackground
        ? _backgroundPresets
        : _cardPresets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('快捷预设',
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant)),
        SizedBox(height: padding * 0.3),
        SizedBox(
          height: padding * 2.2,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: presets.length,
            separatorBuilder: (context, index) => SizedBox(width: padding * 0.3),
            itemBuilder: (context, index) {
              final preset = presets[index];
              return GestureDetector(
                onTap: () => _selectPreset(preset),
                child: Container(
                  width: padding * 2.2,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _scheme.toJson() == preset.toJson()
                          ? theme.colorScheme.primary
                          : theme.colorScheme.outline.withValues(alpha: 0.3),
                      width: _scheme.toJson() == preset.toJson() ? 3 : 1.5,
                    ),
                    gradient: preset.isGradient ? preset.linearGradient : null,
                    color: preset.isGradient ? null : preset.solidColor,
                  ),
                  child: preset.isGradient
                      ? Center(
                          child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('渐变',
                                style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold)),
                          ),
                        )
                      : null,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  /// 操作按钮
  Widget _buildActions(ThemeData theme, double padding) {
    return Row(
      children: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('取消'),
        ),
        const Spacer(),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(null);
          },
          child: const Text('恢复默认'),
        ),
        SizedBox(width: padding * 0.3),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_scheme),
          child: const Text('确定'),
        ),
      ],
    );
  }
}

/// 背景色预设
final List<ColorSchemeConfig> _backgroundPresets = [
  const ColorSchemeConfig(
      mode: ColorSchemeMode.solid, solidColor: Color(0xFFF5F7FA)),
  const ColorSchemeConfig(
      mode: ColorSchemeMode.solid, solidColor: Color(0xFFE3F2FD)),
  const ColorSchemeConfig(
      mode: ColorSchemeMode.solid, solidColor: Color(0xFFE8F5E9)),
  const ColorSchemeConfig(
      mode: ColorSchemeMode.solid, solidColor: Color(0xFFFCE4EC)),
  const ColorSchemeConfig(
      mode: ColorSchemeMode.solid, solidColor: Color(0xFF263238)),
  const ColorSchemeConfig(
      mode: ColorSchemeMode.gradient,
      gradientStart: Color(0xFFE3F2FD),
      gradientEnd: Color(0xFFF3E5F5),
      gradientAngle: 135,
      gradientIntensity: 1.0),
  const ColorSchemeConfig(
      mode: ColorSchemeMode.gradient,
      gradientStart: Color(0xFFFFF8E1),
      gradientEnd: Color(0xFFFFF3E0),
      gradientAngle: 180,
      gradientIntensity: 1.0),
  const ColorSchemeConfig(
      mode: ColorSchemeMode.gradient,
      gradientStart: Color(0xFF1A237E),
      gradientEnd: Color(0xFF311B92),
      gradientAngle: 135,
      gradientIntensity: 1.0),
];

/// 卡片色预设
final List<ColorSchemeConfig> _cardPresets = [
  const ColorSchemeConfig(
      mode: ColorSchemeMode.solid, solidColor: Color(0xFFFFFFFF)),
  const ColorSchemeConfig(
      mode: ColorSchemeMode.solid, solidColor: Color(0xFFF5F5F5)),
  const ColorSchemeConfig(
      mode: ColorSchemeMode.solid, solidColor: Color(0xFFE1F5FE)),
  const ColorSchemeConfig(
      mode: ColorSchemeMode.solid, solidColor: Color(0xFFF1F8E9)),
  const ColorSchemeConfig(
      mode: ColorSchemeMode.solid, solidColor: Color(0xFF37474F)),
  const ColorSchemeConfig(
      mode: ColorSchemeMode.gradient,
      gradientStart: Color(0xFFFFFFFF),
      gradientEnd: Color(0xFFF5F5F5),
      gradientAngle: 180,
      gradientIntensity: 1.0),
  const ColorSchemeConfig(
      mode: ColorSchemeMode.gradient,
      gradientStart: Color(0xFFFFF3E0),
      gradientEnd: Color(0xFFFFE0B2),
      gradientAngle: 135,
      gradientIntensity: 0.8),
];

/// HSV 颜色选择器
///
/// 上方为色相环（HSV中的H），下方为饱和度-亮度方块（SV）。
/// 拖动选择颜色，实时回调。
class HsvColorPicker extends StatefulWidget {
  /// 当前颜色
  final Color currentColor;

  /// 颜色变化回调
  final ValueChanged<Color> onColorChanged;

  /// 构造函数
  const HsvColorPicker({
    super.key,
    required this.currentColor,
    required this.onColorChanged,
  });

  @override
  State<HsvColorPicker> createState() => _HsvColorPickerState();
}

class _HsvColorPickerState extends State<HsvColorPicker> {
  HSVColor get _hsv => HSVColor.fromColor(widget.currentColor);

  /// 更新色相
  void _updateHue(double hue) {
    widget.onColorChanged(_hsv.withHue(hue).toColor());
  }

  /// 更新饱和度和亮度
  void _updateSaturationValue(double saturation, double value) {
    widget.onColorChanged(
        _hsv.withSaturation(saturation).withValue(value).toColor());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sw = MediaQuery.of(context).size.width;
    final size = sw * 0.7;

    return Column(
      children: [
        // 色相滑块
        _buildHueSlider(theme, size),
        SizedBox(height: sw * 0.03),
        // 饱和度-亮度方块
        _buildSaturationValueArea(theme, size),
        SizedBox(height: sw * 0.03),
        // 当前颜色显示
        _buildCurrentColorDisplay(theme, sw),
      ],
    );
  }

  /// 色相滑块（水平彩虹条）
  Widget _buildHueSlider(ThemeData theme, double width) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('色相：${(_hsv.hue).round()}°',
            style: TextStyle(
                fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
        SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            final sliderWidth = width;
            return GestureDetector(
              onPanUpdate: (details) {
                final renderBox = context.findRenderObject() as RenderBox;
                final localPos = renderBox.globalToLocal(details.globalPosition);
                final ratio = (localPos.dx / sliderWidth).clamp(0.0, 1.0);
                _updateHue(ratio * 360);
              },
              onTapDown: (details) {
                final renderBox = context.findRenderObject() as RenderBox;
                final localPos = renderBox.globalToLocal(details.globalPosition);
                final ratio = (localPos.dx / sliderWidth).clamp(0.0, 1.0);
                _updateHue(ratio * 360);
              },
              child: Container(
                width: sliderWidth,
                height: 28,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFFF0000),
                      const Color(0xFFFFFF00),
                      const Color(0xFF00FF00),
                      const Color(0xFF00FFFF),
                      const Color(0xFF0000FF),
                      const Color(0xFFFF00FF),
                      const Color(0xFFFF0000),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      left: (sliderWidth * _hsv.hue / 360) - 10,
                      top: 0,
                      bottom: 0,
                      child: Center(
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _hsv.toColor(),
                            border: Border.all(color: Colors.white, width: 3),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// 饱和度-亮度选择区域
  ///
  /// 横轴为饱和度（0-1），纵轴为亮度（1-0）。
  /// 背景为当前色相下的 SV 渐变。
  Widget _buildSaturationValueArea(ThemeData theme, double size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
            '饱和度：${(_hsv.saturation * 100).round()}%  亮度：${(_hsv.value * 100).round()}%',
            style: TextStyle(
                fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
        SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            final areaSize = size;
            return GestureDetector(
              onPanUpdate: (details) {
                final renderBox = context.findRenderObject() as RenderBox;
                final localPos = renderBox.globalToLocal(details.globalPosition);
                final s = (localPos.dx / areaSize).clamp(0.0, 1.0);
                final v = 1.0 - (localPos.dy / areaSize).clamp(0.0, 1.0);
                _updateSaturationValue(s, v);
              },
              onTapDown: (details) {
                final renderBox = context.findRenderObject() as RenderBox;
                final localPos = renderBox.globalToLocal(details.globalPosition);
                final s = (localPos.dx / areaSize).clamp(0.0, 1.0);
                final v = 1.0 - (localPos.dy / areaSize).clamp(0.0, 1.0);
                _updateSaturationValue(s, v);
              },
              child: Container(
                width: areaSize,
                height: areaSize,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white,
                      _hsv.withSaturation(1).withValue(1).toColor(),
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    // 亮度遮罩（从上到下：白色到黑色）
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black,
                          ],
                        ),
                      ),
                    ),
                    // 当前位置指示器
                    Positioned(
                      left: areaSize * _hsv.saturation - 10,
                      top: areaSize * (1 - _hsv.value) - 10,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _hsv.toColor(),
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: const [
                            BoxShadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(0, 2)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// 当前颜色显示
  Widget _buildCurrentColorDisplay(ThemeData theme, double sw) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: widget.currentColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.3)),
          ),
        ),
        SizedBox(width: sw * 0.03),
        Expanded(
          child: Text(
            'RGB(${(widget.currentColor.r * 255).round().clamp(0, 255)}, ${(widget.currentColor.g * 255).round().clamp(0, 255)}, ${(widget.currentColor.b * 255).round().clamp(0, 255)})\n'
            '#${widget.currentColor.toARGB32().toRadixString(16).toUpperCase().padLeft(8, '0')}',
            style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4),
          ),
        ),
      ],
    );
  }
}

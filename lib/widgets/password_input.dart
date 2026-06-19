import 'package:flutter/material.dart';
import 'package:yanji/core/constants/color_constants.dart';
import 'package:yanji/modules/settings/settings_constants.dart';

/// 4位数字密码输入组件
///
/// 提供数字键盘布局，支持输入、删除、错误提示。
/// 用于密码设置（两次确认）和密码验证场景。
class PasswordInput extends StatefulWidget {
  /// 标题（如"设置密码"、"确认密码"、"输入密码"）
  final String title;

  /// 副标题说明
  final String? subtitle;

  /// 完成回调，返回输入的4位密码
  final ValueChanged<String> onCompleted;

  /// 错误提示文案（外部控制，用于两次输入不一致等场景）
  final String? errorText;

  /// 是否显示返回按钮
  final bool showBackButton;

  /// 返回按钮回调
  final VoidCallback? onBack;

  /// 底部附加组件（如紧急查看急救卡按钮）
  final Widget? footer;

  /// 构造函数
  const PasswordInput({
    super.key,
    required this.title,
    this.subtitle,
    required this.onCompleted,
    this.errorText,
    this.showBackButton = false,
    this.onBack,
    this.footer,
  });

  @override
  State<PasswordInput> createState() => _PasswordInputState();
}

class _PasswordInputState extends State<PasswordInput>
    with SingleTickerProviderStateMixin {
  String _input = '';
  bool _hasError = false;
  late AnimationController _shakeController;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant PasswordInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    // 外部错误变化时触发抖动动画并清空输入
    if (widget.errorText != null && widget.errorText != oldWidget.errorText) {
      _triggerError();
    }
  }

  /// 触发错误状态：抖动 + 清空
  void _triggerError() {
    setState(() {
      _hasError = true;
      _input = '';
    });
    _shakeController.forward(from: 0);
  }

  /// 输入数字
  void _onDigit(String digit) {
    if (_input.length >= SettingsConstants.passwordLength) return;
    setState(() {
      _input += digit;
      _hasError = false;
    });
    if (_input.length == SettingsConstants.passwordLength) {
      // 完成输入，延迟回调让用户看到最后一个圆点
      Future.delayed(const Duration(milliseconds: 150), () {
        widget.onCompleted(_input);
      });
    }
  }

  /// 删除一位
  void _onDelete() {
    if (_input.isEmpty) return;
    setState(() {
      _input = _input.substring(0, _input.length - 1);
      _hasError = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sw = MediaQuery.of(context).size.width;
    final padding = sw * 0.045;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            // 顶部：返回按钮（可选）
            if (widget.showBackButton)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.all(padding * 0.6),
                  child: IconButton(
                    onPressed: widget.onBack,
                    icon: Icon(Icons.arrow_back_rounded,
                        color: theme.colorScheme.onSurface),
                  ),
                ),
              ),
            // 标题区
            Padding(
              padding: EdgeInsets.only(top: padding * 1.5, bottom: padding),
              child: Column(
                children: [
                  Icon(Icons.lock_outline,
                      size: padding * 1.5,
                      color: _hasError
                          ? AppColors.error
                          : theme.colorScheme.primary),
                  SizedBox(height: padding * 0.6),
                  Text(widget.title,
                      style: theme.textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  if (widget.subtitle != null) ...[
                    SizedBox(height: padding * 0.3),
                    Text(widget.subtitle!,
                        style: TextStyle(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant),
                        textAlign: TextAlign.center),
                  ],
                ],
              ),
            ),
            // 密码圆点显示（带抖动动画）
            Expanded(
              flex: 2,
              child: Center(
                child: AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, child) {
                    // 抖动偏移：sin 波形，随动画进度衰减
                    final sine = _shakeController.isAnimating
                        ? 10 *
                            (1 - _shakeController.value) *
                            ((_shakeController.value * 3.14 * 4).sin())
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(sine.toDouble(), 0),
                      child: child,
                    );
                  },
                  child: _buildDots(theme, padding),
                ),
              ),
            ),
            // 错误提示
            SizedBox(
              height: padding * 0.8,
              child: _hasError || widget.errorText != null
                  ? Text(
                      widget.errorText ?? '密码错误，请重试',
                      style: TextStyle(
                          color: AppColors.error, fontSize: 14),
                    )
                  : const SizedBox.shrink(),
            ),
            // 数字键盘
            Expanded(
              flex: 3,
              child: _buildKeypad(theme, padding),
            ),
            // 底部附加组件（如紧急查看急救卡按钮）
            if (widget.footer != null) widget.footer!,
            SizedBox(height: padding * 0.5),
          ],
        ),
      ),
    );
  }

  /// 密码圆点显示
  Widget _buildDots(ThemeData theme, double padding) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(SettingsConstants.passwordLength, (index) {
        final filled = index < _input.length;
        return Container(
          margin: EdgeInsets.symmetric(horizontal: padding * 0.3),
          width: padding * 0.7,
          height: padding * 0.7,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled
                ? (_hasError ? AppColors.error : theme.colorScheme.primary)
                : Colors.transparent,
            border: Border.all(
              color: _hasError
                  ? AppColors.error
                  : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              width: 2,
            ),
          ),
        );
      }),
    );
  }

  /// 数字键盘
  Widget _buildKeypad(ThemeData theme, double padding) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'del'];
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding),
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: keys.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 1.6,
          crossAxisSpacing: padding * 0.4,
          mainAxisSpacing: padding * 0.3,
        ),
        itemBuilder: (context, index) {
          final key = keys[index];
          if (key.isEmpty) return const SizedBox.shrink();
          if (key == 'del') {
            return _buildKeyButton(
              theme,
              padding,
              icon: Icons.backspace_outlined,
              onTap: _onDelete,
            );
          }
          return _buildKeyButton(
            theme,
            padding,
            text: key,
            onTap: () => _onDigit(key),
          );
        },
      ),
    );
  }

  /// 单个键盘按钮
  Widget _buildKeyButton(
    ThemeData theme,
    double padding, {
    String? text,
    IconData? icon,
    required VoidCallback onTap,
  }) {
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      borderRadius: BorderRadius.circular(padding * 0.8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(padding * 0.8),
        child: Center(
          child: icon != null
              ? Icon(icon,
                  color: theme.colorScheme.onSurface, size: padding * 0.8)
              : Text(text!,
                  style: TextStyle(
                      fontSize: padding * 0.9,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface)),
        ),
      ),
    );
  }
}

/// sin 扩展（用于抖动动画）
extension on num {
  double sin() => _mathSin(this);
}

/// 简单 sin 实现（避免引入 dart:math）
double _mathSin(num x) {
  // 使用泰勒级数近似，范围足够覆盖抖动用例
  double xRad = x.toDouble();
  // 归一化到 [-pi, pi]
  while (xRad > 3.14159265) {
    xRad -= 6.28318530;
  }
  while (xRad < -3.14159265) {
    xRad += 6.28318530;
  }
  double term = xRad;
  double sum = xRad;
  for (int i = 1; i < 6; i++) {
    term *= -xRad * xRad / ((2 * i) * (2 * i + 1));
    sum += term;
  }
  return sum;
}

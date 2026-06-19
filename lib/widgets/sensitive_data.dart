import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:yanji/core/providers/theme_provider.dart';
import 'package:yanji/data/repositories/app_config_repository.dart';

/// 敏感数据模糊显示组件
///
/// 根据 AppConfig.sensitiveDataBlurEnabled 决定是否模糊：
/// - 关闭：直接显示明文子组件
/// - 开启：默认模糊（高斯模糊+半透明遮罩），按下时临时显示明文，松开恢复模糊
///
/// 用法：
/// ```dart
/// SensitiveData(child: Text('120/80 mmHg'))
/// ```
class SensitiveData extends StatefulWidget {
  /// 需要保护的明文内容
  final Widget child;

  /// 构造函数
  const SensitiveData({super.key, required this.child});

  @override
  State<SensitiveData> createState() => _SensitiveDataState();
}

class _SensitiveDataState extends State<SensitiveData> {
  /// 是否启用模糊（从配置读取）
  bool _blurEnabled = false;

  /// 是否正在按下（临时显示明文）
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _loadBlurConfig();
  }

  /// 加载模糊配置
  Future<void> _loadBlurConfig() async {
    final config = await AppConfigRepository().getConfig();
    if (mounted) {
      setState(() => _blurEnabled = config.sensitiveDataBlurEnabled);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 长辈模式下模糊区域更大，便于操作
    final isElder = context.watch<ThemeProvider>().elderMode;

    if (!_blurEnabled) {
      return widget.child;
    }

    // 模糊生效，但按下时显示明文
    final showPlain = _isPressed;

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      behavior: HitTestBehavior.opaque,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: showPlain
            ? widget.child
            : _buildBlurred(isElder),
      ),
    );
  }

  /// 构建模糊层
  Widget _buildBlurred(bool isElder) {
    final theme = Theme.of(context);
    return ClipRect(
      child: Stack(
        children: [
          // 模糊层：用 ImageFilter 做高斯模糊
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: isElder ? 6 : 5,
                sigmaY: isElder ? 6 : 5,
              ),
              child: Container(
                color: theme.colorScheme.surface.withValues(alpha: 0.6),
                alignment: Alignment.center,
                child: Icon(Icons.visibility_off_outlined,
                    size: isElder ? 22 : 18,
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.5)),
              ),
            ),
          ),
          // 占位：保持子组件尺寸
          Opacity(opacity: 0, child: widget.child),
        ],
      ),
    );
  }
}

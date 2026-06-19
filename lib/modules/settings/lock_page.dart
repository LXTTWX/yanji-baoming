import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:yanji/core/constants/color_constants.dart';
import 'package:yanji/data/repositories/app_config_repository.dart';
import 'package:yanji/modules/settings/settings_constants.dart';
import 'package:yanji/widgets/password_input.dart';

// ============================================================
// 密码哈希工具函数（纯函数，无副作用）
// ============================================================

/// 生成16字节随机盐，Base64编码
String _generateSalt() {
  final random = Random.secure();
  final bytes = List<int>.generate(16, (_) => random.nextInt(256));
  return base64Encode(bytes);
}

/// 使用SHA-256对密码+盐进行哈希
///
/// [password] 明文密码
/// [salt] Base64编码的盐值
/// 返回64位十六进制哈希字符串
String _hashPassword(String password, String salt) {
  final bytes = utf8.encode('$password$salt');
  return sha256.convert(bytes).toString();
}

/// 验证密码是否匹配
///
/// [input] 用户输入的明文密码
/// [hash] 存储的哈希值
/// [salt] 存储的盐值
bool _verifyPassword(String input, String hash, String salt) {
  return _hashPassword(input, salt) == hash;
}

/// 校验密码格式：必须为4位纯数字
bool _isValidPassword(String password) {
  return RegExp(r'^\d{4}$').hasMatch(password);
}

// ============================================================
// 启动锁页面
// ============================================================

/// 启动锁页面
///
/// 三种模式：
/// - verify：启动验证（输入正确密码进入应用）
/// - setup：首次设置密码（输入两次确认）
/// - change：修改密码（先验证旧密码，再设置新密码）
class LockPage extends StatefulWidget {
  /// 锁定模式
  final LockMode mode;

  /// 验证成功回调
  final VoidCallback? onUnlocked;

  /// 设置成功回调（密码已保存）
  final VoidCallback? onPasswordSet;

  /// 取消回调（仅设置/修改模式有效）
  final VoidCallback? onCancel;

  /// 构造函数
  const LockPage({
    super.key,
    required this.mode,
    this.onUnlocked,
    this.onPasswordSet,
    this.onCancel,
  });

  @override
  State<LockPage> createState() => _LockPageState();
}

/// 锁定模式
enum LockMode {
  /// 启动验证
  verify,
  /// 首次设置
  setup,
  /// 修改密码
  change,
}

class _LockPageState extends State<LockPage> {
  final AppConfigRepository _configRepo = AppConfigRepository();

  /// 当前流程阶段
  _LockStage _stage = _LockStage.input;
  /// 第一次输入的密码（设置/修改模式用）
  String _firstPassword = '';
  /// 错误提示
  String? _errorText;
  /// 是否处于锁定状态（含倒计时）
  bool _isLocked = false;
  /// 锁定剩余秒数
  int _lockoutRemaining = 0;
  /// 锁定倒计时定时器
  Timer? _lockoutTimer;
  /// 是否需要从旧密码系统迁移
  bool _needsMigration = false;
  /// 旧密码验证函数（迁移期间使用）
  String? _oldHashedPassword;

  @override
  void initState() {
    super.initState();
    _initLockoutState();
    if (widget.mode == LockMode.change) {
      _stage = _LockStage.verifyOld;
    }
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    super.dispose();
  }

  /// 初始化锁定状态：从持久化存储读取，若仍在锁定期则启动倒计时
  Future<void> _initLockoutState() async {
    final config = await _configRepo.getConfig();
    // 检查是否需要迁移
    if (_configRepo.needsMigration(config)) {
      _needsMigration = true;
      _oldHashedPassword = config.appLockPassword;
    }
    // 检查是否处于锁定状态
    final lockedUntil = config.lockedUntil;
    if (lockedUntil != null && lockedUntil.isNotEmpty) {
      final until = DateTime.tryParse(lockedUntil);
      if (until != null && until.isAfter(DateTime.now())) {
        // 仍在锁定期，启动倒计时
        final remaining = until.difference(DateTime.now()).inSeconds;
        if (mounted) {
          setState(() {
            _isLocked = true;
            _lockoutRemaining = remaining;
          });
          _startLockoutCountdown();
        }
        return;
      }
    }
    // 不在锁定期，但如果之前有失败次数，加载到本地变量（用于本次会话的防暴力破解）
    if (config.failedAttempts >= SettingsConstants.maxPasswordAttempts) {
      // 已达上限但锁定已过期，重置计数
      await _configRepo.resetFailedAttempts();
    }
  }

  /// 启动锁定倒计时（每秒更新）
  void _startLockoutCountdown() {
    _lockoutTimer?.cancel();
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _lockoutRemaining -= 1;
        if (_lockoutRemaining <= 0) {
          _isLocked = false;
          _lockoutRemaining = 0;
          _errorText = null;
          timer.cancel();
          // 持久化重置锁定状态
          _configRepo.resetFailedAttempts();
        }
      });
    });
  }

  /// 触发锁定：记录失败次数，达到上限则锁定60秒
  Future<void> _triggerLockout() async {
    final config = await _configRepo.getConfig();
    final newCount = config.failedAttempts + 1;
    if (newCount >= SettingsConstants.maxPasswordAttempts) {
      // 达到上限，锁定60秒
      final until = DateTime.now().add(
        Duration(seconds: SettingsConstants.lockoutDurationSeconds),
      );
      await _configRepo.updateLockoutState(
        until.toIso8601String(),
        newCount,
      );
      if (mounted) {
        setState(() {
          _isLocked = true;
          _lockoutRemaining = SettingsConstants.lockoutDurationSeconds;
          _errorText = '错误次数过多，请 ${SettingsConstants.lockoutDurationSeconds} 秒后再试';
        });
        _startLockoutCountdown();
      }
    } else {
      // 未达上限，仅更新计数
      await _configRepo.updateLockoutState(null, newCount);
      if (mounted) {
        setState(() {
          _errorText = '密码错误，请重试（剩余 ${SettingsConstants.maxPasswordAttempts - newCount} 次）';
        });
      }
    }
  }

  /// 密码输入完成处理
  Future<void> _onPasswordCompleted(String password) async {
    switch (widget.mode) {
      case LockMode.verify:
        await _handleVerify(password);
        break;
      case LockMode.setup:
        await _handleSetup(password);
        break;
      case LockMode.change:
        await _handleChange(password);
        break;
    }
  }

  /// 处理启动验证
  Future<void> _handleVerify(String password) async {
    final config = await _configRepo.getConfig();

    // 旧密码系统验证（迁移期间）
    if (_needsMigration && _oldHashedPassword != null) {
      // 使用旧的静态盐验证
      final oldHash = _hashPassword(password, 'yanji_2024_security_salt_v1');
      if (oldHash == _oldHashedPassword) {
        // 验证成功，完成迁移：生成新盐+新哈希
        final newSalt = _generateSalt();
        final newHash = _hashPassword(password, newSalt);
        await _configRepo.completeMigration(newHash, newSalt);
        await _configRepo.resetFailedAttempts();
        widget.onUnlocked?.call();
        return;
      }
      await _triggerLockout();
      return;
    }

    // 新密码系统验证
    final storedHash = config.hashedPassword;
    final storedSalt = config.salt;
    if (storedHash == null || storedHash.isEmpty ||
        storedSalt == null || storedSalt.isEmpty) {
      if (mounted) {
        setState(() {
          _errorText = '密码未设置，请先设置密码';
        });
      }
      return;
    }

    if (_verifyPassword(password, storedHash, storedSalt)) {
      // 验证成功，重置失败计数
      await _configRepo.resetFailedAttempts();
      widget.onUnlocked?.call();
    } else {
      await _triggerLockout();
    }
  }

  /// 处理首次设置
  Future<void> _handleSetup(String password) async {
    // 校验密码格式：4位纯数字
    if (!_isValidPassword(password)) {
      if (mounted) {
        setState(() {
          _errorText = '密码必须为4位纯数字';
        });
      }
      return;
    }

    if (_stage == _LockStage.input) {
      // 第一次输入，进入确认阶段
      setState(() {
        _firstPassword = password;
        _stage = _LockStage.confirm;
        _errorText = null;
      });
    } else if (_stage == _LockStage.confirm) {
      // 第二次输入，校验一致性
      if (password == _firstPassword) {
        // 生成随机盐+哈希，持久化存储
        final salt = _generateSalt();
        final hash = _hashPassword(password, salt);
        await _configRepo.updateHashedPassword(hash, salt);
        await _configRepo.updateAppLockEnabled(true);
        await _configRepo.resetFailedAttempts();
        widget.onPasswordSet?.call();
      } else {
        setState(() {
          _errorText = '两次输入不一致，请重新设置';
          _stage = _LockStage.input;
          _firstPassword = '';
        });
      }
    }
  }

  /// 处理修改密码
  Future<void> _handleChange(String password) async {
    if (_stage == _LockStage.verifyOld) {
      // 验证旧密码
      final config = await _configRepo.getConfig();
      final storedHash = config.hashedPassword;
      final storedSalt = config.salt;

      // 优先使用新系统，回退到旧系统
      bool ok = false;
      if (storedHash != null && storedHash.isNotEmpty &&
          storedSalt != null && storedSalt.isNotEmpty) {
        ok = _verifyPassword(password, storedHash, storedSalt);
      } else if (_needsMigration && _oldHashedPassword != null) {
        final oldHash = _hashPassword(password, 'yanji_2024_security_salt_v1');
        ok = oldHash == _oldHashedPassword;
      }

      if (ok) {
        setState(() {
          _stage = _LockStage.input;
          _errorText = null;
        });
      } else {
        setState(() {
          _errorText = '原密码错误';
        });
      }
    } else if (_stage == _LockStage.input) {
      // 校验新密码格式
      if (!_isValidPassword(password)) {
        if (mounted) {
          setState(() {
            _errorText = '密码必须为4位纯数字';
          });
        }
        return;
      }
      setState(() {
        _firstPassword = password;
        _stage = _LockStage.confirm;
        _errorText = null;
      });
    } else if (_stage == _LockStage.confirm) {
      if (password == _firstPassword) {
        // 生成新盐+新哈希，覆盖旧密码
        final salt = _generateSalt();
        final hash = _hashPassword(password, salt);
        await _configRepo.updateHashedPassword(hash, salt);
        widget.onPasswordSet?.call();
      } else {
        setState(() {
          _errorText = '两次输入不一致，请重新设置';
          _stage = _LockStage.input;
          _firstPassword = '';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // 标题与副标题
    String title;
    String? subtitle;
    bool showBack = false;
    switch (widget.mode) {
      case LockMode.verify:
        title = '输入密码';
        subtitle = '请输入应用锁密码';
        break;
      case LockMode.setup:
        if (_stage == _LockStage.input) {
          title = '设置密码';
          subtitle = '请输入4位数字密码';
        } else {
          title = '确认密码';
          subtitle = '请再次输入相同密码';
        }
        showBack = true;
        break;
      case LockMode.change:
        if (_stage == _LockStage.verifyOld) {
          title = '验证原密码';
          subtitle = '请输入当前应用锁密码';
        } else if (_stage == _LockStage.input) {
          title = '设置新密码';
          subtitle = '请输入新的4位数字密码';
        } else {
          title = '确认新密码';
          subtitle = '请再次输入相同密码';
        }
        showBack = true;
        break;
    }

    // 被锁定时显示锁定界面（含倒计时）
    if (_isLocked) {
      return Scaffold(
        backgroundColor: theme.colorScheme.surface,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_clock, size: 80, color: AppColors.error),
              const SizedBox(height: 24),
              Text(
                '已临时锁定',
                style: theme.textTheme.headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                '请 $_lockoutRemaining 秒后再试',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorText ?? '连续错误次数过多，已临时锁定',
                style: TextStyle(color: AppColors.error),
              ),
            ],
          ),
        ),
      );
    }

    return PasswordInput(
      title: title,
      subtitle: subtitle,
      errorText: _errorText,
      showBackButton: showBack,
      onBack: widget.onCancel,
      onCompleted: _isLocked ? (_) {} : _onPasswordCompleted,
      // 启动验证模式下显示"紧急查看急救卡"按钮（不解锁即可查看）
      footer: widget.mode == LockMode.verify
          ? Padding(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: TextButton.icon(
                onPressed: () => context.push('/emergency/lock'),
                icon: Icon(Icons.emergency, color: AppColors.error, size: 20),
                label: Text(
                  '紧急查看急救卡',
                  style: TextStyle(
                      color: AppColors.error, fontWeight: FontWeight.w600),
                ),
              ),
            )
          : null,
    );
  }
}

/// 锁定流程阶段
enum _LockStage {
  /// 验证旧密码（修改模式）
  verifyOld,
  /// 第一次输入
  input,
  /// 确认输入
  confirm,
}
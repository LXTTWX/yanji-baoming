import 'package:hive/hive.dart';
import 'package:yanji/core/constants/app_constants.dart';
import 'package:yanji/data/models/app_config.dart';

/// 应用配置仓库
class AppConfigRepository {
  Box<AppConfig>? _box;

  /// 获取Hive盒子
  Future<Box<AppConfig>> _getBox() async {
    _box ??= await Hive.openBox<AppConfig>(AppConstants.boxAppConfig);
    return _box!;
  }

  /// 获取应用配置（含旧密码→新哈希懒迁移检测）
  Future<AppConfig> getConfig() async {
    final box = await _getBox();
    final config = box.get('app_config');
    if (config == null) {
      final defaultConfig = AppConfig.defaultConfig();
      await box.put('app_config', defaultConfig);
      return defaultConfig;
    }
    return config;
  }

  /// 检查是否需要从旧密码系统迁移（appLockPassword非空但hashedPassword为空）
  bool needsMigration(AppConfig config) {
    return config.appLockPassword != null &&
        config.appLockPassword!.isNotEmpty &&
        (config.hashedPassword == null || config.hashedPassword!.isEmpty);
  }

  /// 完成密码迁移：将新哈希+盐存入，清空旧密码字段
  Future<void> completeMigration(String hashedPassword, String salt) async {
    final config = await getConfig();
    config.hashedPassword = hashedPassword;
    config.salt = salt;
    config.appLockPassword = null; // 清空旧密码，完成迁移
    await saveConfig(config);
  }

  /// 保存应用配置
  Future<void> saveConfig(AppConfig config) async {
    final box = await _getBox();
    await box.put('app_config', config);
  }

  /// 更新主题类型
  Future<void> updateThemeType(int themeType) async {
    final config = await getConfig();
    config.themeType = themeType;
    await saveConfig(config);
  }

  /// 更新长辈模式
  Future<void> updateElderMode(bool enabled) async {
    final config = await getConfig();
    config.elderMode = enabled;
    config.fontScale = enabled ? 1.2 : 1.0;
    await saveConfig(config);
  }

  /// 更新自动主题
  Future<void> updateAutoTheme(bool autoTheme) async {
    final config = await getConfig();
    config.autoTheme = autoTheme;
    await saveConfig(config);
  }

  /// 更新亮度模式（0-亮色，1-暗色）
  Future<void> updateBrightnessMode(int mode) async {
    final config = await getConfig();
    config.brightnessMode = mode;
    await saveConfig(config);
  }

  /// 更新首页默认启动页（0-首页，1-健身，2-守护）
  Future<void> updateDefaultHomePage(int page) async {
    final config = await getConfig();
    config.defaultHomePage = page;
    await saveConfig(config);
  }

  /// 更新时间格式（0-24小时制，1-12小时制）
  Future<void> updateTimeFormat(int format) async {
    final config = await getConfig();
    config.timeFormat = format;
    await saveConfig(config);
  }

  /// 更新高血压收缩压阈值
  Future<void> updateHypertensionThreshold(int value) async {
    final config = await getConfig();
    config.hypertensionThreshold = value;
    await saveConfig(config);
  }

  /// 更新低血压收缩压阈值
  Future<void> updateHypotensionThreshold(int value) async {
    final config = await getConfig();
    config.hypotensionThreshold = value;
    await saveConfig(config);
  }

  /// 更新心率下限
  Future<void> updateHeartRateMin(int value) async {
    final config = await getConfig();
    config.heartRateMin = value;
    await saveConfig(config);
  }

  /// 更新心率上限
  Future<void> updateHeartRateMax(int value) async {
    final config = await getConfig();
    config.heartRateMax = value;
    await saveConfig(config);
  }

  /// 更新异常提醒敏感度（0-宽松，1-标准，2-严格）
  Future<void> updateAbnormalSensitivity(int value) async {
    final config = await getConfig();
    config.abnormalSensitivity = value;
    await saveConfig(config);
  }

  /// 更新是否显示医学解释
  Future<void> updateShowMedicalExplanation(bool value) async {
    final config = await getConfig();
    config.showMedicalExplanation = value;
    await saveConfig(config);
  }

  /// 更新提醒震动
  Future<void> updateReminderVibrate(bool value) async {
    final config = await getConfig();
    config.reminderVibrate = value;
    await saveConfig(config);
  }

  /// 更新提前提醒分钟数
  Future<void> updateReminderAdvanceMinutes(int value) async {
    final config = await getConfig();
    config.reminderAdvanceMinutes = value;
    await saveConfig(config);
  }

  /// 更新默认提醒时间
  Future<void> updateDefaultReminderTime(String value) async {
    final config = await getConfig();
    config.defaultReminderTime = value;
    await saveConfig(config);
  }

  /// 更新应用启动锁启用状态
  Future<void> updateAppLockEnabled(bool value) async {
    final config = await getConfig();
    config.appLockEnabled = value;
    await saveConfig(config);
  }

  /// 更新应用启动锁密码（新系统：hashedPassword + salt）
  Future<void> updateHashedPassword(String hashedPassword, String salt) async {
    final config = await getConfig();
    config.hashedPassword = hashedPassword;
    config.salt = salt;
    config.appLockPassword = null; // 确保旧字段为空
    await saveConfig(config);
  }

  /// 关闭应用锁：禁用并清空所有密码相关字段
  Future<void> disableAppLock() async {
    final config = await getConfig();
    config.appLockEnabled = false;
    config.appLockPassword = null;
    config.hashedPassword = null;
    config.salt = null;
    config.lockedUntil = null;
    config.failedAttempts = 0;
    await saveConfig(config);
  }

  /// 更新锁定状态（持久化防暴力破解）
  Future<void> updateLockoutState(String? lockedUntil, int failedAttempts) async {
    final config = await getConfig();
    config.lockedUntil = lockedUntil;
    config.failedAttempts = failedAttempts;
    await saveConfig(config);
  }

  /// 重置失败尝试计数（验证成功后调用）
  Future<void> resetFailedAttempts() async {
    final config = await getConfig();
    config.failedAttempts = 0;
    config.lockedUntil = null;
    await saveConfig(config);
  }

  /// 更新敏感数据模糊显示
  Future<void> updateSensitiveDataBlurEnabled(bool value) async {
    final config = await getConfig();
    config.sensitiveDataBlurEnabled = value;
    await saveConfig(config);
  }

  /// 更新自动锁定时间（秒，0表示从不）
  Future<void> updateAutoLockTime(int seconds) async {
    final config = await getConfig();
    config.autoLockTime = seconds;
    await saveConfig(config);
  }

  /// 更新自定义背景色（null表示使用默认）
  Future<void> updateCustomBackgroundColor(int? colorValue) async {
    final config = await getConfig();
    config.customBackgroundColor = colorValue;
    await saveConfig(config);
  }

  /// 更新自定义卡片色（null表示使用默认）
  Future<void> updateCustomCardColor(int? colorValue) async {
    final config = await getConfig();
    config.customCardColor = colorValue;
    await saveConfig(config);
  }

  /// 更新背景颜色方案（JSON 字符串，null表示使用默认）
  Future<void> updateBackgroundScheme(String? json) async {
    final config = await getConfig();
    config.backgroundScheme = json;
    await saveConfig(config);
  }

  /// 更新卡片颜色方案（JSON 字符串，null表示使用默认）
  Future<void> updateCardScheme(String? json) async {
    final config = await getConfig();
    config.cardScheme = json;
    await saveConfig(config);
  }

  /// 更新高对比度模式
  Future<void> updateHighContrastMode(bool value) async {
    final config = await getConfig();
    config.highContrastMode = value;
    await saveConfig(config);
  }

  /// 更新色盲辅助模式（0-关闭，1-红色盲，2-绿色盲，3-蓝黄色盲）
  Future<void> updateColorBlindMode(int value) async {
    final config = await getConfig();
    config.colorBlindMode = value;
    await saveConfig(config);
  }

  /// 更新减少动画
  Future<void> updateReduceMotion(bool value) async {
    final config = await getConfig();
    config.reduceMotion = value;
    await saveConfig(config);
  }

  /// 更新简化布局
  Future<void> updateSimplifiedLayout(bool value) async {
    final config = await getConfig();
    config.simplifiedLayout = value;
    await saveConfig(config);
  }

  /// 更新可点击区域放大
  Future<void> updateEnlargedTouchTarget(bool value) async {
    final config = await getConfig();
    config.enlargedTouchTarget = value;
    await saveConfig(config);
  }

  /// 更新跟随系统无障碍设置
  Future<void> updateFollowSystemAccessibility(bool value) async {
    final config = await getConfig();
    config.followSystemAccessibility = value;
    await saveConfig(config);
  }

  /// 更新用户自定义字体缩放（0.8~1.8）
  Future<void> updateUserFontScale(double value) async {
    final config = await getConfig();
    config.userFontScale = value;
    await saveConfig(config);
  }

  /// 更新屏幕朗读详细描述
  Future<void> updateSemanticLabelsEnabled(bool value) async {
    final config = await getConfig();
    config.semanticLabelsEnabled = value;
    await saveConfig(config);
  }

  /// 标记已启动
  Future<void> markLaunched() async {
    final config = await getConfig();
    config.isFirstLaunch = false;
    await saveConfig(config);
  }
}

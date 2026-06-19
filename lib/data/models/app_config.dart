import 'package:hive/hive.dart';

/// 应用配置模型
@HiveType(typeId: 5)
class AppConfig extends HiveObject {
  /// 当前主题类型（0-简约，1-玻璃拟态，2-羊皮纸）
  @HiveField(0)
  int themeType;

  /// 是否跟随页面自动切换主题
  @HiveField(1)
  bool autoTheme;

  /// 字体大小倍率
  @HiveField(2)
  double fontScale;

  /// 是否开启长辈模式
  @HiveField(3)
  bool elderMode;

  /// 语言设置
  @HiveField(4)
  String language;

  /// 是否首次启动
  @HiveField(5)
  bool isFirstLaunch;

  /// 上次同步时间
  @HiveField(6)
  String? lastSyncAt;

  /// 亮度模式（0-亮色，1-暗色）
  @HiveField(7)
  int brightnessMode;

  /// 首页默认启动页（0-首页，1-健身，2-守护）
  @HiveField(8)
  int defaultHomePage;

  /// 时间格式（0-24小时制，1-12小时制）
  @HiveField(9)
  int timeFormat;

  /// 高血压收缩压阈值（mmHg）
  @HiveField(10)
  int hypertensionThreshold;

  /// 低血压收缩压阈值（mmHg）
  @HiveField(11)
  int hypotensionThreshold;

  /// 心率下限（次/分）
  @HiveField(12)
  int heartRateMin;

  /// 心率上限（次/分）
  @HiveField(13)
  int heartRateMax;

  /// 异常提醒敏感度（0-宽松，1-标准，2-严格）
  @HiveField(14)
  int abnormalSensitivity;

  /// 是否显示医学解释
  @HiveField(15)
  bool showMedicalExplanation;

  /// 提醒是否震动
  @HiveField(16)
  bool reminderVibrate;

  /// 提前提醒分钟数（0/5/10/15）
  @HiveField(17)
  int reminderAdvanceMinutes;

  /// 默认提醒时间（HH:mm）
  @HiveField(18)
  String defaultReminderTime;

  /// 应用启动锁是否启用
  @HiveField(19)
  bool appLockEnabled;

  /// 应用启动锁密码（已废弃，迁移至hashedPassword+salt）
  @Deprecated('使用hashedPassword+salt替代')
  @HiveField(20)
  String? appLockPassword;

  /// 敏感数据模糊显示是否启用
  @HiveField(21)
  bool sensitiveDataBlurEnabled;

  /// 自动锁定时间（秒，0表示从不）
  @HiveField(22)
  int autoLockTime;

  /// SHA-256哈希后的密码（64位十六进制字符串）
  @HiveField(23)
  String? hashedPassword;

  /// Base64编码的16字节随机盐值
  @HiveField(24)
  String? salt;

  /// 锁定截止时间（ISO8601字符串，null表示未锁定）
  @HiveField(25)
  String? lockedUntil;

  /// 连续失败尝试次数（持久化，防暴力破解）
  @HiveField(26)
  int failedAttempts;

  /// 自定义背景色（ARGB整数值，null表示使用默认）
  @HiveField(27)
  int? customBackgroundColor;

  /// 自定义卡片色（ARGB整数值，null表示使用默认）
  @HiveField(28)
  int? customCardColor;

  /// 高对比度模式（提升前景/背景对比度，禁用半透明装饰）
  @HiveField(29)
  bool highContrastMode;

  /// 色盲辅助模式（0-关闭，1-红色盲，2-绿色盲，3-蓝黄色盲）
  @HiveField(30)
  int colorBlindMode;

  /// 减少动画（禁用页面切换与装饰动效）
  @HiveField(31)
  bool reduceMotion;

  /// 简化布局（隐藏非核心装饰，仅保留标题/内容/主操作）
  @HiveField(32)
  bool simplifiedLayout;

  /// 可点击区域放大（所有交互元素触控区≥44dp，长辈模式≥56dp）
  @HiveField(33)
  bool enlargedTouchTarget;

  /// 跟随系统无障碍设置（字体缩放、高对比度、减少动画）
  @HiveField(34)
  bool followSystemAccessibility;

  /// 用户自定义字体缩放（0.8~1.8，与长辈模式叠加）
  @HiveField(35)
  double userFontScale;

  /// 屏幕朗读详细描述（为图标/图片补充语义标签）
  @HiveField(36)
  bool semanticLabelsEnabled;

  /// 自定义背景颜色方案（JSON 字符串，存储纯色/渐变配置）
  ///
  /// 为 null 时回退到 [customBackgroundColor]（向后兼容）。
  @HiveField(37)
  String? backgroundScheme;

  /// 自定义卡片颜色方案（JSON 字符串，存储纯色/渐变配置）
  ///
  /// 为 null 时回退到 [customCardColor]（向后兼容）。
  @HiveField(38)
  String? cardScheme;

  /// 构造函数
  AppConfig({
    this.themeType = 0,
    this.autoTheme = true,
    this.fontScale = 1.0,
    this.elderMode = false,
    this.language = 'zh_CN',
    this.isFirstLaunch = true,
    this.lastSyncAt,
    this.brightnessMode = 0,
    this.defaultHomePage = 0,
    this.timeFormat = 0,
    this.hypertensionThreshold = 140,
    this.hypotensionThreshold = 90,
    this.heartRateMin = 60,
    this.heartRateMax = 100,
    this.abnormalSensitivity = 1,
    this.showMedicalExplanation = true,
    this.reminderVibrate = true,
    this.reminderAdvanceMinutes = 0,
    this.defaultReminderTime = '08:00',
    this.appLockEnabled = false,
    this.appLockPassword,
    this.sensitiveDataBlurEnabled = false,
    this.autoLockTime = 0,
    this.hashedPassword,
    this.salt,
    this.lockedUntil,
    this.failedAttempts = 0,
    this.customBackgroundColor,
    this.customCardColor,
    this.highContrastMode = false,
    this.colorBlindMode = 0,
    this.reduceMotion = false,
    this.simplifiedLayout = false,
    this.enlargedTouchTarget = false,
    this.followSystemAccessibility = false,
    this.userFontScale = 1.0,
    this.semanticLabelsEnabled = true,
    this.backgroundScheme,
    this.cardScheme,
  });

  /// 创建默认配置
  factory AppConfig.defaultConfig() {
    return AppConfig(
      themeType: 0,
      autoTheme: true,
      fontScale: 1.0,
      elderMode: false,
      language: 'zh_CN',
      isFirstLaunch: true,
      brightnessMode: 0,
      defaultHomePage: 0,
      timeFormat: 0,
      hypertensionThreshold: 140,
      hypotensionThreshold: 90,
      heartRateMin: 60,
      heartRateMax: 100,
      abnormalSensitivity: 1,
      showMedicalExplanation: true,
      reminderVibrate: true,
      reminderAdvanceMinutes: 0,
      defaultReminderTime: '08:00',
      appLockEnabled: false,
      appLockPassword: null,
      sensitiveDataBlurEnabled: false,
      autoLockTime: 0,
      hashedPassword: null,
      salt: null,
      lockedUntil: null,
      failedAttempts: 0,
      customBackgroundColor: null,
      customCardColor: null,
      highContrastMode: false,
      colorBlindMode: 0,
      reduceMotion: false,
      simplifiedLayout: false,
      enlargedTouchTarget: false,
      followSystemAccessibility: false,
      userFontScale: 1.0,
      semanticLabelsEnabled: true,
      backgroundScheme: null,
      cardScheme: null,
    );
  }
}

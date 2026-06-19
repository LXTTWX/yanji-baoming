/// 设置模块常量配置
class SettingsConstants {
  /// 首页默认启动页选项
  static const List<String> homePageOptions = ['首页', '健身', '守护'];

  /// 时间格式选项
  static const List<String> timeFormatOptions = ['24小时制', '12小时制'];

  /// 异常提醒敏感度选项
  static const List<String> sensitivityOptions = ['宽松', '标准', '严格'];

  /// 提前提醒选项
  static const List<String> advanceOptions = ['不提前', '5分钟', '10分钟', '15分钟'];

  /// 提前提醒对应分钟数
  static const List<int> advanceMinutes = [0, 5, 10, 15];

  /// 数据导出文件前缀
  static const String exportFilePrefix = 'yanji_backup';

  /// 密码提示文案
  static const String passwordHint = '用于加密导出数据，请牢记此密码';

  /// 清空数据确认文案
  static const String clearDataConfirm = '清空后所有数据将无法恢复，确定要继续吗？';

  /// 关于页面文案
  static const String appDescription = '纯本地、零后端家庭健康助手';

  /// 隐私说明
  static const String privacyStatement = '所有数据100%存储在本地设备，绝不上传到任何服务器';

  /// 开源协议
  static const String license = 'MIT License';

  /// 敏感度说明
  static const List<String> sensitivityDescriptions = [
    '仅标记严重异常值',
    '按医学标准判定',
    '临界值也标记提醒',
  ];

  /// 自动锁定时间选项
  static const List<String> autoLockOptions = ['从不', '1分钟', '3分钟', '5分钟'];

  /// 自动锁定时间对应秒数
  static const List<int> autoLockSeconds = [0, 60, 180, 300];

  /// 密码长度
  static const int passwordLength = 4;

  /// 密码最大错误次数
  static const int maxPasswordAttempts = 5;

  /// 锁定时长（秒）
  static const int lockoutDurationSeconds = 60;
}

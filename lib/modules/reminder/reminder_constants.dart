/// 提醒模块常量配置
class ReminderConstants {
  /// 提醒类型列表
  static const List<String> types = ['健身训练', '喝水', '测血压', '服药'];

  /// 提醒类型图标
  static const Map<String, String> typeIcons = {
    '健身训练': 'fitness_center',
    '喝水': 'water_drop',
    '测血压': 'monitor_heart',
    '服药': 'medication',
  };

  /// 提醒类型默认标题
  static const Map<String, String> defaultTitles = {
    '健身训练': '该锻炼啦',
    '喝水': '记得喝水',
    '测血压': '请测量血压',
    '服药': '该吃药了',
  };

  /// 提醒类型默认内容
  static const Map<String, String> defaultContents = {
    '健身训练': '坚持运动，保持健康体魄',
    '喝水': '适量饮水，保持身体水分充足',
    '测血压': '定时测量血压，关注心血管健康',
    '服药': '按时服药，不要忘记哦',
  };

  /// 重复周期选项（周一到周日）
  static const List<String> weekdays = ['周一', '周二', '周三', '周四', '周五', '周六', '周日'];

  /// 常用快捷重复规则
  static const List<String> quickRepeatRules = ['每天', '工作日', '周末'];
}

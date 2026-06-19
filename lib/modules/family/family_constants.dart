/// 守护模块常量配置
class FamilyConstants {
  /// 成员关系选项
  static const List<String> relationships = [
    '父亲',
    '母亲',
    '配偶',
    '儿子',
    '女儿',
    '爷爷',
    '奶奶',
    '外公',
    '外婆',
    '兄弟',
    '姐妹',
    '其他',
  ];

  /// 健康指标类型
  static const List<String> healthTypes = [
    '血压',
    '心率',
    '步数',
    '服药',
  ];

  /// 血压分级枚举
  static const int gradeNormal = 0;
  static const int grade1 = 1;
  static const int grade2 = 2;

  /// CSV导出表头
  static const List<String> csvHeaders = [
    '记录类型',
    '测量值',
    '单位',
    '是否异常',
    '异常说明',
    '测量时间',
  ];
}

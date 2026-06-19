/// 医学参考值常量
class MedicalConstants {
  /// 血压参考值（收缩压/舒张压 mmHg）
  static const int systolicNormalMin = 90;
  static const int systolicNormalMax = 140;
  static const int diastolicNormalMin = 60;
  static const int diastolicNormalMax = 90;
  
  /// 血压分级阈值
  static const int systolicGrade1Min = 140;
  static const int systolicGrade1Max = 159;
  static const int diastolicGrade1Min = 90;
  static const int diastolicGrade1Max = 99;
  static const int systolicGrade2Min = 160;
  static const int diastolicGrade2Min = 100;
  
  /// 心率参考值（次/分钟）
  static const int heartRateNormalMin = 60;
  static const int heartRateNormalMax = 100;
  
  /// BMI参考值
  static const double bmiUnderweight = 18.5;
  static const double bmiNormalMax = 24.0;
  static const double bmiOverweightMax = 28.0;
  
  /// 血糖参考值（空腹 mmol/L）
  static const double bloodSugarNormalMin = 3.9;
  static const double bloodSugarNormalMax = 6.1;
  
  /// 体温参考值（℃）
  static const double temperatureNormalMin = 36.1;
  static const double temperatureNormalMax = 37.2;
  
  /// 血压异常说明
  static const String systolicHighDesc = '收缩压偏高，建议注意休息，减少盐分摄入';
  static const String systolicLowDesc = '收缩压偏低，建议适当增加营养摄入';
  static const String diastolicHighDesc = '舒张压偏高，建议适量运动，控制体重';
  static const String diastolicLowDesc = '舒张压偏低，建议避免久站，适当补充水分';
  
  /// 心率异常说明
  static const String heartRateHighDesc = '心率偏快，建议避免剧烈运动，保持情绪稳定';
  static const String heartRateLowDesc = '心率偏慢，如伴有头晕乏力建议就医检查';
  
  /// 高血压1级说明
  static const String hypertensionGrade1Desc = '血压轻度升高（高血压1级），建议低盐饮食、规律作息，定期监测';
  /// 高血压2级说明
  static const String hypertensionGrade2Desc = '血压明显升高（高血压2级），请尽快就医，遵医嘱服药';
}

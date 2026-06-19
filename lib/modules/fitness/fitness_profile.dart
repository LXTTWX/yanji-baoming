import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:yanji/core/constants/color_constants.dart';
import 'package:yanji/core/constants/medical_constants.dart';
import 'package:yanji/data/models/user_profile.dart';
import 'package:yanji/data/repositories/user_profile_repository.dart';
import 'package:yanji/data/models/health_record.dart';
import 'package:yanji/data/repositories/health_record_repository.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

/// 身体基础档案页
class FitnessProfilePage extends StatefulWidget {
  /// 构造函数
  const FitnessProfilePage({super.key});

  @override
  State<FitnessProfilePage> createState() => _FitnessProfilePageState();
}

class _FitnessProfilePageState extends State<FitnessProfilePage> {
  final UserProfileRepository _profileRepository = UserProfileRepository();
  final HealthRecordRepository _healthRepository = HealthRecordRepository();
  final TextEditingController _heightController = TextEditingController();
  final TextEditingController _weightController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  
  UserProfile? _profile;
  List<HealthRecord> _weightRecords = [];
  bool _isLoading = true;
  int _selectedGender = 0; // 0-未知，1-男，2-女

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  /// 加载用户资料和体重记录
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final profile = await _profileRepository.getProfile();
      final weightRecords = await _healthRepository.getRecordsByType('体重');
      
      setState(() {
        _profile = profile;
        _weightRecords = weightRecords;
        _isLoading = false;
        
        if (profile != null) {
          _heightController.text = profile.height?.toString() ?? '';
          _weightController.text = profile.weight?.toString() ?? '';
          _ageController.text = profile.age?.toString() ?? '';
          _selectedGender = profile.gender;
        }
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('加载数据失败');
    }
  }

  /// 显示错误提示
  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  /// 显示成功提示
  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.success),
    );
  }

  /// 保存用户资料
  Future<void> _saveProfile() async {
    final heightText = _heightController.text.trim();
    final weightText = _weightController.text.trim();
    final ageText = _ageController.text.trim();

    if (heightText.isEmpty || weightText.isEmpty || ageText.isEmpty) {
      _showErrorSnackBar('请填写完整信息');
      return;
    }

    final height = double.tryParse(heightText);
    final weight = double.tryParse(weightText);
    final age = int.tryParse(ageText);

    if (height == null || weight == null || age == null) {
      _showErrorSnackBar('请输入有效数字');
      return;
    }

    if (height <= 0 || weight <= 0 || age <= 0) {
      _showErrorSnackBar('数值必须大于0');
      return;
    }

    try {
      final now = DateTime.now().toIso8601String();
      
      if (_profile == null) {
        _profile = UserProfile(
          id: 'demo_user_001',
          nickname: '用户',
          age: age,
          gender: _selectedGender,
          height: height,
          weight: weight,
          createdAt: now,
          updatedAt: now,
        );
      } else {
        final profile = _profile;
        if (profile != null) {
          profile.age = age;
          profile.gender = _selectedGender;
          profile.height = height;
          profile.weight = weight;
          profile.updatedAt = now;
        }
      }

      final currentProfile = _profile;
      if (currentProfile != null) {
        await _profileRepository.saveProfile(currentProfile);
      }
      _showSuccessSnackBar('保存成功');
      setState(() {});
    } catch (e) {
      _showErrorSnackBar('保存失败');
    }
  }

  /// 记录今日体重
  Future<void> _recordTodayWeight() async {
    final weightText = _weightController.text.trim();
    if (weightText.isEmpty) {
      _showErrorSnackBar('请先填写体重');
      return;
    }

    final weight = double.tryParse(weightText);
    if (weight == null || weight <= 0) {
      _showErrorSnackBar('请输入有效的体重');
      return;
    }

    try {
      final now = DateTime.now();
      final todayStr = DateFormat('yyyy-MM-dd').format(now);
      
      // 检查今天是否已记录
      final existingRecord = _weightRecords.where((r) => 
        r.measuredAt.startsWith(todayStr)
      ).toList();
      
      if (existingRecord.isNotEmpty) {
        _showErrorSnackBar('今日已记录体重');
        return;
      }

      final record = HealthRecord(
        id: const Uuid().v4(),
        memberId: 'demo_user_001',
        type: '体重',
        value: weight.toString(),
        unit: 'kg',
        isAbnormal: false,
        measuredAt: now.toIso8601String(),
        createdAt: now.toIso8601String(),
      );

      await _healthRepository.addRecord(record);
      _weightRecords.add(record);
      _showSuccessSnackBar('记录成功');
      setState(() {});
    } catch (e) {
      _showErrorSnackBar('记录失败');
    }
  }

  /// 计算BMI
  double? _calculateBMI() {
    final profile = _profile;
    final height = profile?.height;
    final weight = profile?.weight;
    
    if (height != null && weight != null && height > 0) {
      final heightInM = height / 100;
      return weight / (heightInM * heightInM);
    }
    return null;
  }

  /// 获取BMI状态描述
  String _getBMIDescription(double bmi) {
    if (bmi < MedicalConstants.bmiUnderweight) {
      return '偏瘦';
    } else if (bmi < MedicalConstants.bmiNormalMax) {
      return '正常';
    } else if (bmi < MedicalConstants.bmiOverweightMax) {
      return '超重';
    } else {
      return '肥胖';
    }
  }

  /// 获取BMI状态颜色
  Color _getBMIColor(double bmi) {
    if (bmi < MedicalConstants.bmiUnderweight) {
      return AppColors.warning;
    } else if (bmi < MedicalConstants.bmiNormalMax) {
      return AppColors.success;
    } else if (bmi < MedicalConstants.bmiOverweightMax) {
      return AppColors.warning;
    } else {
      return AppColors.error;
    }
  }

  /// 计算BMR基础代谢
  double? _calculateBMR() {
    final profile = _profile;
    final height = profile?.height;
    final weight = profile?.weight;
    final age = profile?.age;
    final gender = profile?.gender;
    
    if (height != null && weight != null && age != null && height > 0 && weight > 0 && age > 0) {
      // Mifflin-St Jeor公式
      if (gender == 1) {
        // 男性：BMR = 10×体重(kg) + 6.25×身高(cm) - 5×年龄 - 161 + 166
        return 10 * weight + 6.25 * height - 5 * age - 161 + 166;
      } else {
        // 女性：BMR = 10×体重(kg) + 6.25×身高(cm) - 5×年龄 - 161
        return 10 * weight + 6.25 * height - 5 * age - 161;
      }
    }
    return null;
  }

  /// 获取近30天体重数据
  List<FlSpot> _getWeightChartData() {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    
    final recentRecords = _weightRecords.where((r) {
      final recordDate = DateTime.parse(r.measuredAt);
      return recordDate.isAfter(thirtyDaysAgo);
    }).toList();

    // 按日期排序
    recentRecords.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    return recentRecords.map((record) {
      final date = DateTime.parse(record.measuredAt);
      final dayDiff = now.difference(date).inDays.toDouble();
      final weight = double.tryParse(record.value) ?? 0;
      return FlSpot(dayDiff, weight);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.04;
    final fontSize = MediaQuery.of(context).textScaler.scale(14);

    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('身体档案'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textLight,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('身体档案'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildProfileForm(context, padding, fontSize),
            SizedBox(height: padding * 2),
            _buildBMICard(context, padding, fontSize),
            SizedBox(height: padding * 2),
            _buildBMROCard(context, padding, fontSize),
            SizedBox(height: padding * 2),
            _buildWeightChart(context, padding, fontSize),
            SizedBox(height: padding * 2),
            _buildRecordButton(context, padding, fontSize),
          ],
        ),
      ),
    );
  }

  /// 构建资料表单
  Widget _buildProfileForm(BuildContext context, double padding, double fontSize) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(padding * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基础信息',
              style: TextStyle(
                fontSize: fontSize * 1.2,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: padding),
            _buildTextField('身高 (cm)', _heightController, TextInputType.number),
            SizedBox(height: padding),
            _buildTextField('体重 (kg)', _weightController, TextInputType.number),
            SizedBox(height: padding),
            _buildTextField('年龄', _ageController, TextInputType.number),
            SizedBox(height: padding),
            _buildGenderSelector(padding, fontSize),
            SizedBox(height: padding * 1.5),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.textLight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  '保存资料',
                  style: TextStyle(fontSize: fontSize * 1.1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建输入框
  Widget _buildTextField(String label, TextEditingController controller, TextInputType keyboardType) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  /// 构建性别选择器
  Widget _buildGenderSelector(double padding, double fontSize) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '性别',
          style: TextStyle(
            fontSize: fontSize,
            color: AppColors.textSecondary,
          ),
        ),
        SizedBox(height: padding * 0.5),
        RadioGroup<int>(
          groupValue: _selectedGender,
          onChanged: (value) => setState(() => _selectedGender = value ?? 0),
          child: Row(
            children: [
              Expanded(
                child: RadioListTile<int>(
                  title: Text('男', style: TextStyle(fontSize: fontSize)),
                  value: 1,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              Expanded(
                child: RadioListTile<int>(
                  title: Text('女', style: TextStyle(fontSize: fontSize)),
                  value: 2,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 构建BMI卡片
  Widget _buildBMICard(BuildContext context, double padding, double fontSize) {
    final bmi = _calculateBMI();
    final bmiValue = bmi?.toStringAsFixed(1) ?? '--';
    final bmiDesc = bmi != null ? _getBMIDescription(bmi) : '请先填写身高体重';
    final bmiColor = bmi != null ? _getBMIColor(bmi) : AppColors.textSecondary;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(padding * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'BMI指数',
              style: TextStyle(
                fontSize: fontSize * 1.2,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: padding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bmiValue,
                      style: TextStyle(
                        fontSize: fontSize * 2.5,
                        fontWeight: FontWeight.bold,
                        color: bmiColor,
                      ),
                    ),
                    SizedBox(height: padding * 0.5),
                    Text(
                      bmiDesc,
                      style: TextStyle(
                        fontSize: fontSize,
                        color: bmiColor,
                      ),
                    ),
                  ],
                ),
                _buildBMIGauge(bmi, fontSize),
              ],
            ),
            SizedBox(height: padding),
            Text(
              '正常范围：18.5 - 24.0',
              style: TextStyle(
                fontSize: fontSize * 0.9,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建BMI仪表盘
  Widget _buildBMIGauge(double? bmi, double fontSize) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: bmi != null ? (bmi / 40).clamp(0.0, 1.0) : 0,
            strokeWidth: 8,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(
              bmi != null ? _getBMIColor(bmi) : AppColors.textSecondary,
            ),
          ),
          Text(
            bmi != null ? bmi.toStringAsFixed(1) : '--',
            style: TextStyle(
              fontSize: fontSize * 1.2,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// 构建BMR卡片
  Widget _buildBMROCard(BuildContext context, double padding, double fontSize) {
    final bmr = _calculateBMR();
    final bmrValue = bmr?.toStringAsFixed(0) ?? '--';

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(padding * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '基础代谢率 (BMR)',
              style: TextStyle(
                fontSize: fontSize * 1.2,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: padding),
            Text(
              '$bmrValue 千卡/天',
              style: TextStyle(
                fontSize: fontSize * 2,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: padding * 0.5),
            Text(
              '基础代谢率是指人体在清醒而又极端安静的状态下，不受肌肉活动、环境温度、食物及精神紧张等影响时的能量代谢率。',
              style: TextStyle(
                fontSize: fontSize * 0.9,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建体重图表
  Widget _buildWeightChart(BuildContext context, double padding, double fontSize) {
    final chartData = _getWeightChartData();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(padding * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '体重变化趋势',
              style: TextStyle(
                fontSize: fontSize * 1.2,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: padding),
            if (chartData.isEmpty)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(padding * 2),
                  child: Text(
                    '暂无体重记录，请先记录今日体重',
                    style: TextStyle(
                      fontSize: fontSize,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 200,
                child: LineChart(
                  LineChartData(
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: 5,
                      getDrawingHorizontalLine: (value) {
                        return FlLine(
                          color: AppColors.divider,
                          strokeWidth: 1,
                        );
                      },
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 40,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                fontSize: fontSize * 0.8,
                                color: AppColors.textSecondary,
                              ),
                            );
                          },
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 30,
                          getTitlesWidget: (value, meta) {
                            final daysAgo = value.toInt();
                            if (daysAgo % 5 == 0) {
                              return Text(
                                '$daysAgo天前',
                                style: TextStyle(
                                  fontSize: fontSize * 0.8,
                                  color: AppColors.textSecondary,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(
                      show: true,
                      border: Border.all(color: AppColors.divider),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: chartData,
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) {
                            return FlDotCirclePainter(
                              radius: 4,
                              color: AppColors.primary,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// 构建记录按钮
  Widget _buildRecordButton(BuildContext context, double padding, double fontSize) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: _recordTodayWeight,
        icon: const Icon(Icons.monitor_weight, size: 24),
        label: Text(
          '记录今日体重',
          style: TextStyle(fontSize: fontSize * 1.2),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.textLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

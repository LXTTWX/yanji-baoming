import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:yanji/core/constants/color_constants.dart';
import 'package:yanji/core/constants/medical_constants.dart';
import 'package:yanji/data/models/fitness_record.dart';
import 'package:yanji/data/models/user_profile.dart';
import 'package:yanji/data/repositories/fitness_record_repository.dart';
import 'package:yanji/data/repositories/user_profile_repository.dart';

/// 健身统计页面
class FitnessStatsPage extends StatefulWidget {
  /// 构造函数
  const FitnessStatsPage({super.key});

  @override
  State<FitnessStatsPage> createState() => _FitnessStatsPageState();
}

class _FitnessStatsPageState extends State<FitnessStatsPage> {
  final FitnessRecordRepository _fitnessRepo = FitnessRecordRepository();
  final UserProfileRepository _profileRepo = UserProfileRepository();
  
  List<FitnessRecord> _allRecords = [];
  UserProfile? _userProfile;
  bool _isLoading = true;
  
  // 统计数据
  int _consecutiveDays = 0;
  int _totalDays = 0;
  double _weekCompletionRate = 0.0;
  double _monthCompletionRate = 0.0;
  List<FlSpot> _bmiSpots = [];
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }
  
  /// 加载数据
  Future<void> _loadData() async {
    try {
      final records = await _fitnessRepo.getAllRecords();
      final profile = await _profileRepo.getProfile();
      
      setState(() {
        _allRecords = records;
        _userProfile = profile;
        _calculateStats();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  /// 计算统计数据
  void _calculateStats() {
    // 连续打卡天数
    _consecutiveDays = _calculateConsecutiveDays();
    
    // 累计训练天数
    _totalDays = _allRecords.where((r) => r.completed).length;
    
    // 本周完成率
    _weekCompletionRate = _calculateWeekCompletionRate();
    
    // 本月完成率
    _monthCompletionRate = _calculateMonthCompletionRate();
    
    // BMI变化趋势
    _bmiSpots = _calculateBmiSpots();
  }
  
  /// 计算连续打卡天数
  int _calculateConsecutiveDays() {
    final completedRecords = _allRecords.where((r) => r.completed).toList();
    if (completedRecords.isEmpty) return 0;
    
    completedRecords.sort((a, b) => b.date.compareTo(a.date));
    int consecutive = 0;
    String? lastDate;
    
    for (final record in completedRecords) {
      if (lastDate == null) {
        lastDate = record.date;
        consecutive = 1;
      } else {
        final last = DateTime.parse(lastDate);
        final current = DateTime.parse(record.date);
        final diff = last.difference(current).inDays;
        if (diff == 1) {
          consecutive++;
          lastDate = record.date;
        } else {
          break;
        }
      }
    }
    return consecutive;
  }
  
  /// 计算本周完成率
  double _calculateWeekCompletionRate() {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final weekRecords = _allRecords.where((r) {
      final recordDate = DateTime.parse(r.date);
      return recordDate.isAfter(startOfWeek.subtract(const Duration(days: 1))) &&
             recordDate.isBefore(now.add(const Duration(days: 1)));
    }).toList();
    
    if (weekRecords.isEmpty) return 0.0;
    final completed = weekRecords.where((r) => r.completed).length;
    return completed / 7.0;
  }
  
  /// 计算本月完成率
  double _calculateMonthCompletionRate() {
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final monthRecords = _allRecords.where((r) {
      final recordDate = DateTime.parse(r.date);
      return recordDate.isAfter(startOfMonth.subtract(const Duration(days: 1))) &&
             recordDate.isBefore(now.add(const Duration(days: 1)));
    }).toList();
    
    if (monthRecords.isEmpty) return 0.0;
    final completed = monthRecords.where((r) => r.completed).length;
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return completed / daysInMonth;
  }
  
  /// 计算BMI变化趋势
  List<FlSpot> _calculateBmiSpots() {
    if (_userProfile == null) return [];
    
    final bmi = _userProfile?.calculateBMI();
    if (bmi == null) return [];
    
    // 模拟历史数据（实际应从存储中获取）
    return [
      FlSpot(0, bmi - 2),
      FlSpot(1, bmi - 1.5),
      FlSpot(2, bmi - 1),
      FlSpot(3, bmi - 0.5),
      FlSpot(4, bmi),
    ];
  }
  
  /// 获取BMI状态描述
  String _getBmiStatus(double bmi) {
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
  Color _getBmiStatusColor(double bmi) {
    if (bmi < MedicalConstants.bmiUnderweight) {
      return AppColors.warning;
    } else if (bmi < MedicalConstants.bmiNormalMax) {
      return AppColors.healthNormal;
    } else if (bmi < MedicalConstants.bmiOverweightMax) {
      return AppColors.warning;
    } else {
      return AppColors.healthDanger;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.04;
    final isElderMode = MediaQuery.of(context).textScaler.scale(1) > 1.1;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('健身统计'),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 核心数据卡片
                  _buildCoreStatsCard(context, padding, isElderMode),
                  SizedBox(height: padding),
                  
                  // 近30天打卡情况
                  _buildCheckInChart(context, padding, isElderMode),
                  SizedBox(height: padding),
                  
                  // BMI变化趋势
                  _buildBmiTrendCard(context, padding, isElderMode),
                  SizedBox(height: padding),
                  
                  // 进度条可视化
                  _buildProgressCard(context, padding, isElderMode),
                ],
              ),
            ),
    );
  }
  
  /// 构建核心数据卡片
  Widget _buildCoreStatsCard(BuildContext context, double padding, bool isElderMode) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: EdgeInsets.all(padding * 1.5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.1),
              AppColors.primaryLight.withValues(alpha: 0.1),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '核心数据',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isElderMode ? 24 : 20,
              ),
            ),
            SizedBox(height: padding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  '$_consecutiveDays',
                  '连续打卡',
                  Icons.local_fire_department,
                  AppColors.accent,
                  isElderMode,
                ),
                _buildStatItem(
                  context,
                  '${(_weekCompletionRate * 100).toStringAsFixed(0)}%',
                  '本周完成率',
                  Icons.trending_up,
                  AppColors.success,
                  isElderMode,
                ),
                _buildStatItem(
                  context,
                  '${(_monthCompletionRate * 100).toStringAsFixed(0)}%',
                  '本月完成率',
                  Icons.calendar_month,
                  AppColors.info,
                  isElderMode,
                ),
                _buildStatItem(
                  context,
                  '$_totalDays',
                  '累计训练',
                  Icons.fitness_center,
                  AppColors.primary,
                  isElderMode,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建统计项
  Widget _buildStatItem(
    BuildContext context,
    String value,
    String label,
    IconData icon,
    Color color,
    bool isElderMode,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(MediaQuery.of(context).size.width * 0.03),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: color,
            size: isElderMode ? 28 : 24,
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.width * 0.02),
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
            fontSize: isElderMode ? 28 : 24,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            fontSize: isElderMode ? 14 : 12,
          ),
        ),
      ],
    );
  }
  
  /// 构建打卡图表
  Widget _buildCheckInChart(BuildContext context, double padding, bool isElderMode) {
    // 获取近30天数据
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final recentRecords = _allRecords.where((r) {
      final recordDate = DateTime.parse(r.date);
      return recordDate.isAfter(thirtyDaysAgo) && r.completed;
    }).toList();
    
    // 按日期分组
    final Map<String, int> dailyCheckIns = {};
    for (int i = 0; i < 30; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = date.toIso8601String().substring(0, 10);
      dailyCheckIns[dateStr] = 0;
    }
    
    for (final record in recentRecords) {
      final dateStr = record.date.substring(0, 10);
      if (dailyCheckIns.containsKey(dateStr)) {
        final current = dailyCheckIns[dateStr] ?? 0;
        dailyCheckIns[dateStr] = current + 1;
      }
    }
    
    final spots = <BarChartGroupData>[];
    final entries = dailyCheckIns.entries.toList();
    
    for (int i = 0; i < entries.length; i++) {
      spots.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: entries[i].value.toDouble(),
              color: entries[i].value > 0 ? AppColors.primary : AppColors.divider,
              width: MediaQuery.of(context).size.width * 0.03,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '近30天打卡情况',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isElderMode ? 20 : 16,
              ),
            ),
            SizedBox(height: padding),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.2,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: 3,
                  barTouchData: BarTouchData(enabled: false),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() % 5 == 0) {
                            return Text(
                              '${value.toInt()}',
                              style: TextStyle(
                                fontSize: isElderMode ? 12 : 10,
                                color: AppColors.textSecondary,
                              ),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() == value) {
                            return Text(
                              '${value.toInt()}',
                              style: TextStyle(
                                fontSize: isElderMode ? 12 : 10,
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
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  barGroups: spots,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建BMI趋势卡片
  Widget _buildBmiTrendCard(BuildContext context, double padding, bool isElderMode) {
    final currentBmi = _userProfile?.calculateBMI();
    final bmiStatus = currentBmi != null ? _getBmiStatus(currentBmi) : '未知';
    final bmiColor = currentBmi != null ? _getBmiStatusColor(currentBmi) : AppColors.textSecondary;
    
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BMI变化趋势',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: isElderMode ? 20 : 16,
                  ),
                ),
                if (currentBmi != null)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: MediaQuery.of(context).size.width * 0.03,
                      vertical: MediaQuery.of(context).size.width * 0.01,
                    ),
                    decoration: BoxDecoration(
                      color: bmiColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      bmiStatus,
                      style: TextStyle(
                        color: bmiColor,
                        fontWeight: FontWeight.bold,
                        fontSize: isElderMode ? 16 : 14,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: padding),
            if (_bmiSpots.isNotEmpty)
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.2,
                child: LineChart(
                  LineChartData(
                    gridData: const FlGridData(show: false),
                    titlesData: FlTitlesData(
                      show: true,
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            final labels = ['4周前', '3周前', '2周前', '1周前', '本周'];
                            if (value.toInt() < labels.length) {
                              return Text(
                                labels[value.toInt()],
                                style: TextStyle(
                                  fontSize: isElderMode ? 12 : 10,
                                  color: AppColors.textSecondary,
                                ),
                              );
                            }
                            return const Text('');
                          },
                        ),
                      ),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (value, meta) {
                            return Text(
                              value.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: isElderMode ? 12 : 10,
                                color: AppColors.textSecondary,
                              ),
                            );
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
                    borderData: FlBorderData(show: false),
                    lineBarsData: [
                      LineChartBarData(
                        spots: _bmiSpots,
                        isCurved: true,
                        color: AppColors.primary,
                        barWidth: 3,
                        isStrokeCapRound: true,
                        dotData: const FlDotData(show: true),
                        belowBarData: BarAreaData(
                          show: true,
                          color: AppColors.primary.withValues(alpha: 0.1),
                        ),
                      ),
                    ],
                    minY: 15,
                    maxY: 35,
                  ),
                ),
              )
            else
              Center(
                child: Text(
                  '暂无BMI数据',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: isElderMode ? 16 : 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  /// 构建进度条卡片
  Widget _buildProgressCard(BuildContext context, double padding, bool isElderMode) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(padding * 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '训练进度',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: isElderMode ? 20 : 16,
              ),
            ),
            SizedBox(height: padding),
            _buildProgressBar(
              context,
              '本周完成率',
              _weekCompletionRate,
              AppColors.success,
              isElderMode,
            ),
            SizedBox(height: padding * 0.5),
            _buildProgressBar(
              context,
              '本月完成率',
              _monthCompletionRate,
              AppColors.info,
              isElderMode,
            ),
            SizedBox(height: padding * 0.5),
            _buildProgressBar(
              context,
              '连续打卡目标',
              _consecutiveDays / 30.0,
              AppColors.accent,
              isElderMode,
            ),
          ],
        ),
      ),
    );
  }
  
  /// 构建进度条
  Widget _buildProgressBar(
    BuildContext context,
    String label,
    double progress,
    Color color,
    bool isElderMode,
  ) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: isElderMode ? 16 : 14,
              ),
            ),
            Text(
              '${(clampedProgress * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: isElderMode ? 16 : 14,
              ),
            ),
          ],
        ),
        SizedBox(height: MediaQuery.of(context).size.width * 0.02),
        LinearProgressIndicator(
          value: clampedProgress,
          backgroundColor: color.withValues(alpha: 0.1),
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: MediaQuery.of(context).size.width * 0.02,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }
}
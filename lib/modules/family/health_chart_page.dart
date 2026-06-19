import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:yanji/core/constants/color_constants.dart';
import 'package:yanji/core/constants/medical_constants.dart';
import 'package:yanji/core/utils/platform_file.dart';
import 'package:yanji/data/models/health_record.dart';
import 'package:yanji/data/repositories/health_record_repository.dart';
import 'package:yanji/modules/family/family_constants.dart';

/// 健康趋势分析页
class HealthChartPage extends StatefulWidget {
  /// 成员ID
  final String memberId;

  /// 成员姓名
  final String memberName;

  /// 构造函数
  const HealthChartPage({super.key, required this.memberId, required this.memberName});

  @override
  State<HealthChartPage> createState() => _HealthChartPageState();
}

class _HealthChartPageState extends State<HealthChartPage> {
  final HealthRecordRepository _healthRepo = HealthRecordRepository();
  
  List<HealthRecord> _allRecords = [];
  List<HealthRecord> _bpRecords = [];
  List<HealthRecord> _hrRecords = [];
  bool _isLoading = true;
  bool _showWeek = true; // true=周视图, false=月视图

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// 加载健康记录
  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final records = await _healthRepo.getRecordsByMember(widget.memberId);
      records.sort((a, b) => a.measuredAt.compareTo(b.measuredAt));
      
      setState(() {
        _allRecords = records;
        _bpRecords = records.where((r) => r.type == '血压').toList();
        _hrRecords = records.where((r) => r.type == '心率').toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  /// 获取日期范围内的记录
  List<HealthRecord> _getRecordsInRange(List<HealthRecord> records, int days) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    return records.where((r) {
      final date = DateTime.parse(r.measuredAt);
      return date.isAfter(startDate);
    }).toList();
  }

  /// 解析血压收缩压
  int? _parseSystolic(String value) {
    final parts = value.split('/');
    if (parts.length == 2) {
      return int.tryParse(parts[0]);
    }
    return null;
  }

  /// 解析血压舒张压
  int? _parseDiastolic(String value) {
    final parts = value.split('/');
    if (parts.length == 2) {
      return int.tryParse(parts[1]);
    }
    return null;
  }

  /// 导出CSV
  Future<void> _exportCSV() async {
    if (kIsWeb) {
      _showSnackBar('Web端暂不支持导出文件', isError: true);
      return;
    }

    try {
      final List<List<String>> csvData = [
        FamilyConstants.csvHeaders,
      ];

      for (final record in _allRecords) {
        final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(DateTime.parse(record.measuredAt));
        csvData.add([
          record.type,
          record.value,
          record.unit,
          record.isAbnormal ? '是' : '否',
          record.abnormalDesc ?? '',
          dateStr,
        ]);
      }

      final csv = const ListToCsvConverter().convert(csvData);
      final now = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = '${widget.memberName}_健康档案_$now.csv';
      
      if (kIsWeb) {
        _showSnackBar('Web端暂不支持文件导出', isError: true);
        return;
      }

      final path = await exportToTempFile(csv, fileName);
      if (path != null) {
        _showSnackBar('已导出到: $path');
      } else {
        _showSnackBar('导出失败', isError: true);
      }
    } catch (e) {
      _showSnackBar('导出失败: $e', isError: true);
    }
  }

  /// 显示提示
  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth * 0.05;
    final fontSize = MediaQuery.of(context).textScaler.scale(14);

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.memberName} 健康趋势'),
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.textLight,
        actions: [
          IconButton(
            onPressed: _exportCSV,
            icon: const Icon(Icons.download),
            tooltip: '导出CSV',
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeToggle(padding, fontSize),
                  SizedBox(height: padding),
                  _buildBloodPressureChart(context, padding, fontSize),
                  SizedBox(height: padding),
                  _buildHeartRateChart(context, padding, fontSize),
                  SizedBox(height: padding),
                  _buildSummaryCard(context, padding, fontSize),
                ],
              ),
            ),
    );
  }

  /// 构建时间范围切换
  Widget _buildTimeToggle(double padding, double fontSize) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showWeek = true),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: padding * 0.6),
                decoration: BoxDecoration(
                  color: _showWeek ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '近7天',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: _showWeek ? AppColors.textLight : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _showWeek = false),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: padding * 0.6),
                decoration: BoxDecoration(
                  color: !_showWeek ? AppColors.primary : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '近30天',
                    style: TextStyle(
                      fontSize: fontSize,
                      fontWeight: FontWeight.bold,
                      color: !_showWeek ? AppColors.textLight : AppColors.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 构建血压趋势图
  Widget _buildBloodPressureChart(BuildContext context, double padding, double fontSize) {
    final days = _showWeek ? 7 : 30;
    final records = _getRecordsInRange(_bpRecords, days);
    
    if (records.isEmpty) {
      return _buildEmptyChart('血压趋势', '暂无血压数据', padding, fontSize);
    }

    final systolicSpots = <FlSpot>[];
    final diastolicSpots = <FlSpot>[];
    
    for (int i = 0; i < records.length; i++) {
      final systolic = _parseSystolic(records[i].value);
      final diastolic = _parseDiastolic(records[i].value);
      if (systolic != null) {
        systolicSpots.add(FlSpot(i.toDouble(), systolic.toDouble()));
      }
      if (diastolic != null) {
        diastolicSpots.add(FlSpot(i.toDouble(), diastolic.toDouble()));
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '血压趋势',
              style: TextStyle(
                fontSize: fontSize * 1.2,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: padding),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.25,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(fontSize: fontSize * 0.8, color: AppColors.textSecondary),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < records.length) {
                            final date = DateTime.parse(records[idx].measuredAt);
                            return Text(
                              DateFormat('MM/dd').format(date),
                              style: TextStyle(fontSize: fontSize * 0.75, color: AppColors.textSecondary),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 40,
                  maxY: 200,
                  lineBarsData: [
                    LineChartBarData(
                      spots: systolicSpots,
                      isCurved: true,
                      color: AppColors.error,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                    ),
                    LineChartBarData(
                      spots: diastolicSpots,
                      isCurved: true,
                      color: AppColors.warning,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: MedicalConstants.systolicNormalMax.toDouble(),
                        color: AppColors.error.withValues(alpha: 0.3),
                        strokeWidth: 1,
                        dashArray: [8, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          style: TextStyle(fontSize: fontSize * 0.7, color: AppColors.error),
                          labelResolver: (_) => '收缩压上限',
                        ),
                      ),
                      HorizontalLine(
                        y: MedicalConstants.diastolicNormalMax.toDouble(),
                        color: AppColors.warning.withValues(alpha: 0.3),
                        strokeWidth: 1,
                        dashArray: [8, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          style: TextStyle(fontSize: fontSize * 0.7, color: AppColors.warning),
                          labelResolver: (_) => '舒张压上限',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: padding * 0.5),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildLegend('收缩压', AppColors.error, fontSize),
                SizedBox(width: padding),
                _buildLegend('舒张压', AppColors.warning, fontSize),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建心率趋势图
  Widget _buildHeartRateChart(BuildContext context, double padding, double fontSize) {
    final days = _showWeek ? 7 : 30;
    final records = _getRecordsInRange(_hrRecords, days);
    
    if (records.isEmpty) {
      return _buildEmptyChart('心率趋势', '暂无心率数据', padding, fontSize);
    }

    final spots = <FlSpot>[];
    for (int i = 0; i < records.length; i++) {
      final hr = int.tryParse(records[i].value);
      if (hr != null) {
        spots.add(FlSpot(i.toDouble(), hr.toDouble()));
      }
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '心率趋势',
              style: TextStyle(
                fontSize: fontSize * 1.2,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: padding),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.25,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: TextStyle(fontSize: fontSize * 0.8, color: AppColors.textSecondary),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx >= 0 && idx < records.length) {
                            final date = DateTime.parse(records[idx].measuredAt);
                            return Text(
                              DateFormat('MM/dd').format(date),
                              style: TextStyle(fontSize: fontSize * 0.75, color: AppColors.textSecondary),
                            );
                          }
                          return const Text('');
                        },
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  minY: 40,
                  maxY: 140,
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
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
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: MedicalConstants.heartRateNormalMin.toDouble(),
                        color: AppColors.warning.withValues(alpha: 0.3),
                        strokeWidth: 1,
                        dashArray: [8, 4],
                      ),
                      HorizontalLine(
                        y: MedicalConstants.heartRateNormalMax.toDouble(),
                        color: AppColors.warning.withValues(alpha: 0.3),
                        strokeWidth: 1,
                        dashArray: [8, 4],
                        label: HorizontalLineLabel(
                          show: true,
                          style: TextStyle(fontSize: fontSize * 0.7, color: AppColors.warning),
                          labelResolver: (_) => '正常上限',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建空图表占位
  Widget _buildEmptyChart(String title, String message, double padding, double fontSize) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(padding * 2),
        child: Column(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: fontSize * 1.2,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: padding),
            Icon(Icons.show_chart, size: fontSize * 3, color: AppColors.textHint),
            SizedBox(height: padding * 0.5),
            Text(
              message,
              style: TextStyle(fontSize: fontSize, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  /// 构建图例
  Widget _buildLegend(String label, Color color, double fontSize) {
    return Row(
      children: [
        Container(
          width: fontSize,
          height: fontSize,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        SizedBox(width: fontSize * 0.3),
        Text(label, style: TextStyle(fontSize: fontSize * 0.9, color: AppColors.textSecondary)),
      ],
    );
  }

  /// 构建汇总卡片
  Widget _buildSummaryCard(BuildContext context, double padding, double fontSize) {
    final abnormalCount = _allRecords.where((r) => r.isAbnormal).length;
    final totalCount = _allRecords.length;
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '数据汇总',
              style: TextStyle(
                fontSize: fontSize * 1.2,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: padding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem('总记录', '$totalCount', AppColors.primary, fontSize, padding),
                _buildSummaryItem('异常记录', '$abnormalCount', AppColors.error, fontSize, padding),
                _buildSummaryItem('血压记录', '${_bpRecords.length}', AppColors.warning, fontSize, padding),
                _buildSummaryItem('心率记录', '${_hrRecords.length}', AppColors.info, fontSize, padding),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 构建汇总项
  Widget _buildSummaryItem(String label, String value, Color color, double fontSize, double padding) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize * 1.8,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        SizedBox(height: padding * 0.2),
        Text(
          label,
          style: TextStyle(fontSize: fontSize * 0.85, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

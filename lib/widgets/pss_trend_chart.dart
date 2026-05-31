import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/pss_assessment.dart';
import '../theme/app_theme.dart';

/// Widget to display PSS trend over time
class PssTrendChart extends StatelessWidget {
  final List<PSSAssessment> assessments;
  final double height;

  const PssTrendChart({
    super.key,
    required this.assessments,
    this.height = 250,
  });

  @override
  Widget build(BuildContext context) {
    if (assessments.isEmpty) {
      return SizedBox(
        height: height,
        child: const Center(
          child: Text('Complete assessments to see your stress trend'),
        ),
      );
    }

    // Sort by date (oldest first)
    final sortedAssessments = List<PSSAssessment>.from(assessments)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Get first and last PSS score
    final firstScore = sortedAssessments.first.totalScore;
    final lastScore = sortedAssessments.last.totalScore;
    final change = lastScore - firstScore;
    final changeColor = change < 0
        ? AppTheme.success
        : change > 0
            ? AppTheme.accent
            : AppTheme.primary;
    final changeText = change < 0
        ? '↓ ${change.abs()} points (Improving!)'
        : change > 0
            ? '↑ $change points (Increasing)'
            : '→ Stable';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Stress Trend',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${assessments.length} assessment${assessments.length > 1 ? 's' : ''}',
                    style: const TextStyle(color: AppTheme.textSecondary),
                  ),
                ],
              ),
              Flexible(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: changeColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: changeColor),
                  ),
                  child: Text(
                    changeText,
                    style: TextStyle(
                      color: changeColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Chart
        SizedBox(
          height: height,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 10,
                  getDrawingHorizontalLine: (value) {
                    return const FlLine(
                      color: AppTheme.divider,
                      strokeWidth: 1,
                      dashArray: [5, 5],
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 10,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 30,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < sortedAssessments.length) {
                          final assessment = sortedAssessments[value.toInt()];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              DateFormat('MMM d').format(assessment.date),
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: true,
                  border: const Border(
                    left: BorderSide(color: AppTheme.divider),
                    bottom: BorderSide(color: AppTheme.divider),
                  ),
                ),
                minX: 0,
                maxX: (sortedAssessments.length - 1).toDouble(),
                minY: 0,
                maxY: 40,
                lineBarsData: [
                  LineChartBarData(
                    spots: sortedAssessments
                        .asMap()
                        .entries
                        .map(
                          (e) => FlSpot(
                            e.key.toDouble(),
                            e.value.totalScore.toDouble(),
                          ),
                        )
                        .toList(),
                    isCurved: true,
                    curveSmoothness: 0.3,
                    color: _getLineColor(lastScore),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) {
                        return FlDotCirclePainter(
                          radius: 4,
                          color: Colors.white,
                          strokeWidth: 2,
                          strokeColor: _getLineColor(spot.y.toInt()),
                        );
                      },
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      color: _getLineColor(lastScore).withValues(alpha: 0.1),
                    ),
                  ),
                ],
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    tooltipBgColor: AppTheme.primaryDark,
                    getTooltipItems: (touchedSpots) {
                      return touchedSpots.map((spot) {
                        final assessment = sortedAssessments[spot.x.toInt()];
                        return LineTooltipItem(
                          'PSS: ${spot.y.toInt()}/40\n'
                          '${DateFormat('MMM d, y').format(assessment.date)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      }).toList();
                    },
                  ),
                ),
              ),
            ),
          ),
        ),

        // Stress level indicators
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildLegendItem('Low (0-13)', AppTheme.stressLow),
              _buildLegendItem('Moderate (14-26)', AppTheme.stressModerate),
              _buildLegendItem('High (27-40)', AppTheme.stressSevere),
            ],
          ),
        ),
      ],
    );
  }

  Color _getLineColor(int score) {
    if (score <= 13) return AppTheme.stressLow;
    if (score <= 26) return AppTheme.stressModerate;
    return AppTheme.stressSevere;
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 11),
        ),
      ],
    );
  }
}

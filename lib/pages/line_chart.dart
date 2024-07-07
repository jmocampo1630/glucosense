import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:glucolook/models/glucose_record.model.dart';
import 'package:glucolook/resources/app_colors.dart';
import 'package:glucolook/resources/gradient_data.dart';

class LineChartGraph extends StatefulWidget {
  const LineChartGraph({super.key, required this.records});
  final List<GlucoseRecord> records;

  @override
  State<LineChartGraph> createState() => _LineChartGraphState();
}

class _LineChartGraphState extends State<LineChartGraph> {
  List<Color> gradientColors = [
    AppColors.contentColorBlue,
    AppColors.contentColorYellow,
    AppColors.contentColorRed,
  ];

  bool showAvg = false;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        AspectRatio(
          aspectRatio: 1.70,
          child: Padding(
            padding: const EdgeInsets.only(
              right: 18,
              left: 12,
              top: 24,
              bottom: 12,
            ),
            child: LineChart(mainData()),
          ),
        ),
      ],
    );
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    // Widget text;
    // switch (value.toInt()) {
    //   case 2:
    //     text = const Text('MAR', style: style);
    //     break;
    //   case 5:
    //     text = const Text('JUN', style: style);
    //     break;
    //   case 8:
    //     text = const Text('SEP', style: style);
    //     break;
    //   default:
    //     text = const Text('', style: style);
    //     break;
    // }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(value.toStringAsFixed(0), style: style),
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 12,
    );
    String text;
    switch (value.toInt() % 2) {
      case 0:
        text = value.toStringAsFixed(0);
        break;
      default:
        return Container();
    }

    return Text(text, style: style, textAlign: TextAlign.left);
  }

  LineChartData mainData() {
    double maxX = 15;
    double maxY = widget.records.isNotEmpty
        ? widget.records.map((obj) => obj.value).reduce((a, b) => a > b ? a : b)
        : 0;
    List<FlSpot> allSpots = generateSpots(widget.records, maxX);
    final gradient =
        GradientData([0, 0.55, 0.7], gradientColors); // The base gradient
    final newGradient = gradient.getConstrainedGradient(
      GraphHelper().findMinValue(allSpots),
      GraphHelper().findMaxValue(allSpots),
      0,
      12,
    );
    // final belowGradient = gradient.getConstrainedGradient(
    //     GraphHelper().findMinValue(allSpots),
    //     GraphHelper().findMaxValue(allSpots),
    //     0,
    //     12,
    //     opacity: 0.1);

    return LineChartData(
      lineTouchData: LineTouchData(
        getTouchedSpotIndicator:
            (LineChartBarData barData, List<int> spotIndexes) {
          return spotIndexes.map((spotIndex) {
            return TouchedSpotIndicatorData(
              const FlLine(
                color: Color(0xff37434d),
                strokeWidth: 2,
              ),
              FlDotData(
                getDotPainter: (spot, percent, barData, index) {
                  return FlDotCirclePainter(
                    radius: 8,
                    color: AppColors.contentColorBlue,
                    strokeWidth: 0,
                  );
                },
              ),
            );
          }).toList();
        },
      ),
      gridData: FlGridData(
        show: true,
        drawHorizontalLine: true,
        verticalInterval: 2,
        horizontalInterval: (maxY / 10).ceil() + 1,
        getDrawingVerticalLine: (value) {
          return const FlLine(
            color: Color(0xff37434d),
            strokeWidth: 1,
          );
        },
        getDrawingHorizontalLine: (value) {
          return const FlLine(
            color: Color(0xff37434d),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 25,
              interval: 1,
              getTitlesWidget: bottomTitleWidgets,
            ),
            axisNameWidget: const Text('Days')),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: (maxY / 10).ceil() + 1,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 30,
          ),
          axisNameWidget: const Text('mg/dL'),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d)),
      ),
      minX: 1,
      maxX: maxX,
      minY: 0,
      maxY: maxY + (maxY * 0.1),
      lineBarsData: [
        LineChartBarData(
          spots: allSpots,
          isCurved: true,
          gradient: LinearGradient(
            // These values assume a top-to-bottom gradient, so reverse if desired
            begin: const Alignment(0, 1), // Top-center
            end: const Alignment(0, -1), // Bottom-center
            stops: newGradient.stops,
            colors: newGradient.colors,
          ),
          barWidth: 3,
          isStrokeCapRound: true,
          preventCurveOverShooting: true,
          dotData: FlDotData(
            show: false,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
              radius: 5,
              color: Colors.blue, // Change dot color here
              strokeWidth: 0,
              strokeColor: Colors.transparent,
            ),
          ),
          belowBarData: BarAreaData(
              show: true, color: AppColors.contentColorBlue.withOpacity(0.3)),
        ),
      ],
    );
  }

  List<FlSpot> generateSpots(List<GlucoseRecord> records, double maxX) {
    List<FlSpot> results = [];
    records.sort((a, b) => a.date.compareTo(b.date));
    for (var i = 1; i <= maxX; i++) {
      if (records.length >= i) {
        results.add(FlSpot(i.toDouble(), records[i - 1].value));
      } else {
        results.add(FlSpot(i.toDouble(), 0));
      }
    }
    return results;
  }
}

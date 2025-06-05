import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:glucolook/models/glucose_record.model.dart';
import 'package:glucolook/services/color_generator.services.dart';
import 'package:intl/intl.dart';

class LineChartGraph extends StatefulWidget {
  final List<GlucoseRecord> records;
  final ValueChanged<int>? onSpotTapped;
  const LineChartGraph({super.key, required this.records, this.onSpotTapped});

  @override
  State<LineChartGraph> createState() => _LineChartGraphState();
}

class _LineChartGraphState extends State<LineChartGraph> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(covariant LineChartGraph oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Scroll to end if records changed
    if (widget.records.length != oldWidget.records.length) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
        }
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // Scroll to end after first build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final records = List<GlucoseRecord>.from(widget.records)
      ..sort((a, b) => a.date.compareTo(b.date));

    if (records.isEmpty) {
      return const SizedBox.shrink();
    }

    Color getColorForValue(double value) {
      // colorRanges must be sorted by value ascending
      for (final metric in colorRanges) {
        if (value <= metric.value) {
          return metric.color;
        }
      }
      return colorRanges.last.color;
    }

    final List<Color> fillColors = [
      for (final record in records)
        getColorForValue(record.value).withOpacity(0.18),
    ];

    List<double> colorStops = [];
    if (fillColors.length == 1) {
      colorStops = [0.0, 1.0];
    } else {
      colorStops = List.generate(
        fillColors.length,
        (i) => i / (fillColors.length - 1),
      );
    }

    final minY =
        (records.map((e) => e.value).reduce((a, b) => a < b ? a : b) - 10);
    final minYClamped = minY < 0 ? 0.0 : minY;
    final maxY =
        records.map((e) => e.value).reduce((a, b) => a > b ? a : b) * 1.35;

    double getDynamicInterval(double min, double max) {
      final range = max - min;
      if (range <= 50) return 10;
      if (range <= 100) return 20;
      if (range <= 200) return 40;
      if (range <= 300) return 60;
      return (range / 5).roundToDouble();
    }

    final double yInterval = getDynamicInterval(minYClamped, maxY);

    List<double> yLabels = [];
    for (double y = minYClamped; y <= maxY; y += yInterval) {
      yLabels.add(y);
    }
    yLabels = yLabels.reversed.toList();

    final double chartWidth =
        ((records.length + 1) * 60 + 40).toDouble().clamp(300, 10000);

    // Find the lowest and highest value in your records
    final minValue =
        records.map((e) => e.value).reduce((a, b) => a < b ? a : b);
    final maxValue =
        records.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    // Get the color for the lowest and highest value using your color mapping
    final Color minColor = getColorForValue(minValue).withOpacity(0.25);
    final Color maxColor = getColorForValue(maxValue).withOpacity(0.35);

    return AspectRatio(
      aspectRatio: 1.7,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Fixed Y-axis labels
            Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: yLabels.map((y) {
                return SizedBox(
                  height: 24,
                  child: Text(
                    y.toInt().toString(),
                    style: const TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(width: 4),
            // Scrollable chart without Y-axis labels
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const SizedBox(width: 20),
                    SizedBox(
                      width: chartWidth,
                      child: LineChart(
                        LineChartData(
                          minY: minYClamped,
                          maxY: maxY,
                          minX: 0,
                          maxX: records.length.toDouble(),
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: yInterval,
                            getDrawingHorizontalLine: (value) => FlLine(
                              color: Colors.grey.withOpacity(0.15),
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: (records.length > 1)
                                    ? (records.length / 4).ceilToDouble()
                                    : 1,
                                getTitlesWidget: (value, meta) {
                                  int idx = value.toInt();
                                  if (idx < 0 || idx >= records.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final date = records[idx].date;
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8),
                                    child: Text(
                                      DateFormat('MM/dd').format(date),
                                      style: const TextStyle(
                                        color: Colors.black54,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w400,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          borderData: FlBorderData(
                            show: false,
                          ),
                          lineBarsData: [
                            LineChartBarData(
                              spots: [
                                for (int i = 0; i < records.length; i++)
                                  FlSpot(i.toDouble(), records[i].value)
                              ],
                              isCurved: true,
                              barWidth: 3,
                              isStrokeCapRound: true,
                              gradient: LinearGradient(
                                colors: [
                                  for (final record in records)
                                    getColorForValue(record.value)
                                ],
                                stops: colorStops,
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                gradient: LinearGradient(
                                  colors: [
                                    minColor,
                                    maxColor,
                                  ],
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                ),
                              ),
                              dotData: FlDotData(
                                show: true,
                                checkToShowDot: (spot, barData) => true,
                              ),
                              shadow: const Shadow(
                                color: Colors.black26,
                                blurRadius: 4,
                                offset: Offset(2, 2),
                              ),
                            ),
                          ],
                          lineTouchData: LineTouchData(
                            touchCallback: (event, response) {
                              if (event is FlTapUpEvent &&
                                  response != null &&
                                  response.lineBarSpots != null &&
                                  response.lineBarSpots!.isNotEmpty) {
                                final idx =
                                    response.lineBarSpots!.first.x.toInt();
                                if (widget.onSpotTapped != null &&
                                    idx >= 0 &&
                                    idx < widget.records.length) {
                                  widget.onSpotTapped!(idx);
                                }
                              }
                            },
                          ),
                        ),
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
}

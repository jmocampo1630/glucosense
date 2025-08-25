import 'dart:io';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:glucolook/models/glucose_record.model.dart';
import 'package:glucolook/models/patient.model.dart';
import 'package:glucolook/services/color_generator.services.dart';

class PdfExportService {
  static Future<File> generateGlucoseRecordsPdf({
    required List<GlucoseRecord> records,
    required DateTime startDate,
    required DateTime endDate,
    Patient? patient,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('MMM dd, yyyy');
    final reportDate = DateFormat('MMMM dd, yyyy').format(DateTime.now());

    // Calculate statistics
    final stats = _calculateStatistics(records);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(patient),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          // Title and Date Range
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(
                  'Glucose Records Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.teal700,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '${dateFormat.format(startDate)} - ${dateFormat.format(endDate)}',
                  style: const pw.TextStyle(
                    fontSize: 16,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.Text(
                  'Generated on $reportDate',
                  style: const pw.TextStyle(
                    fontSize: 12,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
          pw.SizedBox(height: 24),

          // Statistics Summary
          _buildStatisticsSection(stats),
          pw.SizedBox(height: 24),

          // Records Table
          _buildRecordsTable(records),

          pw.SizedBox(height: 24),

          // Level Distribution Chart (text-based)
          _buildLevelDistribution(records),
        ],
      ),
    );

    // Save PDF to device
    final directory = await getApplicationDocumentsDirectory();
    final fileName =
        'glucose_records_${dateFormat.format(startDate).replaceAll(' ', '_')}_to_${dateFormat.format(endDate).replaceAll(' ', '_')}.pdf';
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static Map<String, dynamic> _calculateStatistics(
      List<GlucoseRecord> records) {
    if (records.isEmpty) {
      return {
        'count': 0,
        'average': 0.0,
        'highest': 0.0,
        'lowest': 0.0,
        'levelDistribution': <String, int>{},
      };
    }

    final values = records.map((r) => r.value).toList();
    final average = values.reduce((a, b) => a + b) / values.length;
    final highest = values.reduce((a, b) => a > b ? a : b);
    final lowest = values.reduce((a, b) => a < b ? a : b);

    // Group records by their glucose level names from colorRanges
    Map<String, int> levelDistribution = {};

    for (final record in records) {
      String levelName =
          record.name; // Use the actual glucose level name from the record
      levelDistribution[levelName] = (levelDistribution[levelName] ?? 0) + 1;
    }

    return {
      'count': records.length,
      'average': average,
      'highest': highest,
      'lowest': lowest,
      'levelDistribution': levelDistribution,
    };
  }

  static pw.Widget _buildHeader(Patient? patient) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(
            color: PdfColors.teal700,
            width: 2,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'GlucoSense',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal700,
            ),
          ),
          if (patient != null)
            pw.Text(
              patient.name,
              style: const pw.TextStyle(
                fontSize: 14,
                color: PdfColors.grey700,
              ),
            ),
        ],
      ),
    );
  }

  static pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(
            color: PdfColors.grey400,
            width: 1,
          ),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by GlucoSense App',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildStatisticsSection(Map<String, dynamic> stats) {
    final levelDistribution = stats['levelDistribution'] as Map<String, int>;
    final topLevels = levelDistribution.entries.take(3).toList();

    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Summary Statistics',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.teal700,
            ),
          ),
          pw.SizedBox(height: 16),

          // Main statistics in a 2x2 grid
          pw.Row(
            children: [
              pw.Expanded(
                child: _buildCompactStatCard(
                    'Total Records', '${stats['count']}', PdfColors.blue700),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildCompactStatCard(
                    'Average',
                    '${stats['average'].toStringAsFixed(1)} mg/dL',
                    PdfColors.green700),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildCompactStatCard(
                    'Highest',
                    '${stats['highest'].toStringAsFixed(1)} mg/dL',
                    PdfColors.red700),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: _buildCompactStatCard(
                    'Lowest',
                    '${stats['lowest'].toStringAsFixed(1)} mg/dL',
                    PdfColors.orange700),
              ),
            ],
          ),

          // Top glucose levels if available
          if (topLevels.isNotEmpty) ...[
            pw.SizedBox(height: 16),
            pw.Text(
              'Most Common Levels',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.teal700,
              ),
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              children: topLevels.asMap().entries.map((entry) {
                if (entry.key < topLevels.length - 1) {
                  return pw.Expanded(
                    child: pw.Row(
                      children: [
                        pw.Expanded(
                          child: _buildCompactLevelCard(
                              entry.value.key, entry.value.value),
                        ),
                        pw.SizedBox(width: 8),
                      ],
                    ),
                  );
                } else {
                  return pw.Expanded(
                    child: _buildCompactLevelCard(
                        entry.value.key, entry.value.value),
                  );
                }
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }

  static pw.Widget _buildCompactStatCard(
      String label, String value, PdfColor accentColor) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(6),
        border: pw.Border.all(color: accentColor, width: 1),
      ),
      child: pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: accentColor,
            ),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            label,
            style: const pw.TextStyle(
              fontSize: 10,
              color: PdfColors.grey600,
            ),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildCompactLevelCard(String levelName, int count) {
    // Get color from colorRanges based on the level name
    PdfColor displayColor = _getColorForLevel(levelName);

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(4),
        border: pw.Border.all(color: displayColor, width: 1),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.center,
        children: [
          pw.Container(
            width: 8,
            height: 8,
            decoration: pw.BoxDecoration(
              color: displayColor,
              borderRadius: pw.BorderRadius.circular(4),
            ),
          ),
          pw.SizedBox(width: 6),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  levelName,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: displayColor,
                  ),
                ),
                pw.Text(
                  '$count records',
                  style: const pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildRecordsTable(List<GlucoseRecord> records) {
    final dateFormat = DateFormat('MMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Detailed Records',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.teal700,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400),
          columnWidths: {
            0: const pw.FlexColumnWidth(2),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1),
            4: const pw.FlexColumnWidth(2),
          },
          children: [
            // Header
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.teal700),
              children: [
                _buildTableCell('Date & Time', isHeader: true),
                _buildTableCell('Level', isHeader: true),
                _buildTableCell('Value (mg/dL)', isHeader: true),
                _buildTableCell('Status', isHeader: true),
                _buildTableCell('Tags', isHeader: true),
              ],
            ),
            // Data rows
            ...records.map((record) {
              String status = 'Normal';
              if (record.value < 70) {
                status = 'Low';
              } else if (record.value > 140) {
                status = 'High';
              }

              return pw.TableRow(
                children: [
                  _buildTableCell(
                      '${dateFormat.format(record.date)}\n${timeFormat.format(record.date)}'),
                  _buildTableCell(record.name),
                  _buildTableCell(record.value.toStringAsFixed(1)),
                  _buildTableCell(status),
                  _buildTableCell(record.tags.join(', ')),
                ],
              );
            }),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 12 : 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }

  static pw.Widget _buildLevelDistribution(List<GlucoseRecord> records) {
    final stats = _calculateStatistics(records);
    final total = stats['count'] as int;
    final levelDistribution = stats['levelDistribution'] as Map<String, int>;

    if (total == 0) return pw.SizedBox();

    // Sort level distribution by count (descending)
    final sortedDistribution = levelDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Glucose Level Distribution',
          style: pw.TextStyle(
            fontSize: 18,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.teal700,
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            children: sortedDistribution.map((entry) {
              final percent = ((entry.value / total) * 100).round();

              // Get color from colorRanges based on the level name
              PdfColor displayColor = _getColorForLevel(entry.key);

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 8),
                child: _buildDistributionRow(
                    entry.key, entry.value, percent, displayColor),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // Helper method to get PDF color based on glucose level name
  static PdfColor _getColorForLevel(String levelName) {
    // Find the colorRange that matches this level name
    final colorRange = colorRanges.firstWhere(
      (range) => range.name == levelName,
      orElse: () => colorRanges.first,
    );

    // Convert Flutter Color to PdfColor
    final color = colorRange.color;
    return PdfColor.fromInt(color.value);
  }

  static pw.Widget _buildDistributionRow(
      String label, int count, int percent, PdfColor color) {
    return pw.Row(
      children: [
        pw.Container(
          width: 16,
          height: 16,
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: pw.BorderRadius.circular(2),
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Expanded(
          child: pw.Text(
            '$label: $count records ($percent%)',
            style: const pw.TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}

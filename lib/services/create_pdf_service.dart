import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class PdfService {
  static Future<File> generateAnalysisReport({
    required File imageFile,
    required String analysis,
    required String scanType,
  }) async {
    final pdf = pw.Document();
    final imageBytes = await imageFile.readAsBytes();
    final image = pw.MemoryImage(imageBytes);

    // Parse analysis text for formatting
    final formattedContent = _parseAnalysisText(analysis);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(32),
        build: (context) => [
          // Header
          pw.Container(
            padding: pw.EdgeInsets.only(bottom: 20),
            decoration: pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(
                  color: PdfColors.blue700,
                  width: 2,
                ),
              ),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'MedScan AI Analysis Report',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Scan Type: $scanType',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                    pw.Text(
                      'Date: ${DateFormat('MMM dd, yyyy - HH:mm').format(DateTime.now())}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.grey700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 20),

          // Image Section
          pw.Container(
            padding: pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey300, width: 1),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Uploaded Scan Image',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Center(
                  child: pw.Container(
                    constraints: pw.BoxConstraints(
                      maxHeight: 300,
                      maxWidth: 400,
                    ),
                    child: pw.Image(image),
                  ),
                ),
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Analysis Section
          pw.Container(
            padding: pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              border: pw.Border.all(color: PdfColors.blue200, width: 1),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 4,
                      height: 20,
                      color: PdfColors.blue700,
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      'AI Analysis Report',
                      style: pw.TextStyle(
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.blue900,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Powered by Gemini AI',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
                pw.SizedBox(height: 16),
                pw.Divider(color: PdfColors.blue200),
                pw.SizedBox(height: 12),
                ...formattedContent,
              ],
            ),
          ),

          pw.SizedBox(height: 24),

          // Disclaimer
          pw.Container(
            padding: pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: PdfColors.orange50,
              border: pw.Border.all(color: PdfColors.orange300, width: 1),
              borderRadius: pw.BorderRadius.circular(8),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Text(
                      '⚠️ ',
                      style: pw.TextStyle(fontSize: 16),
                    ),
                    pw.Text(
                      'Medical Disclaimer',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange900,
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'This AI-generated analysis is for educational purposes only. '
                      'Always consult qualified healthcare professionals for proper medical '
                      'diagnosis and treatment. This report should not be used as a substitute '
                      'for professional medical advice.',
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey800,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),

          // Footer
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Center(
            child: pw.Text(
              'Generated by MedScan - AI Medical Image Analysis',
              style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.grey600,
              ),
            ),
          ),
        ],
      ),
    );

    // Save PDF to temporary directory
    final output = await getTemporaryDirectory();
    final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
    final file = File('${output.path}/medscan_report_$timestamp.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  static List<pw.Widget> _parseAnalysisText(String text) {
    final widgets = <pw.Widget>[];
    final lines = text.split('\n');

    for (var line in lines) {
      if (line.trim().isEmpty) {
        widgets.add(pw.SizedBox(height: 8));
        continue;
      }

      // Check for headings (##)
      if (line.startsWith('##')) {
        final headingText = line.replaceFirst(RegExp(r'^#+\s*'), '');
        widgets.add(pw.SizedBox(height: 12));
        widgets.add(
          pw.Text(
            headingText,
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue900,
            ),
          ),
        );
        widgets.add(pw.SizedBox(height: 8));
        continue;
      }

      // Parse bold text (***text***)
      final spans = <pw.InlineSpan>[];
      final boldPattern = RegExp(r'\*\*\*?(.*?)\*\*\*?');
      int currentIndex = 0;

      for (final match in boldPattern.allMatches(line)) {
        // Add normal text before bold
        if (match.start > currentIndex) {
          spans.add(
            pw.TextSpan(
              text: line.substring(currentIndex, match.start),
              style: pw.TextStyle(fontSize: 11, height: 1.5),
            ),
          );
        }

        // Add bold text
        spans.add(
          pw.TextSpan(
            text: match.group(1),
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              height: 1.5,
            ),
          ),
        );

        currentIndex = match.end;
      }

      // Add remaining text
      if (currentIndex < line.length) {
        spans.add(
          pw.TextSpan(
            text: line.substring(currentIndex),
            style: pw.TextStyle(fontSize: 11, height: 1.5),
          ),
        );
      }

      if (spans.isNotEmpty) {
        widgets.add(
          pw.RichText(
            text: pw.TextSpan(children: spans),
          ),
        );
        widgets.add(pw.SizedBox(height: 6));
      }
    }

    return widgets;
  }
}

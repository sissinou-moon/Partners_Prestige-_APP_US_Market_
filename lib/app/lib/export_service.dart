import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Service to export table data to CSV, PDF, and HTML formats
class ExportService {
  /// Get the downloads/documents directory for saving files
  static Future<Directory> _getExportDirectory() async {
    // Try to get downloads directory first (Android), fallback to documents
    try {
      if (Platform.isAndroid) {
        final dir = await getExternalStorageDirectory();
        if (dir != null) {
          final exportDir = Directory('${dir.path}/PrestigePartners/Exports');
          if (!await exportDir.exists()) {
            await exportDir.create(recursive: true);
          }
          return exportDir;
        }
      }
    } catch (_) {}

    // Fallback to application documents directory
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${dir.path}/Exports');
    if (!await exportDir.exists()) {
      await exportDir.create(recursive: true);
    }
    return exportDir;
  }

  /// Export data to CSV file
  static Future<String?> exportToCsv({
    required List<String> headers,
    required List<List<String>> rows,
    required String fileName,
  }) async {
    try {
      // Build CSV content
      final buffer = StringBuffer();

      // Add headers
      buffer.writeln(headers.map((h) => _escapeCsvField(h)).join(','));

      // Add rows
      for (final row in rows) {
        buffer.writeln(row.map((cell) => _escapeCsvField(cell)).join(','));
      }

      // Get export directory
      final directory = await _getExportDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/${fileName}_$timestamp.csv';

      // Write file
      final file = File(filePath);
      await file.writeAsString(buffer.toString());

      print('📄 CSV exported to: $filePath');
      return filePath;
    } catch (e) {
      print('Error exporting to CSV: $e');
      return null;
    }
  }

  /// Export data to PDF file
  static Future<String?> exportToPdf({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    required String fileName,
  }) async {
    try {
      final pdf = pw.Document();

      // Create PDF content
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(32),
          header: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                title,
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Generated on ${DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(
                  fontSize: 10,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 8),
            ],
          ),
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            margin: const pw.EdgeInsets.only(top: 16),
            child: pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount} | Prestige Partners',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
            ),
          ),
          build: (context) => [
            pw.TableHelper.fromTextArray(
              context: context,
              headers: headers,
              data: rows,
              headerStyle: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.white,
                fontSize: 10,
              ),
              headerDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFF00D4AA),
              ),
              cellStyle: const pw.TextStyle(fontSize: 9),
              cellPadding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 6,
              ),
              cellAlignment: pw.Alignment.centerLeft,
              headerAlignment: pw.Alignment.centerLeft,
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              oddRowDecoration: const pw.BoxDecoration(
                color: PdfColor.fromInt(0xFFF9F9F9),
              ),
            ),
            pw.SizedBox(height: 16),
            pw.Text(
              'Total records: ${rows.length}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ],
        ),
      );

      // Get export directory
      final directory = await _getExportDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/${fileName}_$timestamp.pdf';

      // Write file
      final file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      print('📄 PDF exported to: $filePath');
      return filePath;
    } catch (e) {
      print('Error exporting to PDF: $e');
      return null;
    }
  }

  /// Export data to HTML file (print-ready format)
  static Future<String?> exportToHtml({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    required String fileName,
  }) async {
    try {
      final buffer = StringBuffer();

      buffer.writeln('''
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>$title</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; }
    h1 { color: #1A1A1A; font-size: 24px; margin-bottom: 10px; }
    .subtitle { color: #666; font-size: 14px; margin-bottom: 20px; }
    table { width: 100%; border-collapse: collapse; font-size: 12px; }
    th { background-color: #00D4AA; color: white; padding: 12px 8px; text-align: left; }
    td { padding: 10px 8px; border-bottom: 1px solid #eee; }
    tr:nth-child(even) { background-color: #f9f9f9; }
    .footer { margin-top: 20px; font-size: 11px; color: #999; }
    @media print {
      body { margin: 0; }
      .no-print { display: none; }
    }
  </style>
</head>
<body>
  <h1>$title</h1>
  <p class="subtitle">Generated on ${DateFormat('MMMM dd, yyyy HH:mm').format(DateTime.now())}</p>
  <table>
    <thead>
      <tr>
''');

      // Add headers
      for (final header in headers) {
        buffer.writeln('        <th>$header</th>');
      }

      buffer.writeln('''
      </tr>
    </thead>
    <tbody>
''');

      // Add rows
      for (final row in rows) {
        buffer.writeln('      <tr>');
        for (final cell in row) {
          buffer.writeln('        <td>${_escapeHtml(cell)}</td>');
        }
        buffer.writeln('      </tr>');
      }

      buffer.writeln('''
    </tbody>
  </table>
  <p class="footer">Total records: ${rows.length} | Exported from Prestige Partners</p>
</body>
</html>
''');

      // Get export directory
      final directory = await _getExportDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filePath = '${directory.path}/${fileName}_$timestamp.html';

      // Write file
      final file = File(filePath);
      await file.writeAsString(buffer.toString());

      print('📄 HTML exported to: $filePath');
      return filePath;
    } catch (e) {
      print('Error exporting to HTML: $e');
      return null;
    }
  }

  /// Copy to clipboard as text
  static Future<void> copyToClipboard({
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    final buffer = StringBuffer();

    // Add headers
    buffer.writeln(headers.join('\t'));

    // Add rows
    for (final row in rows) {
      buffer.writeln(row.join('\t'));
    }

    await Clipboard.setData(ClipboardData(text: buffer.toString()));
  }

  /// Escape CSV field (handle commas, quotes, newlines)
  static String _escapeCsvField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Escape HTML special characters
  static String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#39;');
  }
}

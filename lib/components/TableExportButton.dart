import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:line_icons/line_icons.dart';
import 'package:share_plus/share_plus.dart';
import 'package:open_filex/open_filex.dart';

import '../app/lib/export_service.dart';

/// Reusable export button widget for tables
class TableExportButton extends StatefulWidget {
  final List<String> headers;
  final List<List<String>> Function() getRows;
  final String fileName;
  final String reportTitle;
  final bool hasData;

  const TableExportButton({
    super.key,
    required this.headers,
    required this.getRows,
    required this.fileName,
    required this.reportTitle,
    this.hasData = true,
  });

  @override
  State<TableExportButton> createState() => _TableExportButtonState();
}

class _TableExportButtonState extends State<TableExportButton> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      enabled: widget.hasData,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: widget.hasData
              ? const Color(0xFF6366F1).withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isExporting)
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFF6366F1),
                ),
              )
            else
              Icon(
                LineIcons.download,
                color: widget.hasData
                    ? const Color(0xFF6366F1)
                    : Colors.grey[400],
                size: 18,
              ),
            const SizedBox(width: 6),
            Text(
              'Export',
              style: TextStyle(
                color: widget.hasData
                    ? const Color(0xFF6366F1)
                    : Colors.grey[400],
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      onSelected: _handleExport,
      itemBuilder: (context) => [
        _buildExportMenuItem(
          icon: LineIcons.file,
          title: 'Export as CSV',
          subtitle: 'Spreadsheet format',
          value: 'csv',
        ),
        _buildExportMenuItem(
          icon: LineIcons.fileContract,
          title: 'Export as PDF',
          subtitle: 'Portable document',
          value: 'pdf',
        ),
        _buildExportMenuItem(
          icon: LineIcons.code,
          title: 'Export as HTML',
          subtitle: 'Web/print format',
          value: 'html',
        ),
        const PopupMenuDivider(),
        _buildExportMenuItem(
          icon: LineIcons.copy,
          title: 'Copy to Clipboard',
          subtitle: 'Tab-separated text',
          value: 'clipboard',
        ),
      ],
    );
  }

  PopupMenuItem<String> _buildExportMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF6366F1), size: 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1A1A1A),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleExport(String format) async {
    if (!widget.hasData) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    setState(() => _isExporting = true);
    HapticFeedback.lightImpact();

    try {
      final rows = widget.getRows();

      String? filePath;
      String message = '';
      String fileType = '';

      switch (format) {
        case 'csv':
          filePath = await ExportService.exportToCsv(
            headers: widget.headers,
            rows: rows,
            fileName: widget.fileName,
          );
          message = 'CSV file saved successfully';
          fileType = 'CSV';
          break;
        case 'pdf':
          filePath = await ExportService.exportToPdf(
            title: widget.reportTitle,
            headers: widget.headers,
            rows: rows,
            fileName: widget.fileName,
          );
          message = 'PDF file saved successfully';
          fileType = 'PDF';
          break;
        case 'html':
          filePath = await ExportService.exportToHtml(
            title: widget.reportTitle,
            headers: widget.headers,
            rows: rows,
            fileName: widget.fileName,
          );
          message = 'HTML file saved successfully';
          fileType = 'HTML';
          break;
        case 'clipboard':
          await ExportService.copyToClipboard(
            headers: widget.headers,
            rows: rows,
          );
          message = 'Data copied to clipboard';
          break;
      }

      if (mounted) {
        if (filePath != null) {
          _showExportSuccessDialog(filePath, message, fileType);
        } else if (format == 'clipboard') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(message),
                ],
              ),
              backgroundColor: const Color(0xFF00D4AA),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Export failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  void _showExportSuccessDialog(
    String filePath,
    String message,
    String fileType,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Success Icon
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF00D4AA).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF00D4AA),
                size: 36,
              ),
            ),
            const SizedBox(height: 20),

            // Title
            const Text(
              'Export Complete!',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),

            // Message
            Text(
              '$fileType file has been saved to your device',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),

            // File path
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                filePath.split('/').last,
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  color: Colors.grey[700],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      OpenFilex.open(filePath);
                    },
                    icon: const Icon(Icons.open_in_new, size: 18),
                    label: const Text('Open'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF6366F1),
                      side: const BorderSide(color: Color(0xFF6366F1)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      Share.shareXFiles([
                        XFile(filePath),
                      ], subject: widget.reportTitle);
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00D4AA),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Close button
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Close', style: TextStyle(color: Colors.grey[600])),
            ),
          ],
        ),
      ),
    );
  }
}

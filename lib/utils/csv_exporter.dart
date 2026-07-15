import 'file_saver.dart' as fs;

class CsvExporter {
  /// Exports a list of maps to a CSV file and triggers a download.
  static void exportToCsv({
    required List<String> headers,
    required List<List<dynamic>> rows,
    required String fileName,
  }) {
    // Construct CSV content
    String csv = headers.map((h) => '"$h"').join(',') + '\n';
    
    for (final row in rows) {
      csv += row.map((v) {
        if (v == null) return '""';
        // Escape quotes and wrap in quotes
        String str = v.toString().replaceAll('"', '""');
        return '"$str"';
      }).join(',') + '\n';
    }

    try {
      fs.saveFile(
        content: csv,
        fileName: '$fileName.csv',
        mimeType: 'text/csv',
      );
    } catch (e) {
      // Handle platforms that don't support file saving (e.g. mobile/desktop if not implemented)
      print('CSV Export failed: $e');
    }
  }
}

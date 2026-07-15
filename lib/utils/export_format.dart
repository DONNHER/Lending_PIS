class ExportFormatInfo {
  final String format;
  final String extension;
  final String mimeType;
  final String displayName;

  const ExportFormatInfo({
    required this.format,
    required this.extension,
    required this.mimeType,
    required this.displayName,
  });

  static ExportFormatInfo forFormat(String? format) {
    final normalized = (format ?? 'csv').toLowerCase();

    switch (normalized) {
      case 'xlsx':
        return const ExportFormatInfo(
          format: 'xlsx',
          extension: '.xlsx',
          mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          displayName: 'Excel',
        );
      case 'csv':
        return const ExportFormatInfo(
          format: 'csv',
          extension: '.csv',
          mimeType: 'text/csv',
          displayName: 'CSV',
        );
      case 'pdf':
        return const ExportFormatInfo(
          format: 'pdf',
          extension: '.pdf',
          mimeType: 'application/pdf',
          displayName: 'PDF',
        );
      default:
        return const ExportFormatInfo(
          format: 'csv',
          extension: '.csv',
          mimeType: 'text/csv',
          displayName: 'CSV',
        );
    }
  }
}

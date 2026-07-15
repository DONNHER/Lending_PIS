import 'package:capstone_application/utils/export_format.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExportFormatInfo', () {
    test('returns the right metadata for supported formats', () {
      expect(ExportFormatInfo.forFormat('xlsx').extension, '.xlsx');
      expect(ExportFormatInfo.forFormat('xlsx').mimeType, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      expect(ExportFormatInfo.forFormat('csv').displayName, 'CSV');
      expect(ExportFormatInfo.forFormat('pdf').extension, '.pdf');
    });

    test('falls back to csv for unsupported formats', () {
      final info = ExportFormatInfo.forFormat('unknown');
      expect(info.extension, '.csv');
      expect(info.mimeType, 'text/csv');
      expect(info.displayName, 'CSV');
    });
  });
}

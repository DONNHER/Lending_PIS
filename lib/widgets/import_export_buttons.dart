import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/import_export_viewmodel.dart';

class ImportExportButtons extends StatelessWidget {
  final String type;
  final VoidCallback onRefresh;

  const ImportExportButtons({
    super.key,
    required this.type,
    required this.onRefresh,
  });
  @override
  Widget build(BuildContext context) {
    return Consumer<ImportExportViewModel>(
      builder: (context, viewModel, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // EXPORT BUTTON (ARROW UP)
            ElevatedButton.icon(
              onPressed: viewModel.isExporting
                  ? null
                  : () => _showExportFormatDialog(context, viewModel),
              icon: viewModel.isExporting
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.upload_rounded, size: 18), // SWAPPED TO UPLOAD ARROW
              label: const Text('Export'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC06C4D),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                minimumSize: const Size(0, 40),
              ),
            ),
            const SizedBox(width: 12),

            // BULK IMPORT BUTTON (ARROW DOWN)
            ElevatedButton.icon(
              onPressed: viewModel.isImporting
                  ? null
                  : () async {
                final success = await viewModel.previewImport(type);
                if (success && context.mounted) {
                  _showImportPreviewDialog(context, viewModel);
                }
              },
              icon: viewModel.isImporting
                  ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
                  : const Icon(Icons.download_rounded, size: 18), // SWAPPED TO DOWNLOAD ARROW
              label: const Text('Bulk Import'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFA726), // Yellow accent palette background color
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
                minimumSize: const Size(0, 40),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showExportFormatDialog(BuildContext context, ImportExportViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Data ($type)'),
        content: const Text('Select your preferred file conversion framework:'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.exportData(type, 'xlsx');
            },
            child: const Text('Excel (.xlsx)'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.exportData(type, 'csv');
            },
            child: const Text('CSV (.csv)'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              viewModel.exportData(type, 'pdf');
            },
            child: const Text('PDF (.pdf)'),
          ),
        ],
      ),
    );
  }

  void _showImportPreviewDialog(BuildContext context, ImportExportViewModel viewModel) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Import Matrix Preview'),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Total Extracted Rows: ${viewModel.previewData?['total_rows'] ?? 0}'),
              Text('Valid Structural Target Rows: ${viewModel.previewData?['valid_rows'] ?? 0}'),
              Text('Error Row Intersections: ${viewModel.previewData?['error_rows'] ?? 0}',
                  style: TextStyle(color: viewModel.errors.isNotEmpty ? Colors.red : Colors.black)),
              if (viewModel.duplicates.isNotEmpty)
                Text('Duplicate Flags Isolated: ${viewModel.duplicates.length}', style: const TextStyle(color: Colors.orange)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              viewModel.clearPreview();
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              final status = await viewModel.confirmImport(type, '');
              if (status) {
                onRefresh();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC06C4D)),
            child: const Text('Confirm Commit'),
          ),
        ],
      ),
    );
  }
}
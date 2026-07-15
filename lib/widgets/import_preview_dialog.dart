import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/import_export_viewmodel.dart';
import '../app_theme.dart';

class ImportPreviewDialog extends StatelessWidget {
  final String type;
  final String filePath;
  final VoidCallback onComplete;

  const ImportPreviewDialog({
    super.key,
    required this.type,
    required this.filePath,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<ImportExportViewModel>();
    final data = viewModel.previewData;

    if (data == null) return const SizedBox.shrink();

    final int total = data['total_rows'] ?? 0;
    final int valid = data['valid_rows'] ?? 0;
    final int errorRows = data['error_rows'] ?? 0;
    final int duplicateRows = (data['duplicates'] as List?)?.length ?? 0;

    return AlertDialog(
      title: Text('Import Preview: ${type.toUpperCase()}'),
      content: SizedBox(
        width: 600,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStat('Total', total.toString(), Colors.blue),
                _buildStat('Valid', valid.toString(), Colors.green),
                _buildStat('Errors', errorRows.toString(), Colors.red),
                _buildStat('Duplicates', duplicateRows.toString(), Colors.orange),
              ],
            ),
            const SizedBox(height: 24),
            if (viewModel.isProcessing)
              const Column(
                children: [
                  LinearProgressIndicator(color: AppTheme.primary),
                  SizedBox(height: 8),
                  Text('Processing import...', style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
                ],
              ),
            if (!viewModel.isProcessing && viewModel.lastImportMessage != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(viewModel.lastImportMessage!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildMiniStat('Imported', viewModel.importedCount.toString(), Colors.green),
                        const SizedBox(width: 16),
                        _buildMiniStat('Failed', viewModel.failedCount.toString(), Colors.red),
                      ],
                    ),
                  ],
                ),
              ),
            if (!viewModel.isProcessing && (viewModel.errors.isNotEmpty || viewModel.duplicates.isNotEmpty))
              Flexible(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 200),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        if (viewModel.errors.isNotEmpty) ...[
                          const Text('Validation Errors:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          ...viewModel.errors.map((e) => Text('• Row ${e['row']}: ${e['messages'].join(', ')}', style: const TextStyle(fontSize: 12))),
                          const SizedBox(height: 12),
                        ],
                        if (viewModel.duplicates.isNotEmpty) ...[
                          const Text('Duplicates Found:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                          ...viewModel.duplicates.map((e) => Text('• Row ${e['row']}: ${e['message']}', style: const TextStyle(fontSize: 12))),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: viewModel.isProcessing ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        if (errorRows > 0)
          TextButton(
            onPressed: viewModel.isProcessing ? null : viewModel.downloadErrorReport,
            child: const Text('Download Error Report', style: TextStyle(color: Colors.red)),
          ),
        ElevatedButton(
          onPressed: viewModel.isProcessing || valid == 0
              ? null
              : () async {
                  final success = await viewModel.confirmImport(type, filePath);
                  if (context.mounted) {
                    if (success) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Import completed: ${viewModel.importedCount} imported, ${viewModel.failedCount} failed'), backgroundColor: Colors.green),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Import failed. Please review the validation errors.'), backgroundColor: Colors.red),
                      );
                    }
                    onComplete();
                  }
                },
          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary),
          child: Text(valid == 0 ? 'No Valid Rows' : 'Confirm Import ($valid rows)'),
        ),
      ],
    );
  }

  Widget _buildStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      ],
    );
  }

  Widget _buildMiniStat(String label, String value, Color color) {
    return Row(
      children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: AppTheme.textMuted)),
      ],
    );
  }
}

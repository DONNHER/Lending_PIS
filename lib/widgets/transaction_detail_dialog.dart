import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_theme.dart';
import '../models/transaction_model.dart';

class TransactionDetailDialog extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailDialog({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(symbol: '₱ ');
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 30,
                offset: const Offset(0, 15),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header / Close button
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                        splashRadius: 24,
                      ),
                    ],
                  ),
                ),

                // Success Icon & Title
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, size: 40, color: Color(0xFF10B981)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Transaction Successful',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF10B981),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currencyFormat.format(transaction.amount),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Details Container
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    children: [
                      const Divider(height: 1, color: Color(0xFFF3F4F6)),
                      const SizedBox(height: 24),
                      _detailRow('Client Name', transaction.clientName),
                      _detailRow('Transaction Type', transaction.type),
                      _detailRow('Status', transaction.status),
                      _detailRow('Payment Method', transaction.method),
                      _detailRow('Date', dateFormat.format(transaction.date)),
                      _detailRow('Time', timeFormat.format(transaction.date)),
                      if (transaction.referenceId != null && transaction.referenceId!.isNotEmpty)
                        _detailRow('Reference ID', transaction.referenceId!),
                      _detailRow('Transaction ID', '#${transaction.id.substring(0, min(8, transaction.id.length))}...'),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),

                // Info Box
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9FAFB),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFF3F4F6)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded, size: 18, color: AppTheme.textMuted),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'This is a verified record of the ${transaction.type.toLowerCase()} processed by the system.',
                            style: const TextStyle(fontSize: 11, color: AppTheme.textMuted, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Actions
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () => _savePdf(context),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Save PDF', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC06C4D),
                          side: const BorderSide(color: Color(0xFFC06C4D)),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _printPdf(context),
                        icon: const Icon(Icons.print_rounded, size: 18),
                        label: const Text('Print', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC06C4D),
                          side: const BorderSide(color: Color(0xFFC06C4D)),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _sharePdf(context),
                        icon: const Icon(Icons.send_rounded, size: 18),
                        label: const Text('Email', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFC06C4D),
                          side: const BorderSide(color: Color(0xFFC06C4D)),
                          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC06C4D),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 18),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                        child: const Text('Dismiss', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int min(int a, int b) => a < b ? a : b;

  Future<pw.Document> _buildTransactionPdf() async {
    final document = pw.Document();
    final currencyFormat = NumberFormat.currency(symbol: '₱ ');
    final dateFormat = DateFormat('MMMM dd, yyyy');
    final timeFormat = DateFormat('hh:mm a');

    document.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context pdfContext) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(24),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Capstone Lending System', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                        pw.SizedBox(height: 4),
                        pw.Text('Professional transaction receipt', style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFF1F2937), borderRadius: pw.BorderRadius.all(pw.Radius.circular(8))),
                      child: pw.Text('TRANSACTION', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
                pw.SizedBox(height: 10),
                pw.Divider(thickness: 1),
                pw.SizedBox(height: 14),
                pw.Text('Transaction Details', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('Generated on ${DateFormat('MMMM dd, yyyy hh:mm a').format(DateTime.now())}'),
                pw.SizedBox(height: 18),
                pw.Text('Client Name: ${transaction.clientName}', style: const pw.TextStyle(fontSize: 12)),
                pw.Text('Transaction Type: ${transaction.type}', style: const pw.TextStyle(fontSize: 12)),
                pw.Text('Status: ${transaction.status}', style: const pw.TextStyle(fontSize: 12)),
                pw.Text('Payment Method: ${transaction.method}', style: const pw.TextStyle(fontSize: 12)),
                pw.Text('Date: ${dateFormat.format(transaction.date)}', style: const pw.TextStyle(fontSize: 12)),
                pw.Text('Time: ${timeFormat.format(transaction.date)}', style: const pw.TextStyle(fontSize: 12)),
                if (transaction.referenceId != null && transaction.referenceId!.isNotEmpty)
                  pw.Text('Reference ID: ${transaction.referenceId}', style: const pw.TextStyle(fontSize: 12)),
                pw.Text('Transaction ID: #${transaction.id.substring(0, min(transaction.id.length, 8))}...', style: const pw.TextStyle(fontSize: 12)),
                pw.SizedBox(height: 18),
                pw.Container(
                  padding: const pw.EdgeInsets.all(12),
                  decoration: pw.BoxDecoration(
                    color: const PdfColor.fromInt(0xFFF9FAFB),
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                  ),
                  child: pw.Text('Amount: ${currencyFormat.format(transaction.amount)}', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Confidential business document', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                    pw.Text('Page ${pdfContext.pageNumber}', style: pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return document;
  }

  Future<void> _savePdf(BuildContext context) async {
    final document = await _buildTransactionPdf();
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/transaction_${transaction.id}.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await document.save());

    if (!context.mounted) return;

    final uri = Uri.file(filePath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('PDF saved to ${file.path}')),
    );
  }

  Future<void> _printPdf(BuildContext context) async {
    final document = await _buildTransactionPdf();
    await Printing.layoutPdf(onLayout: (format) async => document.save());

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Print dialog opened for the PDF.')),
    );
  }

  Future<void> _sharePdf(BuildContext context) async {
    final document = await _buildTransactionPdf();
    final tempDir = await getTemporaryDirectory();
    final filePath = '${tempDir.path}/transaction_${transaction.id}_shared.pdf';
    final file = File(filePath);
    await file.writeAsBytes(await document.save());

    if (!context.mounted) return;

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Transaction PDF',
      text: 'Here is the transaction PDF generated from the Capstone app.',
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, color: AppTheme.textMuted, fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.textDark),
            ),
          ),
        ],
      ),
    );
  }
}

import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'time_tracking_service.dart';

class InvoicePdfService {
  static Future<Uint8List> generateInvoicePdf(InvoiceData data) async {
    final doc = pw.Document();
    final dateFmt = DateFormat('MMM d, y');
    final timeFmt = DateFormat('h:mm a');

    final headers = <String>['Date', 'Clock In', 'Clock Out', 'Hours', 'Rate', 'Amount'];

    final rows = <List<String>>[];
    for (final entry in data.entries) {
      final minutes = entry.duration ?? 0;
      final hours = minutes / 60.0;
      final amount = hours * data.hourlyRate;
      rows.add([
        dateFmt.format(entry.clockIn),
        timeFmt.format(entry.clockIn),
        entry.clockOut != null ? timeFmt.format(entry.clockOut!) : '-',
        hours.toStringAsFixed(2),
        '${data.hourlyRate.toStringAsFixed(2)}',
        '${amount.toStringAsFixed(2)}',
      ]);
    }

    // Totals
    final totalHours = data.totalHours;
    final totalAmount = data.totalAmount;

    doc.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(),
        ),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('INVOICE', style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 8),
                  pw.Text('Project: ${data.projectId}'),
                  pw.Text('Period: ${dateFmt.format(data.startDate)} - ${dateFmt.format(data.endDate)}'),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Date: ${dateFmt.format(DateTime.now())}'),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 24),
          pw.Table.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColor.fromInt(0xFFEFEFEF)),
            cellAlignment: pw.Alignment.centerLeft,
            columnWidths: {
              0: const pw.FlexColumnWidth(2),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(2),
              3: const pw.FlexColumnWidth(1),
              4: const pw.FlexColumnWidth(1.2),
              5: const pw.FlexColumnWidth(1.4),
            },
          ),
          pw.SizedBox(height: 16),
          pw.Divider(),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [
              pw.Container(
                width: 280,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                  children: [
                    _summaryRow('Total Hours:', totalHours.toStringAsFixed(2)),
                    _summaryRow('Hourly Rate:', '\u0024${data.hourlyRate.toStringAsFixed(2)}'),
                    pw.Divider(),
                    _summaryRow('TOTAL DUE:', '\u0024${totalAmount.toStringAsFixed(2)}', bold: true, size: 16),
                  ],
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 12),
          pw.Text('Thank you for your business!', style: const pw.TextStyle(color: PdfColors.grey700)),
        ],
      ),
    );

    return doc.save();
  }

  static pw.Widget _summaryRow(String label, String value, {bool bold = false, double size = 12}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: size, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: size, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }
}

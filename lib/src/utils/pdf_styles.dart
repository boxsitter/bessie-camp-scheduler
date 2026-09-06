import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class CorePdfStyles {
  // Text styles
  static pw.TextStyle rosterTitleTextStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);
  static pw.TextStyle rosterSizeTextStyle = const pw.TextStyle(fontSize: 8);
  static pw.TextStyle tableHeaderTextStyle = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);
  static pw.TextStyle tableCellTextStyle = const pw.TextStyle(fontSize: 8);

  // Decorations
  static pw.BoxDecoration tableHeaderDecoration = const pw.BoxDecoration(color: PdfColors.grey300);

  // Padding for table cells
  static const pw.EdgeInsets cellPadding = pw.EdgeInsets.all(2.5); // Define cellPadding here

  // TODO: make pdfs a feature and extract this to a widgets folder
  static pw.Widget paddedText(String text, pw.TextStyle style) {
    return pw.Padding(
      padding: cellPadding,
      child: pw.Text(text, style: style),
    );
  }

  static const defaultColumnWidths = {
    0: pw.FlexColumnWidth(3),
    1: pw.FlexColumnWidth(3),
    2: pw.FlexColumnWidth(1),
    3: pw.FlexColumnWidth(2),
  };
}


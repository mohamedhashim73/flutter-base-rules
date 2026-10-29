import 'dart:convert';
import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:typed_data';
import 'xlsx_package_builder.dart';

@JS('window.print')
external void _browserPrint();

class PrintService {
  const PrintService._();

  static void printPage() => _browserPrint();

  static void downloadExcel({required String filename, required String html}) {
    _download(
      filename: filename,
      bytes: utf8.encode(html),
      mime: 'application/vnd.ms-excel;charset=utf-8',
    );
  }

  static void downloadXlsx({
    required String filename,
    required List<List<String>> rows,
  }) {
    _download(
      filename: filename,
      bytes: XlsxPackageBuilder.build(rows),
      mime: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    );
  }

  static void downloadPdf({
    required String filename,
    required List<String> lines,
  }) {
    final content = StringBuffer()
      ..writeln('BT')
      ..writeln('/F1 11 Tf')
      ..writeln('50 760 Td');
    for (final line in lines.take(45)) {
      final safe = line
          .replaceAll(r'\', r'\\')
          .replaceAll('(', r'\(')
          .replaceAll(')', r'\)');
      content
        ..writeln('($safe) Tj')
        ..writeln('0 -16 Td');
    }
    content.writeln('ET');
    final objects = <String>[
      '<< /Type /Catalog /Pages 2 0 R >>',
      '<< /Type /Pages /Kids [3 0 R] /Count 1 >>',
      '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 612 792] /Resources << /Font << /F1 4 0 R >> >> /Contents 5 0 R >>',
      '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica >>',
      '<< /Length ${utf8.encode(content.toString()).length} >>\nstream\n$content\nendstream',
    ];
    final document = StringBuffer('%PDF-1.4\n');
    final offsets = <int>[0];
    for (var index = 0; index < objects.length; index++) {
      offsets.add(utf8.encode(document.toString()).length);
      document
        ..writeln('${index + 1} 0 obj')
        ..writeln(objects[index])
        ..writeln('endobj');
    }
    final xrefOffset = utf8.encode(document.toString()).length;
    document
      ..writeln('xref')
      ..writeln('0 ${objects.length + 1}')
      ..writeln('0000000000 65535 f ');
    for (final offset in offsets.skip(1)) {
      document.writeln('${offset.toString().padLeft(10, '0')} 00000 n ');
    }
    document
      ..writeln('trailer')
      ..writeln('<< /Size ${objects.length + 1} /Root 1 0 R >>')
      ..writeln('startxref')
      ..writeln(xrefOffset)
      ..writeln('%%EOF');
    _download(
      filename: filename,
      bytes: utf8.encode(document.toString()),
      mime: 'application/pdf',
    );
  }

  static void _download({
    required String filename,
    required List<int> bytes,
    required String mime,
  }) {
    final blob = html.Blob([Uint8List.fromList(bytes)], mime);
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..download = filename
      ..style.display = 'none';
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);
  }
}

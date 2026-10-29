import 'dart:convert';
import 'dart:typed_data';

class XlsxPackageBuilder {
  const XlsxPackageBuilder._();

  static List<int> build(List<List<String>> rows) {
    final files = <String, List<int>>{
      '[Content_Types].xml': utf8.encode(
        '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/></Types>''',
      ),
      '_rels/.rels': utf8.encode(
        '''<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>''',
      ),
      'xl/workbook.xml': utf8.encode(
        '''<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets><sheet name="Credexa" sheetId="1" r:id="rId1"/></sheets></workbook>''',
      ),
      'xl/_rels/workbook.xml.rels': utf8.encode(
        '''<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/></Relationships>''',
      ),
      'xl/worksheets/sheet1.xml': utf8.encode(_sheetXml(rows)),
    };
    final output = BytesBuilder();
    final centralDirectory = BytesBuilder();
    var offset = 0;
    for (final entry in files.entries) {
      final name = utf8.encode(entry.key);
      final data = entry.value;
      final crc = _crc32(data);
      output.add(_header(0x04034b50, name.length, data.length, crc));
      output.add(name);
      output.add(data);
      centralDirectory.add(_centralHeader(name, data.length, crc, offset));
      offset += 30 + name.length + data.length;
    }
    final directory = centralDirectory.toBytes();
    final bytes = output.toBytes();
    return <int>[
      ...bytes,
      ...directory,
      ..._end(files.length, directory.length, bytes.length),
    ];
  }

  static String _sheetXml(List<List<String>> rows) {
    final buffer = StringBuffer(
      '''<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetData>''',
    );
    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      buffer.write('<row r="${rowIndex + 1}">');
      for (
        var columnIndex = 0;
        columnIndex < rows[rowIndex].length;
        columnIndex++
      ) {
        final reference = '${_columnName(columnIndex)}${rowIndex + 1}';
        buffer.write(
          '<c r="$reference" t="inlineStr"><is><t>${_escape(rows[rowIndex][columnIndex])}</t></is></c>',
        );
      }
      buffer.write('</row>');
    }
    return '$buffer</sheetData></worksheet>';
  }

  static String _columnName(int index) {
    var value = index + 1;
    final result = StringBuffer();
    while (value > 0) {
      final remainder = (value - 1) % 26;
      result.writeCharCode(65 + remainder);
      value = (value - 1) ~/ 26;
    }
    return result.toString().split('').reversed.join();
  }

  static String _escape(String value) => value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  static List<int> _header(int signature, int nameLength, int size, int crc) {
    final data = ByteData(30)
      ..setUint32(0, signature, Endian.little)
      ..setUint16(4, 20, Endian.little)
      ..setUint32(14, crc, Endian.little)
      ..setUint32(18, size, Endian.little)
      ..setUint32(22, size, Endian.little)
      ..setUint16(26, nameLength, Endian.little);
    return data.buffer.asUint8List();
  }

  static List<int> _centralHeader(
    List<int> name,
    int size,
    int crc,
    int offset,
  ) {
    final data = ByteData(46)
      ..setUint32(0, 0x02014b50, Endian.little)
      ..setUint16(4, 20, Endian.little)
      ..setUint16(6, 20, Endian.little)
      ..setUint32(16, crc, Endian.little)
      ..setUint32(20, size, Endian.little)
      ..setUint32(24, size, Endian.little)
      ..setUint16(28, name.length, Endian.little)
      ..setUint32(42, offset, Endian.little);
    return <int>[...data.buffer.asUint8List(), ...name];
  }

  static List<int> _end(int entries, int directorySize, int directoryOffset) {
    final data = ByteData(22)
      ..setUint32(0, 0x06054b50, Endian.little)
      ..setUint16(8, entries, Endian.little)
      ..setUint16(10, entries, Endian.little)
      ..setUint32(12, directorySize, Endian.little)
      ..setUint32(16, directoryOffset, Endian.little);
    return data.buffer.asUint8List();
  }

  static int _crc32(List<int> bytes) {
    var crc = 0xffffffff;
    for (final byte in bytes) {
      crc ^= byte;
      for (var bit = 0; bit < 8; bit++) {
        crc = (crc & 1) == 1 ? (crc >> 1) ^ 0xedb88320 : crc >> 1;
      }
    }
    return (crc ^ 0xffffffff) & 0xffffffff;
  }
}

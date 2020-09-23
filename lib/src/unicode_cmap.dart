// ignore_for_file: omit_local_variable_types

part of pdf;

class PdfUnicodeCmap extends PdfObjectStream {
  PdfUnicodeCmap(PdfDocument pdfDocument, this.protect) : super(pdfDocument);

  final List<int> cmap = <int>[0];

  final bool protect;

  @override
  void _prepare() {
    if (protect) {
      cmap.fillRange(1, cmap.length, 0x20);
    }

    buf.putString('/CIDInit/ProcSet findresource begin\n'
        '12 dict begin\n'
        'begincmap\n'
        '/CIDSystemInfo<<\n'
        '/Registry (Adobe)\n'
        '/Ordering (UCS)\n'
        '/Supplement 0\n'
        '>> def\n'
        '/CMapName/Adobe-Identity-UCS def\n'
        '/CMapType 2 def\n'
        '1 begincodespacerange\n'
        '<0000> <FFFF>\n'
        'endcodespacerange\n'
        '${cmap.length} beginbfchar\n');

    for (int key = 0; key < cmap.length; key++) {
      final int value = cmap[key];
      buf.putString('<' +
          key.toRadixString(16).toUpperCase().padLeft(4, '0') +
          '> <' +
          value.toRadixString(16).toUpperCase().padLeft(4, '0') +
          '>\n');
    }

    buf.putString('endbfchar\n'
        'endcmap\n'
        'CMapName currentdict /CMap defineresource pop\n'
        'end\n'
        'end');
    super._prepare();
  }
}


part of pdf;

class PdfFontDescriptor extends PdfObject {
  PdfFontDescriptor(
    this.ttfFont,
    this.file,
  )   : assert(ttfFont != null),
        assert(file != null),
        super(ttfFont.pdfDocument, '/FontDescriptor');

  final PdfObjectStream file;

  final PdfTtfFont ttfFont;

  @override
  void _prepare() {
    super._prepare();

    params['/FontName'] = PdfName('/' + ttfFont.fontName);
    params['/FontFile2'] = file.ref();
    params['/Flags'] = PdfNum(ttfFont.font.unicode ? 4 : 32);
    params['/FontBBox'] = PdfArray.fromNum(<int>[
      (ttfFont.font.xMin / ttfFont.font.unitsPerEm * 1000).toInt(),
      (ttfFont.font.yMin / ttfFont.font.unitsPerEm * 1000).toInt(),
      (ttfFont.font.xMax / ttfFont.font.unitsPerEm * 1000).toInt(),
      (ttfFont.font.yMax / ttfFont.font.unitsPerEm * 1000).toInt()
    ]);
    params['/Ascent'] = PdfNum((ttfFont.ascent * 1000).toInt());
    params['/Descent'] = PdfNum((ttfFont.descent * 1000).toInt());
    params['/ItalicAngle'] = const PdfNum(0);
    params['/CapHeight'] = const PdfNum(10);
    params['/StemV'] = const PdfNum(79);
  }
}



part of pdf;

class PdfType1Font extends PdfFont {
  /// Constructs a [PdfTtfFont]
  PdfType1Font._create(PdfDocument pdfDocument, this.fontName, this.ascent,
      this.descent, this.widths)
      : assert(() {
          print(
              '$fontName has no Unicode support see https://github.com/DavBfr/dart_pdf/wiki/Fonts-Management');
          return true;
        }()),
        super._create(pdfDocument, subtype: '/Type1');

  /// The font's real name
  @override
  final String fontName;

  @override
  final double ascent;

  @override
  final double descent;

  final List<double> widths;

  /// @param os OutputStream to send the object to
  @override
  void _prepare() {
    super._prepare();

    params['/BaseFont'] = PdfName('/' + fontName);
  }

  @override
  PdfFontMetrics glyphMetrics(int charCode) {
    return PdfFontMetrics(
        left: 0,
        top: descent,
        right: charCode < widths.length
            ? widths[charCode]
            : PdfFont.defaultGlyphWidth,
        bottom: ascent);
  }
}

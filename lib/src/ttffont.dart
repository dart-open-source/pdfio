
part of pdf;

class PdfTtfFont extends PdfFont {
  /// Constructs a [PdfTtfFont]
  PdfTtfFont(PdfDocument pdfDocument, ByteData bytes, {bool protect = false})
      : font = TtfParser(bytes),
        super._create(pdfDocument, subtype: '/TrueType') {
    file = PdfObjectStream(pdfDocument, isBinary: true);
    unicodeCMap = PdfUnicodeCmap(pdfDocument, protect);
    descriptor = PdfFontDescriptor(this, file);
    widthsObject = PdfArrayObject(pdfDocument, PdfArray());
  }

  @override
  String get subtype => font.unicode ? '/Type0' : super.subtype;

  PdfUnicodeCmap unicodeCMap;

  PdfFontDescriptor descriptor;

  PdfObjectStream file;

  PdfArrayObject widthsObject;

  final TtfParser font;

  @override
  String get fontName => font.fontName;

  @override
  double get ascent => font.ascent.toDouble() / font.unitsPerEm;

  @override
  double get descent => font.descent.toDouble() / font.unitsPerEm;

  @override
  PdfFontMetrics glyphMetrics(int charCode) {
    var g = font.charToGlyphIndexMap[charCode];
    if (g == null) {
      return PdfFontMetrics.zero;
    }
    if (PdfArabic._isArabicDiacriticValue(charCode)) {
      var metric = font.glyphInfoMap[g] ?? PdfFontMetrics.zero;
      return metric.copyWith(advanceWidth: 0);
    }
    return font.glyphInfoMap[g] ?? PdfFontMetrics.zero;
  }

  void _buildTrueType(PdfDict params) {
    int charMin;
    int charMax;

    file.buf.putBytes(font.bytes.buffer.asUint8List());
    file.params['/Length1'] = PdfNum(font.bytes.lengthInBytes);

    params['/BaseFont'] = PdfName('/' + fontName);
    params['/FontDescriptor'] = descriptor.ref();
    charMin = 32;
    charMax = 255;
    for (var i = charMin; i <= charMax; i++) {
      widthsObject.array
          .add(PdfNum((glyphMetrics(i).advanceWidth * 1000.0).toInt()));
    }
    params['/FirstChar'] = PdfNum(charMin);
    params['/LastChar'] = PdfNum(charMax);
    params['/Widths'] = widthsObject.ref();
  }

  void _buildType0(PdfDict params) {
    int charMin;
    int charMax;

    var ttfWriter = TtfWriter(font);
    var data = ttfWriter.withChars(unicodeCMap.cmap);
    file.buf.putBytes(data);
    file.params['/Length1'] = PdfNum(data.length);

    var descendantFont = PdfDict(<String, PdfDataType>{
      '/Type': const PdfName('/Font'),
      '/BaseFont': PdfName('/' + fontName),
      '/FontFile2': file.ref(),
      '/FontDescriptor': descriptor.ref(),
      '/W': PdfArray(<PdfDataType>[
        const PdfNum(0),
        widthsObject.ref(),
      ]),
      '/CIDToGIDMap': const PdfName('/Identity'),
      '/DW': const PdfNum(1000),
      '/Subtype': const PdfName('/CIDFontType2'),
      '/CIDSystemInfo': PdfDict(<String, PdfDataType>{
        '/Supplement': const PdfNum(0),
        '/Registry': PdfSecString.fromString(this, 'Adobe'),
        '/Ordering': PdfSecString.fromString(this, 'Identity-H'),
      })
    });

    params['/BaseFont'] = PdfName('/' + fontName);
    params['/Encoding'] = const PdfName('/Identity-H');
    params['/DescendantFonts'] = PdfArray(<PdfDataType>[descendantFont]);
    params['/ToUnicode'] = unicodeCMap.ref();

    charMin = 0;
    charMax = unicodeCMap.cmap.length - 1;
    for (var i = charMin; i <= charMax; i++) {
      widthsObject.array.add(PdfNum((glyphMetrics(unicodeCMap.cmap[i]).advanceWidth * 1000.0).toInt()));
    }
  }

  @override
  void _prepare() {
    super._prepare();

    if (font.unicode) {
      _buildType0(params);
    } else {
      _buildTrueType(params);
    }
  }

  @override
  void putText(PdfStream stream, String text) {
    if (!font.unicode) {
      super.putText(stream, text);
    }

    var runes = text.runes;

    stream.putByte(0x3c);
    for (var rune in runes) {
      var char = unicodeCMap.cmap.indexOf(rune);
      if (char == -1) {
        char = unicodeCMap.cmap.length;
        unicodeCMap.cmap.add(rune);
      }

      stream.putBytes(latin1.encode(char.toRadixString(16).padLeft(4, '0')));
    }
    stream.putByte(0x3e);
  }

  @override
  PdfFontMetrics stringMetrics(String s, {double letterSpacing = 0}) {
    if (s.isEmpty || !font.unicode) {
      return super.stringMetrics(s, letterSpacing: letterSpacing);
    }

    var runes = s.runes;
    var bytes = <int>[];
    runes.forEach(bytes.add);
    var metrics = bytes.map(glyphMetrics);
    return PdfFontMetrics.append(metrics, letterSpacing: letterSpacing);
  }
}

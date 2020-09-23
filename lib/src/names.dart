

part of pdf;

class PdfNames extends PdfObject {
  /// This constructs a Pdf Name object
  PdfNames(PdfDocument pdfDocument) : super(pdfDocument);

  final PdfArray _dests = PdfArray();

  void addDest(
    String name,
    PdfPage page, {
    double posX,
    double posY,
    double posZ,
  }) {
    assert(page.pdfDocument == pdfDocument);
    assert(name != null);

    _dests.add(PdfSecString.fromString(this, name));
    _dests.add(PdfDict(<String, PdfDataType>{
      '/D': PdfArray(<PdfDataType>[
        page.ref(),
        const PdfName('/XYZ'),
        if (posX == null) const PdfNull() else PdfNum(posX),
        if (posY == null) const PdfNull() else PdfNum(posY),
        if (posZ == null) const PdfNull() else PdfNum(posZ),
      ]),
    }));
  }

  @override
  void _prepare() {
    super._prepare();

    params['/Dests'] = PdfDict(<String, PdfDataType>{'/Names': _dests});
  }
}

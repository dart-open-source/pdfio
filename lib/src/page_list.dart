

part of pdf;

class PdfPageList extends PdfObject {
  /// This constructs a [PdfPageList] object.
  PdfPageList(PdfDocument pdfDocument) : super(pdfDocument, '/Pages');

  /// This holds the pages
  final List<PdfPage> pages = <PdfPage>[];

  /// This returns a specific page. Used by the Pdf class.
  /// @param page page number to return
  /// @return [PdfPage] at that position
  PdfPage getPage(int page) => pages[page];

  @override
  void _prepare() {
    super._prepare();

    params['/Kids'] = PdfArray.fromObjects(pages);
    params['/Count'] = PdfNum(pages.length);
  }
}

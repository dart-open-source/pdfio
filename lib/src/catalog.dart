// ignore_for_file: omit_local_variable_types

part of pdf;

class PdfCatalog extends PdfObject {
  /// This constructs a Pdf Catalog object
  ///
  /// @param pdfPageList The [PdfPageList] object that's the root of the documents page tree
  /// @param pagemode How the document should appear when opened.
  /// Allowed values are usenone, useoutlines, usethumbs or fullscreen.
  PdfCatalog(
    PdfDocument pdfDocument,
    this.pdfPageList,
    this.pageMode,
    this.names,
  )   : assert(pdfPageList != null),
        assert(pageMode != null),
        assert(names != null),
        super(pdfDocument, '/Catalog');

  /// The pages of the document
  final PdfPageList pdfPageList;

  /// The outlines of the document
  PdfOutline outlines;

  /// The initial page mode
  final PdfPageMode pageMode;

  /// The initial page mode
  final PdfNames names;

  /// @param os OutputStream to send the object to
  @override
  void _prepare() {
    super._prepare();

    /// the PDF specification version, overrides the header version starting from 1.4
    params['/Version'] = PdfName('/${pdfDocument.version}');

    params['/Pages'] = pdfPageList.ref();

    // the Outlines object
    if (outlines != null && outlines.outlines.isNotEmpty) {
      params['/Outlines'] = outlines.ref();
    }

    // the Names object
    params['/Names'] = names.ref();

    // the /PageMode setting
    params['/PageMode'] = PdfName(PdfDocument._PdfPageModes[pageMode.index]);

    if (pdfDocument.sign != null) {
      params['/Perms'] = PdfDict(<String, PdfDataType>{
        '/DocMDP': pdfDocument.sign.ref(),
      });
    }

    final List<PdfAnnot> widgets = <PdfAnnot>[];
    for (PdfPage page in pdfDocument.pdfPageList.pages) {
      for (PdfAnnot annot in page.annotations) {
        if (annot.annot.subtype == '/Widget') {
          widgets.add(annot);
        }
      }
    }

    if (widgets.isNotEmpty) {
      params['/AcroForm'] = PdfDict(<String, PdfDataType>{
        '/SigFlags': PdfNum(pdfDocument.sign?.flagsValue ?? 0),
        '/Fields': PdfArray.fromObjects(widgets),
      });
    }
  }
}

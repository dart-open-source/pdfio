
part of pdf;

class PdfXObject extends PdfObjectStream {
  PdfXObject(PdfDocument pdfDocument, String subtype, {bool isBinary = false})
      : super(pdfDocument, type: '/XObject', isBinary: isBinary) {
    params['/Subtype'] = PdfName(subtype);
  }
}

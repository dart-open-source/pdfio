

part of pdf;

abstract class PdfEncryption extends PdfObject {
  PdfEncryption(PdfDocument pdfDocument) : super(pdfDocument, null);

  Uint8List encrypt(Uint8List input, PdfObject object);
}

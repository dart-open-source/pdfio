

part of pdf;

class PdfArrayObject extends PdfObject {
  PdfArrayObject(
    PdfDocument pdfDocument,
    this.array,
  )   : assert(array != null),
        super(pdfDocument);

  final PdfArray array;

  @override
  void _writeContent(PdfStream os) {
    super._writeContent(os);
    array.output(os);
    os.putBytes(<int>[0x0a]);
  }
}

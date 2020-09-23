
part of pdf;

enum PdfSigFlags { signaturesExist, appendOnly }

class PdfSignature extends PdfObject {
  PdfSignature(
    PdfDocument pdfDocument, {
    @required this.crypto,
    Set<PdfSigFlags> flags,
  })  : assert(crypto != null),
        flags = flags ?? const <PdfSigFlags>{PdfSigFlags.signaturesExist},
        super(pdfDocument, '/Sig');

  final Set<PdfSigFlags> flags;

  final PdfSignatureBase crypto;

  int get flagsValue => flags
      .map<int>((PdfSigFlags e) => 1 >> e.index)
      .reduce((int a, int b) => a | b);

  int _offsetStart;
  int _offsetEnd;

  @override
  void _write(PdfStream os) {
    crypto.preSign(this, params);

    _offsetStart = os.offset + '$objser $objgen obj\n'.length;
    super._write(os);
    _offsetEnd = os.offset;
  }

  void _writeSignature(PdfStream os) {
    assert(_offsetStart != null && _offsetEnd != null,
        'Must reserve the object space before signing the document');

    crypto.sign(this, os, params, _offsetStart, _offsetEnd);
  }
}

abstract class PdfSignatureBase {
  void preSign(PdfObject object, PdfDict params);

  void sign(PdfObject object, PdfStream os, PdfDict params, int offsetStart,
      int offsetEnd);
}

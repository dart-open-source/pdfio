

// ignore_for_file: omit_local_variable_types

part of pdf;

class PdfObjectStream extends PdfObject {
  /// Constructs a stream. The supplied type is stored in the stream's header
  /// and is used by other objects that extend the [PdfStream] class (like
  /// [PdfImage]).
  /// By default, the stream will be compressed.
  ///
  /// @param type type for the stream
  /// @see [PdfImage]
  PdfObjectStream(PdfDocument pdfDocument, {String type, this.isBinary = false})
      : super(pdfDocument, type);

  /// This holds the stream's content.
  final PdfStream buf = PdfStream();

  /// defines if the stream needs to be converted to ascii85
  final bool isBinary;

  Uint8List _data;

  @override
  void _prepare() {
    super._prepare();

    if (params.containsKey('/Filter') && _data == null) {
      // The data is already in the right format
      _data = buf.output();
    } else if (pdfDocument.deflate != null) {
      final Uint8List original = buf.output();
      final Uint8List newData = pdfDocument.deflate(original);
      if (newData.lengthInBytes < original.lengthInBytes) {
        params['/Filter'] = const PdfName('/FlateDecode');
        _data = newData;
      }
    }

    if (_data == null) {
      if (isBinary) {
        // This is a Ascii85 stream
        final Ascii85Encoder e = Ascii85Encoder();
        _data = e.convert(buf.output());
        params['/Filter'] = const PdfName('/ASCII85Decode');
      } else {
        // This is a non-deflated stream
        _data = buf.output();
      }
    }
    if (pdfDocument.encryption != null) {
      _data = pdfDocument.encryption.encrypt(_data, this);
    }
    params['/Length'] = PdfNum(_data.length);
  }

  @override
  void _writeContent(PdfStream os) {
    super._writeContent(os);

    os.putString('stream\n');
    os.putBytes(_data);
    os.putString('\nendstream\n');
  }
}

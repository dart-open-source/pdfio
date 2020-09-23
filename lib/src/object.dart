

part of pdf;

class PdfObject {
  /// This is usually called by extensors to this class, and sets the
  /// Pdf Object Type
  /// @param type the Pdf Object Type
  PdfObject(this.pdfDocument, [String type])
      : assert(pdfDocument != null),
        objser = pdfDocument._genSerial() {
    if (type != null) {
      params['/Type'] = PdfName(type);
    }

    pdfDocument.objects.add(this);
  }

  /// This is the object parameters.
  final PdfDict params = PdfDict();

  /// This is the unique serial number for this object.
  final int objser;

  /// This is the generation number for this object.
  final int objgen = 0;

  /// This allows any Pdf object to refer to the document being constructed.
  final PdfDocument pdfDocument;

  /// Writes the object to the output stream.
  /// This method must be overridden.
  ///
  /// Note: It should not write any other objects, even if they are
  /// it's Kids, as they will be written by the calling routine.
  ///
  /// @param os OutputStream to send the object to
  void _write(PdfStream os) {
    _prepare();
    _writeStart(os);
    _writeContent(os);
    _writeEnd(os);
  }

  /// Prepare the object to be written to the stream
  @mustCallSuper
  void _prepare() {}

  /// The write method should call this before writing anything to the
  /// OutputStream. This will send the standard header for each object.
  ///
  /// Note: There are a few rare cases where this method is not called.
  ///
  /// @param os OutputStream to write to
  void _writeStart(PdfStream os) {
    os.putString('$objser $objgen obj\n');
  }

  void _writeContent(PdfStream os) {
    if (params.isNotEmpty) {
      params.output(os);
      os.putString('\n');
    }
  }

  /// The write method should call this after writing anything to the
  /// OutputStream. This will send the standard footer for each object.
  ///
  /// Note: There are a few rare cases where this method is not called.
  ///
  /// @param os OutputStream to write to
  void _writeEnd(PdfStream os) {
    os.putString('endobj\n');
  }

  /// Returns the unique serial number in Pdf format
  /// @return the serial number in Pdf format
  PdfIndirect ref() => PdfIndirect(objser, objgen);
}

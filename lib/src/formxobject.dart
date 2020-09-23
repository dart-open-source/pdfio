// ignore_for_file: omit_local_variable_types

part of pdf;

class PdfFormXObject extends PdfXObject {
  PdfFormXObject(PdfDocument pdfDocument) : super(pdfDocument, '/Form') {
    params['/FormType'] = const PdfNum(1);
    params['/BBox'] = PdfArray.fromNum(const <int>[0, 0, 1000, 1000]);
  }

  /// The fonts associated with this page
  final Map<String, PdfFont> fonts = <String, PdfFont>{};

  /// The xobjects or other images in the pdf
  final Map<String, PdfXObject> xobjects = <String, PdfXObject>{};

  /// set matrix
  void setMatrix(Matrix4 t) {
    final Float64List s = t.storage;
    params['/Matrix'] =
        PdfArray.fromNum(<double>[s[0], s[1], s[4], s[5], s[12], s[13]]);
  }

  @override
  void _prepare() {
    super._prepare();

    // Now the resources
    /// This holds any resources for this FormXObject
    final PdfDict resources = PdfDict();

    // fonts
    if (fonts.isNotEmpty) {
      resources['/Font'] = PdfDict.fromObjectMap(fonts);
    }

    // Now the XObjects
    if (xobjects.isNotEmpty) {
      resources['/XObject'] = PdfDict.fromObjectMap(xobjects);
    }

    if (resources.isNotEmpty) {
      params['/Resources'] = resources;
    }
  }
}

// ignore_for_file: omit_local_variable_types

part of pdf;

enum PdfBorderStyle {
  /// Solid border. The border is drawn as a solid line.
  solid,

  /// The border is drawn with a dashed line.
  dashed,

  /// The border is drawn in a beveled style (faux three-dimensional) such
  /// that it looks as if it is pushed out of the page (opposite of INSET)
  beveled,

  /// The border is drawn in an inset style (faux three-dimensional) such
  /// that it looks as if it is inset into the page (opposite of BEVELED)
  inset,

  /// The border is drawn as a line on the bottom of the annotation rectangle
  underlined
}

class PdfBorder extends PdfObject {
  /// Creates a border using the predefined styles in [PdfAnnotation].
  /// Note: Do not use [PdfAnnotation.dashed] with this method.
  /// Use the other constructor.
  ///
  /// @param width The width of the border
  /// @param style The style of the border
  /// @param dash The line pattern definition
  /// @see [PdfAnnotation]
  PdfBorder(
    PdfDocument pdfDocument,
    this.width, {
    this.style = PdfBorderStyle.solid,
    this.dash,
  })  : assert(width != null),
        assert(style != null),
        super(pdfDocument);

  /// The style of the border
  final PdfBorderStyle style;

  /// The width of the border
  final double width;

  /// This array allows the definition of a dotted line for the border
  final List<double> dash;

  /// @param os OutputStream to send the object to
  @override
  void _prepare() {
    super._prepare();

    params['/S'] = PdfName('/' + 'SDBIU'.substring(style.index, style.index + 1));
    params['/W'] = PdfNum(width);
    if (dash != null) {
      params['/D'] = PdfArray.fromNum(dash);
    }
  }
}

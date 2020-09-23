

// ignore_for_file: omit_local_variable_types

part of pdf;

enum PdfShadingType { axial, radial }

class PdfShading extends PdfObject {
  PdfShading(
    PdfDocument pdfDocument, {
    @required this.shadingType,
    @required this.function,
    @required this.start,
    @required this.end,
    this.radius0,
    this.radius1,
    this.boundingBox,
    this.extendStart = false,
    this.extendEnd = false,
  })  : assert(shadingType != null),
        assert(function != null),
        assert(start != null),
        assert(end != null),
        assert(extendStart != null),
        assert(extendEnd != null),
        super(pdfDocument);

  /// Name of the Shading object
  String get name => '/S$objser';

  final PdfShadingType shadingType;

  final PdfBaseFunction function;

  final PdfPoint start;

  final PdfPoint end;

  final PdfRect boundingBox;

  final bool extendStart;

  final bool extendEnd;

  final double radius0;

  final double radius1;

  @override
  void _prepare() {
    super._prepare();

    params['/ShadingType'] = PdfNum(shadingType.index + 2);
    if (boundingBox != null) {
      params['/BBox'] = PdfArray.fromNum(<double>[
        boundingBox.left,
        boundingBox.bottom,
        boundingBox.right,
        boundingBox.top,
      ]);
    }
    params['/AntiAlias'] = const PdfBool(true);
    params['/ColorSpace'] = const PdfName('/DeviceRGB');

    if (shadingType == PdfShadingType.axial) {
      params['/Coords'] =PdfArray.fromNum(<double>[start.x, start.y, end.x, end.y]);
    } else if (shadingType == PdfShadingType.radial) {
      assert(radius0 != null);
      assert(radius1 != null);
      params['/Coords'] = PdfArray.fromNum(<double>[start.x, start.y, radius0, end.x, end.y, radius1]);
    }
    // params['/Domain'] = PdfArray.fromNum(<num>[0, 1]);
    if (extendStart || extendEnd) {
      params['/Extend'] =
          PdfArray(<PdfBool>[PdfBool(extendStart), PdfBool(extendEnd)]);
    }
    params['/Function'] = function.ref();
  }
}

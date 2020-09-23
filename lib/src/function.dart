// ignore_for_file: omit_local_variable_types

part of pdf;

abstract class PdfBaseFunction extends PdfObject {
  PdfBaseFunction(PdfDocument pdfDocument) : super(pdfDocument);
}

class PdfFunction extends PdfObjectStream implements PdfBaseFunction {
  PdfFunction(
    PdfDocument pdfDocument, {
    this.colors,
  }) : super(pdfDocument);

  final List<PdfColor> colors;

  @override
  void _prepare() {
    for (final PdfColor color in colors) {
      buf.putBytes(<int>[
        (color.red * 255.0).round() & 0xff,
        (color.green * 255.0).round() & 0xff,
        (color.blue * 255.0).round() & 0xff,
      ]);
    }

    super._prepare();

    params['/FunctionType'] = const PdfNum(0);
    params['/BitsPerSample'] = const PdfNum(8);
    params['/Order'] = const PdfNum(3);
    params['/Domain'] = PdfArray.fromNum(const <num>[0, 1]);
    params['/Range'] = PdfArray.fromNum(const <num>[0, 1, 0, 1, 0, 1]);
    params['/Size'] = PdfArray.fromNum(<int>[colors.length]);
  }
}

class PdfStitchingFunction extends PdfBaseFunction {
  PdfStitchingFunction(
    PdfDocument pdfDocument, {
    @required this.functions,
    @required this.bounds,
    this.domainStart = 0,
    this.domainEnd = 1,
  })  : assert(functions != null),
        assert(bounds != null),
        super(pdfDocument);

  final List<PdfFunction> functions;

  final List<double> bounds;

  final double domainStart;

  final double domainEnd;

  @override
  void _prepare() {
    super._prepare();

    params['/FunctionType'] = const PdfNum(3);
    params['/Functions'] = PdfArray.fromObjects(functions);
    params['/Order'] = const PdfNum(3);
    params['/Domain'] = PdfArray.fromNum(<num>[domainStart, domainEnd]);
    params['/Bounds'] = PdfArray.fromNum(bounds);
    params['/Encode'] = PdfArray.fromNum(List<int>.generate(functions.length * 2, (int i) => i % 2));
  }
}

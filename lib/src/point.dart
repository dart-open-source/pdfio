

part of pdf;

@immutable
class PdfPoint {
  const PdfPoint(this.x, this.y);

  final double x, y;

  @Deprecated('Use `x` instead')
  double get w => x;

  @Deprecated('Use `y` instead')
  double get h => y;

  static const PdfPoint zero = PdfPoint(0.0, 0.0);

  @override
  String toString() => 'PdfPoint($x, $y)';

  PdfPoint translate(double offsetX, double offsetY) =>
      PdfPoint(x + offsetX, y + offsetY);
}

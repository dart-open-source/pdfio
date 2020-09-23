

part of pdf;

@immutable
class PdfRect {
  const PdfRect(this.x, this.y, this.width, this.height);

  factory PdfRect.fromLTRB(
      double left, double top, double right, double bottom) {
    return PdfRect(left, top, right - left, bottom - top);
  }

  factory PdfRect.fromPoints(PdfPoint offset, PdfPoint size) {
    return PdfRect(offset.x, offset.y, size.x, size.y);
  }

  final double x, y, width, height;

  static const PdfRect zero = PdfRect(0, 0, 0, 0);

  double get left => x;
  double get bottom => y;
  double get right => x + width;
  double get top => y + height;

  double get horizondalCenter => x + width / 2;
  double get verticalCenter => y + height / 2;

  @Deprecated('Use `left` instead')
  double get l => left;

  @Deprecated('Use `bottom` instead')
  double get b => bottom;

  @Deprecated('Use `right` instead')
  double get r => right;

  @Deprecated('Use `top` instead')
  double get t => top;

  @Deprecated('Use `width` instead')
  double get w => width;

  @Deprecated('Use `height` instead')
  double get h => height;

  @override
  String toString() => 'PdfRect($x, $y, $width, $height)';

  PdfRect operator *(double factor) {
    return PdfRect(x * factor, y * factor, width * factor, height * factor);
  }

  PdfPoint get offset => PdfPoint(x, y);
  PdfPoint get size => PdfPoint(width, height);

  PdfPoint get topLeft => PdfPoint(x, y);
  PdfPoint get topRight => PdfPoint(right, y);
  PdfPoint get bottomLeft => PdfPoint(x, top);
  PdfPoint get bottomRight => PdfPoint(right, top);
}

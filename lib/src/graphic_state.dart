
// ignore_for_file: omit_local_variable_types

part of pdf;

@immutable
class PdfGraphicState {
  const PdfGraphicState({this.opacity});

  final double opacity;

  @protected
  PdfDict _output() {
    final PdfDict params = PdfDict();

    if (opacity != null) {
      params['/CA'] = PdfNum(opacity);
      params['/ca'] = PdfNum(opacity);
    }

    return params;
  }

  @override
  bool operator ==(dynamic other) {
    if (!(other is PdfGraphicState)) {
      return false;
    }
    return other.opacity == opacity;
  }

  @override
  int get hashCode => opacity.hashCode;
}

class PdfGraphicStates extends PdfObject {
  PdfGraphicStates(PdfDocument pdfDocument) : super(pdfDocument);

  final List<PdfGraphicState> _states = <PdfGraphicState>[];

  static const String _prefix = '/a';

  String stateName(PdfGraphicState state) {
    int index = _states.indexOf(state);
    if (index < 0) {
      index = _states.length;
      _states.add(state);
    }
    return '$_prefix$index';
  }

  @override
  void _prepare() {
    super._prepare();

    for (int index = 0; index < _states.length; index++) {
      params['$_prefix$index'] = _states[index]._output();
    }
  }
}

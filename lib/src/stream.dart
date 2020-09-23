
part of pdf;

class PdfStream {
  static const int _grow = 65536;

  Uint8List _stream = Uint8List(_grow);

  int _offset = 0;

  void _ensureCapacity(int size) {
    if (_stream.length - _offset >= size) {
      return;
    }
    var newSize = _offset + size + _grow;
    var newBuffer = Uint8List(newSize);
    newBuffer.setAll(0, _stream);
    _stream = newBuffer;
  }

  void putByte(int s) {
    _ensureCapacity(1);
    _stream[_offset++] = s;
  }

  void putBytes(List<int> s) {
    _ensureCapacity(s.length);
    _stream.setAll(_offset, s);
    _offset += s.length;
  }

  void setBytes(int offset, Iterable<int> iterable) {
    _stream.setAll(offset, iterable);
  }

  void putStream(PdfStream s) {
    putBytes(s._stream);
  }

  int get offset => _offset;

  Uint8List output() => _stream.sublist(0, _offset);

  void putString(String s) {
    assert(() {
      for (var codeUnit in s.codeUnits) {
        if (codeUnit > 0x7f) return false;
      }
      return true;
    }());
    putBytes(s.codeUnits);
  }
}

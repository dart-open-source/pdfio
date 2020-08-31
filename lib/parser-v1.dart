import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';
import 'package:convert/convert.dart';
main() {
  var dir=Directory.current.path;
  var path = '$dir/pdf/test.pdf';
  path='$dir/pdf/hello-world.pdf';
  path='$dir/pdf/2016201680666.pdf';
//  path='$dir/pdf/100-p.pdf';
//  path='$dir/pdf/em3.pdf';
  var file = File(path);
  File('${file.path}.txt').writeAsBytesSync(file.readAsBytesSync());
  print('file.lengthSync(${file.lengthSync()})');
  PdfPack(file: file).parse();
  print(pow(2, 24));
}

class PdfPack {
  int _position = 0;
  Uint8List _bytes;
  static Uint8List code_09 = Uint8List.fromList([48, 49, 50, 51, 52, 53, 54, 55, 56, 57]);
  static Uint8List code_az = Uint8List.fromList([97, 98, 99, 100, 101, 102, 103, 104, 105, 106, 107, 108, 109, 110, 111, 112, 113, 114, 115, 116, 117, 118, 119, 120, 121, 122]);
  static Uint8List code_AZ = Uint8List.fromList([65, 66, 67, 68, 69, 70, 71, 72, 73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, 85, 86, 87, 88, 89, 90]);
  static Uint8List code_aZ09 = Uint8List.fromList(code_09 + code_az + code_AZ);
  static Uint8List code_aF09 = Uint8List.fromList(code_09 + code_az.sublist(0, 6) + code_AZ.sublist(0, 6));

  StringBuffer word;
  bool insideStream = false;
  bool hexcode = false;

  int slashCode='/'.codeUnitAt(0);
  int spCode='#'.codeUnitAt(0);

  String lastWord='';

  String get wordStr => word.toString();

  static Map wordAll = {};
  static Map words = {
    'obj': 0,
    'endobj': 0,
    'stream': 0,
    'endstream': 0,
    'xref': 0,
    'trailer': 0,
    'startxref': 0,
    '/Page': 0,
    '/Font': 0,
    '/Encrypt': 0,
    '/ObjStm': 0,
    '/JS': 0,
    '/JavaScript': 0,
    '/AA': 0,
    '/OpenAction': 0,
    '/AcroForm': 0,
    '/JBIG2Decode':0,
    '/RichMedia': 0,
    '/Launch': 0,
    '/EmbeddedFile': 0,
    '/BaseFont': 0,
    '/XFA': 0,
  };
  static Map<String,List> wordsIndex={};

  int startxref;
  int chr = 0;
  int byteCounter = 0;
  int byteBefore = 0;

  final File file;

  String version = '';
  String slash = '';

  PdfPack({this.file});

  void parse() {
    _bytes = file.readAsBytesSync();
    if (_bytes.isEmpty) throw Exception('Empty PDF data given.');
    if (!checkHeader(bytes(4))) throw Exception('Invalid PDF data: missing %PDF header.');
    version = utf8.decode(bytes(4)).replaceAll('-', '');
    print('version:PDF-$version');
    byteBefore=_bytes.length;
    print('byte-len:$byteBefore');
    word = StringBuffer();
    byteCounter=0;
    while(true){
      chr = byte();
      if (code_aZ09.contains(chr)) {
        word.writeCharCode(chr);
      }  else {
        checkWord();
        if (chr == slashCode) {
          slash = '/';
        } else {
          slash = '';
        }
      }
      if(isByteOut()) break;
    }
    words.forEach((key, value) {
      print('$value : $key');
    });


//
//    var fontCode=_bytes.sublist(169132-('/BaseFont'.codeUnits.length+1),169132+100);
//    print(utf8.decode(fontCode));
//    print(hex.encode(fontCode));

//
//    wordsIndex['/BaseFont'].forEach((element) {
//      print('$element');
//    });

  }

  bool checkHeader(byte) => utf8.decode(byte) == '%PDF';
  bool isByteOut(){
    byteCounter++;
    if(byteCounter>byteBefore-10) return true;
    return false;
  }




  void rb(int i) => _bytes = _bytes.sublist(i);

  void readStartXref() {
    var minByteSize = 'startxref--------------------%%EOF'.length;
    var con = _bytes.sublist(_bytes.length - minByteSize);
    var startxrefL = utf8.decode(con).split('startxref');
    if (startxrefL.length != 2) throw Exception('startxref can\'t find');
    var n = startxrefL.last.split('%%EOF').first;
    startxref = int.parse(n);
    var xrefBit = _bytes.sublist(startxref - 4, startxref);
    if (xrefBit == utf8.encode('xref')) throw Exception('xref point error');
  }

  Future<void> decodeXref() async {
    var bytes = _bytes.sublist(startxref);
    var dat = utf8.decode(bytes);
    while (bytes.isNotEmpty) {
      var read = bytes.sublist(0, 4);
    }

//    for(var element in dat.split('\n')) {
//      if(element.trim()=='trailer') break;
//      print(hex.encode(element.codeUnits));
//    }
  }

  void unbyte(int chr1) {
    _bytes=Uint8List.fromList([chr1]+_bytes);
  }

  Uint8List bytes([int len = 1]) {
    try{
      var start=_position;
      _position+=len;
      return _bytes.sublist(start, start+len);
    }catch(e){
      return null;
    }
  }

  int byte([int len = 1]) {
    try{
      var start=_position;
      _position+=len;
      return _bytes.sublist(start, start+len).first;
    }catch(e){
      return null;
    }
  }

  void checkWord() {
    if (word.isNotEmpty) {
      var key=slash + wordStr;
      if (words.containsKey(key)) {
        words[key]++;
        if(wordsIndex.containsKey(key)){
          wordsIndex[key].add(_position);
        }else{
          wordsIndex[key]=[_position];
        }
        if(key=='/BaseFont') checkFont();
      }
    }
    word.clear();
  }

  void checkFont() {
    word.clear();

    while(true){
      chr = byte();
      if (chr == slashCode) {
        break;
      }else{
        word.writeCharCode(chr);
      }
      if(isByteOut()) break;
    }
    print('checkFont:${wordStr.trim()}');
    word.clear();
  }




}

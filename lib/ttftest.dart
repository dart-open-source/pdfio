import 'dart:io';
import 'package:pdfio/pdf.dart';

void main()  {

  var pathFonts=Directory.current.path+'/fonts/';
  var  fontData = File('$pathFonts/STSONG.TTF').readAsBytesSync();
  var  font = TtfParser(fontData.buffer.asByteData());
  print('{font.fontName=${font.fontName}');
  print('{font.charToGlyphIndexMap=${font.charToGlyphIndexMap.length}');

  var ttfWriter = TtfWriter(font);
  var data = ttfWriter.withChars('你好 國!'.runes.toList());
  var output = File('$pathFonts/${font.fontName}d.ttf');
  output.writeAsBytesSync(data);
}
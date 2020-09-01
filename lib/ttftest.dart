import 'dart:io';
import 'package:pdfio/pdf.dart';

void main()  {


  var str='  نۇرئالىمجان پەيزۇللا  '.runes.toList();

  print('str:${str}');
  var pathFonts=Directory.current.path+'/fonts/';
  var  fontData = File('$pathFonts/Amiri-Bold.ttf').readAsBytesSync();
  var  font = TtfParser(fontData.buffer.asByteData());
  print('{font.fontName=${font.fontName}');
  print('{font.charToGlyphIndexMap=${font.charToGlyphIndexMap.length}');

  var ttfWriter = TtfWriter(font);
  var data = ttfWriter.withChars(str);
  var output = File('$pathFonts/${font.fontName}d.ttf');
  output.writeAsBytesSync(data);
}
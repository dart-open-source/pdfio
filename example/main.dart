// ignore_for_file: always_specify_types

import 'dart:io';

import 'package:alm/alm.dart';
import 'package:pdfio/pdf.dart';

void main() {
  var st=Alm.timeint();
  var pdf = PdfDocument();
  PdfPage(pdf).addImageFile(File('/Users/alm/Documents/test-1.jpg'));
  PdfPage(pdf).addImageFile(File('/Users/alm/Documents/test-2.jpg'));
  var bytes = pdf.save();
  print(Alm.timediff(st));
  File('build/jpeg.pdf').writeAsBytesSync(bytes);
  File('build/jpeg.pdf.txt').writeAsBytesSync(bytes);
  print(Alm.timediff(st));
}

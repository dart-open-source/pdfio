import 'dart:convert';
import 'dart:io';

import 'package:pdfio/pdf.dart';
import 'package:pdfio/widgets.dart';

void main() {
  var pdf = PdfDocument();
  PdfPage(pdf).addImageFile(File('/Users/alm/Documents/test-1.jpg'));
  PdfPage(pdf).addImageFile(File('/Users/alm/Documents/test-2.jpg'));
  var bytes = pdf.save();
  File('build/jpeg.pdf').writeAsBytesSync(bytes);
  File('build/jpeg.pdf.txt').writeAsBytesSync(bytes);
}

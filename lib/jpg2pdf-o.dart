import 'dart:convert';
import 'dart:io';

import 'package:pdfio/pdf.dart';
import 'package:pdfio/widgets.dart';


void main() {
  var pdf = Document();
  var image = PdfImage.jpeg(
      pdf.document,
      image: File('/Users/alm/Documents/test-1.jpg').readAsBytesSync(),
  );
  pdf.addPage(Page(
    pageFormat: PdfPageFormat.a4,
    margin: EdgeInsets.all(0),
    build: (Context context) => Image(image,fit: BoxFit.fill),
  ));
  var bytes=pdf.save();
  File('test.pdf').writeAsBytesSync(bytes);
  File('test.pdf.txt').writeAsBytesSync(bytes);
}

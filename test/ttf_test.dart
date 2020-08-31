/*
 * Copyright (C) 2017, David PHAM-VAN <dev.nfet.net@gmail.com>
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// ignore_for_file: omit_local_variable_types

import 'dart:io';
import 'dart:typed_data';

import 'package:pdfio/pdf.dart';
import 'package:test/test.dart';

void printText(PdfGraphics canvas, String text, PdfFont font, double top) {
  text = text + font.fontName;
  const double fontSize = 20;
  final PdfFontMetrics metrics = font.stringMetrics(text) * fontSize;
  const double deb = 5;
  const double x = 50;
  final double y = canvas.page.pageFormat.height - top;

  canvas
    ..drawRect(x + metrics.left, y + metrics.top, metrics.width, metrics.height)
    ..setColor(const PdfColor(0.9, 0.9, 0.9))
    ..fillPath()
    ..drawLine(x + metrics.left - deb, y, x + metrics.right + deb, y)
    ..setColor(PdfColors.blue)
    ..strokePath()
    ..drawLine(x + metrics.left - deb, y + metrics.ascent, x + metrics.right + deb, y + metrics.ascent)
    ..setColor(PdfColors.green)
    ..strokePath()
    ..drawLine(x + metrics.left - deb, y + metrics.descent, x + metrics.right + deb, y + metrics.descent)
    ..setColor(PdfColors.purple)
    ..strokePath()
    ..setColor(const PdfColor(0.3, 0.3, 0.3))
    ..drawString(font, fontSize, text, x, y);
}

void printTextTtf(PdfGraphics canvas, String text, File ttfFont, double top) {
  final Uint8List fontData = ttfFont.readAsBytesSync();
  final PdfTtfFont font = PdfTtfFont(canvas.page.pdfDocument, fontData.buffer.asByteData());
  printText(canvas, text, font, top);
}
var pathFonts=Directory.current.path+'/fonts/';

void main() {
  test('Pdf TrueType', () {
    final PdfDocument pdf = PdfDocument();
    final PdfPage page = PdfPage(pdf, pageFormat: PdfPageFormat.a4);
    final PdfGraphics g = page.getGraphics();
    int top = 2;
    //74968
    printTextTtf(g, 'Hello ', File('$pathFonts/INFROMAN.TTF'), 30.0 + 30.0 * top++);
    printText(g, 'Alm.Pazel ', PdfFont.helvetica(pdf), 30.0 + 30.0 * top++);
    printTextTtf(g, '你好 ', File('$pathFonts/STSONG.TTF'), 30.0 + 30.0 * top++);
    final File file = File('ttf-2.pdf');
    file.writeAsBytesSync(pdf.save());
  });
}
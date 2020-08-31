# 20080518
# 20080519

import mPDF
import time
import zlib
import sys

oPDF = mPDF.cPDF('pdffile.pdf.txt')
oPDF.header()
oPDF.template1()
oPDF.stream(5, 0, """BT /F1 12 Tf 100 700 Td 15 TL 
(Hello World PDF Generated) Tj 
(Second Line) ' 
(Third Line) ' 
ET
100 712 100 -100 re S""")
oPDF.stream(6, 0, "BT /F1 24 Tf 100 700 Td (Hello World) Tj ET")
oPDF.xrefAndTrailer("1 0 R")

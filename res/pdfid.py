#!/usr/bin/python3

__description__ = 'Tool to test a PDF file'
__author__ = 'Alm Pazel'
__version__ = '0.2.7'
__date__ = '2020/8/17'

import sys

class cBinaryFile:
    def __init__(self, file):
        self.file = file
        try:
            self.infile = open(file, 'rb')
        except:
            print('Error opening file %s' % file)
            print(sys.exc_info()[1])
            sys.exit()

        self.ungetted = []

    def byte(self):
        if len(self.ungetted) != 0:
            return self.ungetted.pop()
        inbyte = self.infile.read(1)
        if not inbyte or inbyte == '':
            self.infile.close()
            return None
        return ord(inbyte)

    def bytes(self, size):
        if size <= len(self.ungetted):
            result = self.ungetted[0:size]
            del self.ungetted[0:size]
            return result
        inbytes = self.infile.read(size - len(self.ungetted))
        if inbytes == '':
            self.infile.close()
        if type(inbytes) == type(''):
            result = self.ungetted + [ord(b) for b in inbytes]
        else:
            result = self.ungetted + [b for b in inbytes]
        self.ungetted = []
        return result

    def unget(self, byte):
        self.ungetted.append(byte)

    def ungets(self, bytes):
        bytes.reverse()
        self.ungetted.extend(bytes)



def FindPDFHeaderRelaxed(oBinaryFile):
    bytes = oBinaryFile.bytes(1024)
    index = ''.join([chr(byte) for byte in bytes]).find('%PDF')
    if index == -1:
        oBinaryFile.ungets(bytes)
        return [], None
    for endHeader in range(index + 4, index + 4 + 10):
        if bytes[endHeader] == 10 or bytes[endHeader] == 13:
            break
    oBinaryFile.ungets(bytes[endHeader:])
    return bytes[0:endHeader], ''.join([chr(byte) for byte in bytes[index:endHeader]])


def Hexcode2String(char):
    if type(char) == int:
        return '#%02x' % char
    else:
        return char


def SwapCase(char):
    if type(char) == int:
        return ord(chr(char).swapcase())
    else:
        return char.swapcase()


def HexcodeName2String(hexcodeName):
    return ''.join(map(Hexcode2String, hexcodeName))


def SwapName(wordExact):
    return map(SwapCase, wordExact)


def UpdateWords(word, slash, words, lastName, insideStream):
    if word != '':
        if slash + word in words:
            words[slash + word][0] += 1
        if slash == '/':
            lastName = slash + word
        if slash == '':
            if word == 'stream':
                insideStream = True
            if word == 'endstream':
                insideStream = False

    return '', lastName, insideStream



def PDFiD(file):
    word = ''
    lastName = ''
    insideStream = False
    keywords = ['obj',
                'endobj',
                'stream',
                'endstream',
                'xref',
                'trailer',
                'startxref',
                '/Page',
                '/Encrypt',
                '/ObjStm',
                '/JS',
                '/JavaScript',
                '/AA',
                '/OpenAction',
                '/AcroForm',
                '/JBIG2Decode',
                '/RichMedia',
                '/Launch',
                '/EmbeddedFile',
                '/XFA',
                ]
    words = {}
    for keyword in keywords:
        words[keyword] = [0, 0]

    slash = ''

    try:
        o_binary_file = cBinaryFile(file)
        (bytesHeader, pdfHeader) = FindPDFHeaderRelaxed(o_binary_file)
        print(pdfHeader)
        byte = o_binary_file.byte()
        byte_loop=0

        print(byte)
        while byte is not None:
            byte_loop=byte_loop+1
            char = chr(byte)
            if 'A' <= char.upper() <= 'Z' or '0' <= char.upper() <= '9':
                word += char
            elif slash == '/' and char == '#':
                d1 = o_binary_file.byte()
                if d1 is not None:
                    d2 = o_binary_file.byte()
                    if d2 is not None and ('0' <= chr(d1) <= '9' or 'A' <= chr(d1).upper() <= 'F') and (
                            '0' <= chr(d2) <= '9' or 'A' <= chr(d2).upper() <= 'F'):
                        print('d1 %s '% d1)
                        print('d2 %s '% d2)
                        nchr=int(chr(d1) + chr(d2), 16)
                        print('nchr %s '% nchr)
                        word += chr(nchr)
                    else:
                        o_binary_file.unget(d2)
                        o_binary_file.unget(d1)
                        (word, lastName, insideStream) = UpdateWords(word, slash, words, lastName, insideStream)

                else:
                    o_binary_file.unget(d1)
                    (word, lastName, insideStream) = UpdateWords(word, slash, words, lastName, insideStream)

            else:
                (word, lastName, insideStream) = UpdateWords(word, slash, words, lastName, insideStream)
                if char == '/':
                    slash = '/'
                else:
                    slash = ''

            byte = o_binary_file.byte()

    except SystemExit:
        sys.exit()

    print('byteLoop %s' % byte_loop)

    for word in words.keys():
        print(word + ': %s ' % words[word])
    return ''


if __name__ == '__main__':
    PDFiD('/Users/alm/Documents/em3.pdf')

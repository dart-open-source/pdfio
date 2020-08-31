#!/usr/bin/python3

__description__ = 'pdf-parser, use it to parse a PDF document'
__author__ = 'Alm Pazel'
__version__ = '0.2.7'
__date__ = '2020/8/17'
__minimum_python_version__ = (2, 5, 1)
__maximum_python_version__ = (3, 7, 5)

import re
import optparse
import zlib
import binascii
import sys
import os
from io import StringIO

CHAR_WHITESPACE = 1
CHAR_DELIMITER = 2
CHAR_REGULAR = 3

CONTEXT_NONE = 1
CONTEXT_OBJ = 2
CONTEXT_XREF = 3
CONTEXT_TRAILER = 4

PDF_ELEMENT_COMMENT = 1
PDF_ELEMENT_INDIRECT_OBJECT = 2
PDF_ELEMENT_XREF = 3
PDF_ELEMENT_TRAILER = 4
PDF_ELEMENT_STARTXREF = 5
PDF_ELEMENT_MALFORMED = 6


# Convert 2 Bytes If Python 3
def C2BIP3(string):
    if type(string) == bytes:
        return string
    else:
        return bytes([ord(x) for x in string])


def CopyWithoutWhiteSpace(content):
    result = []
    for token in content:
        if token[0] != CHAR_WHITESPACE:
            result.append(token)
    return result


class cByter:
    def __init__(self, file):
        self.file = file
        try:
            self.infile = open(file, 'rb')
        except:
            print('Error opening file %s' % file)
            print(sys.exc_info()[1])
            sys.exit()
        self.ungetted = []
        self.position = -1

    def byte(self):
        if len(self.ungetted) != 0:
            self.position += 1
            return self.ungetted.pop()
        inbyte = self.infile.read(1)
        if not inbyte or inbyte == '':
            self.infile.close()
            return None
        self.position += 1
        return ord(inbyte)

    def unget(self, byte):
        self.position -= 1
        self.ungetted.append(byte)


def CharacterClass(byte):
    if byte == 0 or byte == 9 or byte == 10 or byte == 12 or byte == 13 or byte == 32:
        return CHAR_WHITESPACE
    if byte == 0x28 or byte == 0x29 or byte == 0x3C or byte == 0x3E or byte == 0x5B or byte == 0x5D or byte == 0x7B or byte == 0x7D or byte == 0x2F or byte == 0x25:
        return CHAR_DELIMITER
    return CHAR_REGULAR


def IsNumeric(str):
    return re.match('^[0-9]+', str)


class PDFTokenizer:
    def __init__(self, file):
        self.byter = cByter(file)
        self.ungetted = []

    def Token(self):
        if len(self.ungetted) != 0:
            return self.ungetted.pop()
        if self.byter == None:
            return None
        self.byte = self.byter.byte()
        if self.byte == None:
            self.byter = None
            return None
        elif CharacterClass(self.byte) == CHAR_WHITESPACE:
            file_str = StringIO()
            while self.byte != None and CharacterClass(self.byte) == CHAR_WHITESPACE:
                file_str.write(chr(self.byte))
                self.byte = self.byter.byte()
            if self.byte != None:
                self.byter.unget(self.byte)
            else:
                self.byter = None
            self.token = file_str.getvalue()
            return (CHAR_WHITESPACE, self.token)
        elif CharacterClass(self.byte) == CHAR_REGULAR:
            file_str = StringIO()
            while self.byte != None and CharacterClass(self.byte) == CHAR_REGULAR:
                file_str.write(chr(self.byte))
                self.byte = self.byter.byte()
            if self.byte != None:
                self.byter.unget(self.byte)
            else:
                self.byter = None
            self.token = file_str.getvalue()
            return (CHAR_REGULAR, self.token)
        else:
            if self.byte == 0x3C:
                self.byte = self.byter.byte()
                if self.byte == 0x3C:
                    return (CHAR_DELIMITER, '<<')
                else:
                    self.byter.unget(self.byte)
                    return (CHAR_DELIMITER, '<')
            elif self.byte == 0x3E:
                self.byte = self.byter.byte()
                if self.byte == 0x3E:
                    return (CHAR_DELIMITER, '>>')
                else:
                    self.byter.unget(self.byte)
                    return (CHAR_DELIMITER, '>')
            elif self.byte == 0x25:
                file_str = StringIO()
                while self.byte is not None:
                    file_str.write(chr(self.byte))
                    if self.byte == 10 or self.byte == 13:
                        self.byte = self.byter.byte()
                        break
                    self.byte = self.byter.byte()
                if self.byte is not None:
                    if self.byte == 10:
                        file_str.write(chr(self.byte))
                    else:
                        self.byter.unget(self.byte)
                else:
                    self.byter = None
                self.token = file_str.getvalue()
                return (CHAR_DELIMITER, self.token)
            return (CHAR_DELIMITER, chr(self.byte))

    def TokenIgnoreWhiteSpace(self):
        token = self.Token()
        while token != None and token[0] == CHAR_WHITESPACE:
            token = self.Token()
        return token

    def Tokens(self):
        tokens = []
        token = self.Token()
        while token != None:
            tokens.append(token)
            token = self.Token()
        return tokens

    def unget(self, byte):
        self.ungetted.append(byte)


class cPDFParser:
    def __init__(self, file, verbose=True, extract=None, objstm=None):
        self.context = CONTEXT_NONE
        self.content = []
        self.oPDFTokenizer = PDFTokenizer(file)
        self.verbose = verbose
        self.extract = extract
        self.objstm = objstm

    def GetObject(self):
        while True:
            if self.context == CONTEXT_OBJ:
                self.token = self.oPDFTokenizer.Token()
            else:
                self.token = self.oPDFTokenizer.TokenIgnoreWhiteSpace()

            if self.token:
                # print('token->%s' % str(self.token))
                if self.token[0] == CHAR_DELIMITER:
                    if self.token[1][0] == '%':
                        if self.context == CONTEXT_OBJ:
                            self.content.append(self.token)
                        else:
                            return cPDFElementComment(self.token[1])
                    elif self.token[1] == '/':
                        self.token2 = self.oPDFTokenizer.Token()
                        if self.token2[0] == CHAR_REGULAR:
                            if self.context != CONTEXT_NONE:
                                self.content.append((CHAR_DELIMITER, self.token[1] + self.token2[1]))
                        else:
                            self.oPDFTokenizer.unget(self.token2)
                            if self.context != CONTEXT_NONE:
                                self.content.append(self.token)
                    elif self.context != CONTEXT_NONE:
                        self.content.append(self.token)
                elif self.token[0] == CHAR_WHITESPACE:
                    if self.context != CONTEXT_NONE:
                        self.content.append(self.token)
                else:
                    if self.context == CONTEXT_OBJ:
                        if self.token[1] == 'endobj':
                            self.oPDFElementIndirectObject = cPDFElementIndirectObject(self.objectId, self.objectVersion, self.content, self.objstm)
                            self.context = CONTEXT_NONE
                            self.content = []
                            return self.oPDFElementIndirectObject
                        else:
                            self.content.append(self.token)
                    elif self.context == CONTEXT_TRAILER:
                        if self.token[1] == 'startxref' or self.token[1] == 'xref':
                            self.oPDFElementTrailer = cPDFElementTrailer(self.content)
                            self.oPDFTokenizer.unget(self.token)
                            self.context = CONTEXT_NONE
                            self.content = []
                            return self.oPDFElementTrailer
                        else:
                            self.content.append(self.token)
                    elif self.context == CONTEXT_XREF:
                        if self.token[1] == 'trailer' or self.token[1] == 'xref':
                            self.oPDFElementXref = cPDFElementXref(self.content)
                            self.oPDFTokenizer.unget(self.token)
                            self.context = CONTEXT_NONE
                            self.content = []
                            return self.oPDFElementXref
                        else:
                            self.content.append(self.token)
                    else:
                        if IsNumeric(self.token[1]):
                            self.token2 = self.oPDFTokenizer.TokenIgnoreWhiteSpace()
                            if IsNumeric(self.token2[1]):
                                self.token3 = self.oPDFTokenizer.TokenIgnoreWhiteSpace()
                                if self.token3[1] == 'obj':
                                    self.objectId = int(self.token[1], 10)
                                    self.objectVersion = int(self.token2[1], 10)
                                    self.context = CONTEXT_OBJ
                                else:
                                    self.oPDFTokenizer.unget(self.token3)
                                    self.oPDFTokenizer.unget(self.token2)
                            else:
                                self.oPDFTokenizer.unget(self.token2)

                        elif self.token[1] == 'trailer':
                            self.context = CONTEXT_TRAILER
                            self.content = [self.token]
                        elif self.token[1] == 'xref':
                            self.context = CONTEXT_XREF
                            self.content = [self.token]
                        elif self.token[1] == 'startxref':
                            self.token2 = self.oPDFTokenizer.TokenIgnoreWhiteSpace()
                            if self.token2 and IsNumeric(self.token2[1]):
                                return cPDFElementStartxref(int(self.token2[1], 10))
                            else:
                                self.oPDFTokenizer.unget(self.token2)
            else:
                break


class cPDFElementComment:
    def __init__(self, comment):
        self.type = PDF_ELEMENT_COMMENT
        self.comment = comment


class cPDFElementXref:
    def __init__(self, content):
        self.type = PDF_ELEMENT_XREF
        self.content = content


class cPDFElementTrailer:
    def __init__(self, content):
        self.type = PDF_ELEMENT_TRAILER
        self.content = content

    def Contains(self, keyword):
        data = ''
        for i in range(0, len(self.content)):
            if self.content[i][1] == 'stream':
                break
            else:
                data += Canonicalize(self.content[i][1])
        return data.upper().find(keyword.upper()) != -1


def IIf(expr, truepart, falsepart):
    if expr:
        return truepart
    else:
        return falsepart


class cPDFElementIndirectObject:
    def __init__(self, id, version, content, objstm=None):
        self.type = PDF_ELEMENT_INDIRECT_OBJECT
        self.id = id
        self.version = version
        self.content = content
        self.objstm = objstm
        # fix stream for Ghostscript bug reported by Kurt
        if self.isStream():
            position = len(self.content) - 1
            if position < 0:
                return
            while self.content[position][0] == CHAR_WHITESPACE and position >= 0:
                position -= 1
            if position < 0:
                return
            if self.content[position][0] != CHAR_REGULAR:
                return
            if self.content[position][1] == 'endstream':
                return
            if not self.content[position][1].endswith('endstream'):
                return
            self.content = self.content[0:position] + [
                (self.content[position][0], self.content[position][1][:-len('endstream')])] + [
                               (self.content[position][0], 'endstream')] + self.content[position + 1:]

    def GetType(self):
        content = CopyWithoutWhiteSpace(self.content)
        dictionary = 0
        for i in range(0, len(content)):
            if content[i][0] == CHAR_DELIMITER and content[i][1] == '<<':
                dictionary += 1
            if content[i][0] == CHAR_DELIMITER and content[i][1] == '>>':
                dictionary -= 1
            if dictionary == 1 and content[i][0] == CHAR_DELIMITER and EqualCanonical(content[i][1], '/Type') and i < len(content) - 1:
                return content[i + 1][1]
        return ''

    def GetReferences(self):
        content = CopyWithoutWhiteSpace(self.content)
        references = []
        for i in range(0, len(content)):
            if i > 1 and content[i][0] == CHAR_REGULAR and content[i][1] == 'R' and content[i - 2][0] == CHAR_REGULAR and IsNumeric(content[i - 2][1]) and content[i - 1][0] == CHAR_REGULAR and IsNumeric(content[i - 1][1]):
                references.append((content[i - 2][1], content[i - 1][1], content[i][1]))
        return references

    def isStream(self):
        for i in range(0, len(self.content)):
            if self.content[i][0] == CHAR_REGULAR and self.content[i][1] == 'stream':
                return self.content[0:i]
        return False

    def Contains(self, keyword):
        data = ''
        for i in range(0, len(self.content)):
            if self.content[i][1] == 'stream':
                break
            else:
                data += Canonicalize(self.content[i][1])
        return data.upper().find(keyword.upper()) != -1

    def ContainsName(self, keyword):
        for token in self.content:
            if token[1] == 'stream':
                return False
            if token[0] == CHAR_DELIMITER and EqualCanonical(token[1], keyword):
                return True
        return False

    def StreamContains(self, keyword, filter, casesensitive, regex, overridingfilters):
        if not self.isStream():
            return False
        streamData = self.Stream(filter, overridingfilters)
        if filter and streamData == 'No filters':
            streamData = self.Stream(False, overridingfilters)
        if regex:
            return re.search(keyword, streamData, IIf(casesensitive, 0, re.I))
        elif casesensitive:
            return keyword in streamData
        else:
            return keyword.lower() in streamData.lower()

    def Stream(self, filter=True, overridingfilters=''):
        state = 'start'
        countDirectories = 0
        data = ''
        filters = []
        for i in range(0, len(self.content)):
            if state == 'start':
                if self.content[i][0] == CHAR_DELIMITER and self.content[i][1] == '<<':
                    countDirectories += 1
                if self.content[i][0] == CHAR_DELIMITER and self.content[i][1] == '>>':
                    countDirectories -= 1
                if countDirectories == 1 and self.content[i][0] == CHAR_DELIMITER and EqualCanonical(self.content[i][1], '/Filter'):
                    state = 'filter'
                elif countDirectories == 0 and self.content[i][0] == CHAR_REGULAR and self.content[i][1] == 'stream':
                    state = 'stream-whitespace'
            elif state == 'filter':
                if self.content[i][0] == CHAR_DELIMITER and self.content[i][1][0] == '/':
                    filters = [self.content[i][1]]
                    state = 'search-stream'
                elif self.content[i][0] == CHAR_DELIMITER and self.content[i][1] == '[':
                    state = 'filter-list'
            elif state == 'filter-list':
                if self.content[i][0] == CHAR_DELIMITER and self.content[i][1][0] == '/':
                    filters.append(self.content[i][1])
                elif self.content[i][0] == CHAR_DELIMITER and self.content[i][1] == ']':
                    state = 'search-stream'
            elif state == 'search-stream':
                if self.content[i][0] == CHAR_REGULAR and self.content[i][1] == 'stream':
                    state = 'stream-whitespace'
            elif state == 'stream-whitespace':
                if self.content[i][0] == CHAR_WHITESPACE:
                    whitespace = self.content[i][1]
                    if whitespace.startswith('\x0D\x0A') and len(whitespace) > 2:
                        data += whitespace[2:]
                    elif whitespace.startswith('\x0A') and len(whitespace) > 1:
                        data += whitespace[1:]
                else:
                    data += self.content[i][1]
                state = 'stream-concat'
            elif state == 'stream-concat':
                if self.content[i][0] == CHAR_REGULAR and self.content[i][1] == 'endstream':
                    if filter:
                        if overridingfilters == '':
                            return self.Decompress(data, filters)
                        elif overridingfilters == 'raw':
                            return data
                        else:
                            return self.Decompress(data, overridingfilters.split(' '))
                    else:
                        return data
                else:
                    data += self.content[i][1]
            else:
                return 'Unexpected filter state'
        return filters

    def Decompress(self, data, filters):
        for filter in filters:
            if EqualCanonical(filter, '/FlateDecode') or EqualCanonical(filter, '/Fl'):
                try:
                    data = FlateDecode(data)
                except zlib.error as e:
                    message = 'FlateDecode decompress failed'
                    if len(data) > 0 and ord(data[0]) & 0x0F != 8:
                        message += ', unexpected compression method: %02x' % ord(data[0])
                    return message + '. zlib.error %s' % e.message
            elif EqualCanonical(filter, '/ASCIIHexDecode') or EqualCanonical(filter, '/AHx'):
                try:
                    data = ASCIIHexDecode(data)
                except:
                    return 'ASCIIHexDecode decompress failed'
            elif EqualCanonical(filter, '/ASCII85Decode') or EqualCanonical(filter, '/A85'):
                try:
                    data = ASCII85Decode(data.rstrip('>'))
                except:
                    return 'ASCII85Decode decompress failed'
            elif EqualCanonical(filter, '/LZWDecode') or EqualCanonical(filter, '/LZW'):
                try:
                    data = LZWDecode(data)
                except:
                    return 'LZWDecode decompress failed'
            elif EqualCanonical(filter, '/RunLengthDecode') or EqualCanonical(filter, '/R'):
                try:
                    data = RunLengthDecode(data)
                except:
                    return 'RunLengthDecode decompress failed'
            #            elif i.startswith('/CC')                        # CCITTFaxDecode
            #            elif i.startswith('/DCT')                       # DCTDecode
            else:
                return 'Unsupported filter: %s' % repr(filters)
        if len(filters) == 0:
            return 'No filters'
        else:
            return data


class cPDFElementStartxref:
    def __init__(self, index):
        self.type = PDF_ELEMENT_STARTXREF
        self.index = index


class cPDFElementMalformed:
    def __init__(self, content):
        self.type = PDF_ELEMENT_MALFORMED
        self.content = content


def TrimLWhiteSpace(data):
    while data != [] and data[0][0] == CHAR_WHITESPACE:
        data = data[1:]
    return data


def TrimRWhiteSpace(data):
    while data != [] and data[-1][0] == CHAR_WHITESPACE:
        data = data[:-1]
    return data


class cPDFParseDictionary:
    def __init__(self, content):
        self.content = content
        dataTrimmed = TrimLWhiteSpace(TrimRWhiteSpace(self.content))
        if dataTrimmed == []:
            self.parsed = None
        elif self.isOpenDictionary(dataTrimmed[0]) and (
                self.isCloseDictionary(dataTrimmed[-1]) or self.couldBeCloseDictionary(dataTrimmed[-1])):
            self.parsed = self.ParseDictionary(dataTrimmed)[0]
        else:
            self.parsed = None

    def isOpenDictionary(self, token):
        return token[0] == CHAR_DELIMITER and token[1] == '<<'

    def isCloseDictionary(self, token):
        return token[0] == CHAR_DELIMITER and token[1] == '>>'

    def couldBeCloseDictionary(self, token):
        return token[0] == CHAR_DELIMITER and token[1].rstrip().endswith('>>')

    def ParseDictionary(self, tokens):
        state = 0  # start
        dictionary = []
        while tokens != []:
            if state == 0:
                if self.isOpenDictionary(tokens[0]):
                    state = 1
                else:
                    return None, tokens
            elif state == 1:
                if self.isOpenDictionary(tokens[0]):
                    pass
                elif self.isCloseDictionary(tokens[0]):
                    return dictionary, tokens
                elif tokens[0][0] != CHAR_WHITESPACE:
                    key = Canonicalize(tokens[0][1])
                    value = []
                    state = 2
            elif state == 2:
                if self.isOpenDictionary(tokens[0]):
                    value, tokens = self.ParseDictionary(tokens)
                    dictionary.append((key, value))
                    state = 1
                elif self.isCloseDictionary(tokens[0]):
                    dictionary.append((key, value))
                    return dictionary, tokens

                elif value == [] and tokens[0][0] == CHAR_WHITESPACE:
                    pass
                elif value == [] and tokens[0][1] == '[':
                    value.append(tokens[0][1])
                elif value != [] and value[0] == '[' and tokens[0][1] != ']':
                    value.append(tokens[0][1])
                elif value != [] and value[0] == '[' and tokens[0][1] == ']':
                    value.append(tokens[0][1])
                    dictionary.append((key, value))
                    value = []
                    state = 1
                elif value == [] and tokens[0][1] == '(':
                    value.append(tokens[0][1])
                elif value != [] and value[0] == '(' and tokens[0][1] != ')':
                    if tokens[0][1][0] == '%':
                        tokens = [tokens[0]] + PDFTokenizer(StringIO(tokens[0][1][1:])).Tokens() + tokens[1:]
                        value.append('%')
                    else:
                        value.append(tokens[0][1])
                elif value != [] and value[0] == '(' and tokens[0][1] == ')':
                    value.append(tokens[0][1])
                    balanced = 0
                    for item in value:
                        if item == '(':
                            balanced += 1
                        elif item == ')':
                            balanced -= 1
                    if balanced < 0 and self.verbose:
                        print('todo 11: ' + repr(value))
                    if balanced < 1:
                        dictionary.append((key, value))
                        value = []
                        state = 1
                elif value != [] and tokens[0][1][0] == '/':
                    dictionary.append((key, value))
                    key = Canonicalize(tokens[0][1])
                    value = []
                    state = 2
                else:
                    value.append(Canonicalize(tokens[0][1]))
            tokens = tokens[1:]

    def Retrieve(self):
        return self.parsed

    def PrettyPrintSubElement(self, prefix, e):
        if e[1] == []:
            print('%s  %s' % (prefix, e[0]))
        elif type(e[1][0]) == type(''):
            if len(e[1]) == 3 and IsNumeric(e[1][0]) and e[1][1] == '0' and e[1][2] == 'R':
                joiner = ' '
            else:
                joiner = ''
            value = joiner.join(e[1]).strip()
            reprValue = repr(value)
            if "'" + value + "'" != reprValue:
                value = reprValue
            print('%s  %s %s' % (prefix, e[0], value))
        else:
            print('%s  %s' % (prefix, e[0]))
            self.PrettyPrintSub(prefix + '    ', e[1])

    def PrettyPrintSub(self, prefix, dictionary):
        if dictionary != None:
            # print('%s->' % prefix)
            for e in dictionary:
                self.PrettyPrintSubElement(prefix, e)

    def PrettyPrint(self, prefix):
        self.PrettyPrintSub(prefix, self.parsed)

    def Get(self, select):
        for key, value in self.parsed:
            if key == select:
                return value
        return None

    def GetNestedSub(self, dictionary, select):
        for key, value in dictionary:
            if key == select:
                return self.PrettyPrintSubElement('', [select, value])
            if type(value) == type([]) and len(value) > 0 and type(value[0]) == type((None,)):
                result = self.GetNestedSub(value, select)
                if result != None:
                    return self.PrettyPrintSubElement('', [select, result])
        return None

    def GetNested(self, select):
        return self.GetNestedSub(self.parsed, select)


def FormatOutput(data):
    return ascii(data)


# Fix for http://bugs.python.org/issue11395
def StdoutWriteChunked(data):
    if sys.version_info[0] > 2:
        sys.stdout.buffer.write(data)
    else:
        while data != '':
            sys.stdout.write(data[0:10000])
            try:
                sys.stdout.flush()
            except IOError:
                return
            data = data[10000:]


def IfWIN32SetBinary(io):
    if sys.platform == 'win32':
        import msvcrt
        msvcrt.setmode(io.fileno(), os.O_BINARY)


def PrintOutputObject(object, options):
    print('obj %d %d' % (object.id, object.version))
    print('Type: %s' % Canonicalize(object.GetType()))
    print('Referencing: %s' % ', '.join(map(lambda x: '%s %s %s' % x, object.GetReferences())))
    dataPrecedingStream = object.isStream()
    if dataPrecedingStream:
        print('--stream--')
        oPDFParseDictionary = cPDFParseDictionary(dataPrecedingStream)
    else:
        oPDFParseDictionary = cPDFParseDictionary(object.content)
    oPDFParseDictionary.PrettyPrint(' ')
    print('')
    if options.filter and not options.dump:
        filtered = object.Stream()
        if filtered == []:
            print(' %s' % ascii(object.content))
        else:
            print(' %s' % ascii(filtered))

    if options.dump:
        filtered = object.Stream(options.filter == True)
        if filtered == []:
            filtered = ''
        try:
            fDump = open(options.dump, 'wb')
            try:
                fDump.write(C2BIP3(filtered))
            except:
                print('Error writing file %s' % options.dump)
            fDump.close()
        except:
            print('Error writing file %s' % options.dump)
    print('')
    return


def Canonicalize(sIn):
    if sIn == '':
        return sIn
    elif sIn[0] != '/':
        return sIn
    elif sIn.find('#') == -1:
        return sIn
    else:
        i = 0
        iLen = len(sIn)
        sCanonical = ''
        while i < iLen:
            if sIn[i] == '#' and i < iLen - 2:
                try:
                    sCanonical += chr(int(sIn[i + 1:i + 3], 16))
                    i += 2
                except:
                    sCanonical += sIn[i]
            else:
                sCanonical += sIn[i]
            i += 1
        return sCanonical


def EqualCanonical(s1, s2):
    return Canonicalize(s1) == s2


# http://code.google.com/p/pdfminerr/source/browse/trunk/pdfminer/pdfminer/ascii85.py
def ASCII85Decode(data):
    import struct
    n = b = 0
    out = ''
    for c in data:
        if '!' <= c and c <= 'u':
            n += 1
            b = b * 85 + (ord(c) - 33)
            if n == 5:
                out += struct.pack('>L', b)
                n = b = 0
        elif c == 'z':
            assert n == 0
            out += '\0\0\0\0'
        elif c == '~':
            if n:
                for _ in range(5 - n):
                    b = b * 85 + 84
                out += struct.pack('>L', b)[:n - 1]
            break
    return out


def ASCIIHexDecode(data):
    return binascii.unhexlify(''.join([c for c in data if c not in ' \t\n\r']).rstrip('>'))


# if inflating fails, we try to inflate byte per byte (sample 4da299d6e52bbb79c0ac00bad6a1d51d4d5fe42965a8d94e88a359e5277117e2)
def FlateDecode(data):
    try:
        return zlib.decompress(C2BIP3(data))
    except:
        if len(data) <= 10:
            raise
        oDecompress = zlib.decompressobj()
        oStringIO = StringIO()
        count = 0
        for byte in C2BIP3(data):
            try:
                oStringIO.write(oDecompress.decompress(byte))
                count += 1
            except:
                break
        if len(data) - count <= 2:
            return oStringIO.getvalue()
        else:
            raise


def RunLengthDecode(data):
    f = StringIO(data)
    decompressed = ''
    runLength = ord(f.read(1))
    while runLength:
        if runLength < 128:
            decompressed += f.read(runLength + 1)
        if runLength > 128:
            decompressed += f.read(1) * (257 - runLength)
        if runLength == 128:
            break
        runLength = ord(f.read(1))
    #    return sub(r'(\d+)(\D)', lambda m: m.group(2) * int(m.group(1)), data)
    return decompressed


#### LZW code sourced from pdfminer
# Copyright (c) 2004-2009 Yusuke Shinyama <yusuke at cs dot nyu dot edu>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
# documentation files (the "Software"), to deal in the Software without restriction, including without limitation
# the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software,
# and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

class LZWDecoder(object):
    def __init__(self, fp):
        self.fp = fp
        self.buff = 0
        self.bpos = 8
        self.nbits = 9
        self.table = None
        self.prevbuf = None
        return

    def readbits(self, bits):
        v = 0
        while 1:
            # the number of remaining bits we can get from the current buffer.
            r = 8 - self.bpos
            if bits <= r:
                # |-----8-bits-----|
                # |-bpos-|-bits-|  |
                # |      |----r----|
                v = (v << bits) | ((self.buff >> (r - bits)) & ((1 << bits) - 1))
                self.bpos += bits
                break
            else:
                # |-----8-bits-----|
                # |-bpos-|---bits----...
                # |      |----r----|
                v = (v << r) | (self.buff & ((1 << r) - 1))
                bits -= r
                x = self.fp.read(1)
                if not x: raise EOFError
                self.buff = ord(x)
                self.bpos = 0
        return v

    def feed(self, code):
        x = ''
        if code == 256:
            self.table = [chr(c) for c in range(256)]  # 0-255
            self.table.append(None)  # 256
            self.table.append(None)  # 257
            self.prevbuf = ''
            self.nbits = 9
        elif code == 257:
            pass
        elif not self.prevbuf:
            x = self.prevbuf = self.table[code]
        else:
            if code < len(self.table):
                x = self.table[code]
                self.table.append(self.prevbuf + x[0])
            else:
                self.table.append(self.prevbuf + self.prevbuf[0])
                x = self.table[code]
            l = len(self.table)
            if l == 511:
                self.nbits = 10
            elif l == 1023:
                self.nbits = 11
            elif l == 2047:
                self.nbits = 12
            self.prevbuf = x
        return x

    def run(self):
        while 1:
            try:
                code = self.readbits(self.nbits)
            except EOFError:
                break
            x = self.feed(code)
            yield x
        return


####

def LZWDecode(data):
    return ''.join(LZWDecoder(StringIO(data)).run())


def GetArguments():
    arguments = sys.argv[1:]
    envvar = os.getenv('PDFPARSER_OPTIONS')
    if envvar is None:
        return arguments
    return envvar.split(' ') + arguments


def Main():
    oParser = optparse.OptionParser(usage='usage: %prog [options] pdf-file|zip-file|url\n' + __description__, version='%prog ' + __version__)
    oParser.add_option('-m', '--man', action='store_true', default=False, help='Print manual')
    oParser.add_option('-s', '--search', help='string to search in indirect objects (except streams)')
    oParser.add_option('-f', '--filter', action='store_true', default=False, help='pass stream object through filters (FlateDecode, ASCIIHexDecode, ASCII85Decode, LZWDecode and RunLengthDecode only)')
    oParser.add_option('-o', '--object', help='id(s) of indirect object(s) to select, use comma (,) to separate ids (version independent)')
    oParser.add_option('-d', '--dump', help='filename to dump stream content to')

    (options, args) = oParser.parse_args(GetArguments())
    if options.man:
        oParser.print_help()
        return 0
    else:

        oPDFParser = cPDFParser('f-docx.pdf')

        while True:
            object = oPDFParser.GetObject()
            if object is None:
                break
            else:
                if object.type == PDF_ELEMENT_COMMENT:
                    print('PDF Comment %s' % ascii(object.comment))
                    print('')
                elif object.type == PDF_ELEMENT_XREF:
                    print('xref %s' % object)
                elif object.type == PDF_ELEMENT_STARTXREF:
                    print('startxref %d' % object.index)
                    print('')
                elif object.type == PDF_ELEMENT_INDIRECT_OBJECT:
                    if options.search:
                        if object.Contains(options.search):
                            PrintOutputObject(object, options)
                    elif options.object:
                        if str(object.id) in options.object.split(','):
                            PrintOutputObject(object, options)
                    else:
                        PrintOutputObject(object, options)


if __name__ == '__main__':
    print('Python.version %s' % sys.version_info[0])
    # print(IsNumeric('version2'))
    # print(IsNumeric('23231-032'))
    # print('erer-endstreamdede'[:-len('endstream')])
    Main()


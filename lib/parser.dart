import 'dart:convert';
import 'dart:io';
import 'package:alm/alm.dart';
import 'package:byter/byter.dart';
import 'package:collection/collection.dart';

class PDFToken {
  final int type;
  final Byter value;
  Function eq = const ListEquality().equals;

  PDFToken(this.type, this.value);

  bool get isRegular => type == PDFTokenizer.CHAR_REGULAR;

  bool get isWhiteSpace => type == PDFTokenizer.CHAR_WHITESPACE;

  bool get isDelimiter => type == PDFTokenizer.CHAR_DELIMITER;

  @override
  String toString() {
    return '{ $type,${value} }';
  }

  bool isComment() => eq('%'.codeUnits, value.buffer);

  bool isSlash() => eq('/'.codeUnits, value.buffer);

  bool hasDelimiter(String s) => isDelimiter && isContains(s);

  bool isOpen() {
    return hasDelimiter('<<') || hasDelimiter('[') || hasDelimiter('(');
  }

  bool isClose() {
    return hasDelimiter('>>') || hasDelimiter(']') || hasDelimiter(')');
  }

  bool isContains(String s) => value.isContains(s);

  List numericCodeUnits = '0123456789'.codeUnits;

  bool get isNumeric {
    if (value.isEmpty) return false;
    return numericCodeUnits.contains(value.first);
  }

  bool endWith(String s) {
    var sl = s.codeUnits.length;
    if (sl <= value.length) {
      var temp = value.buffer.sublist(value.length - sl, value.length);
      return eq(temp, s.codeUnits);
    }
    return false;
  }

  bool startWith(String s) {
    var sl = s.codeUnits.length;
    if (sl <= value.length) {
      var temp = value.buffer.sublist(0, sl);
      return eq(temp, s.codeUnits);
    }
    return false;
  }

  Byter endCut(String s) {
    var sl = s.codeUnits.length;
    if (sl <= value.length) {
      return Byter(value.buffer.sublist(0, value.length - sl));
    }
    return Byter([]);
  }

  String strVal() => value.str();
}

class PDFTokenizer {
  static int CHAR_WHITESPACE = 1;
  static int CHAR_DELIMITER = 2;
  static int CHAR_REGULAR = 3;

  Byter byter;
  PDFToken token;
  List<PDFToken> ungetted = [];
  int byte;

  PDFTokenizer(this.byter);

  Byter newByter = Byter([]);

  bool get isRegular => character() == CHAR_REGULAR;

  bool get isWhiteSpace => character() == CHAR_WHITESPACE;

  bool get byterNull => byter == null;

  bool get byteNull => byte == null;

  void ifNullNyte({bool isTen = false}) {
    if (byte != null) {
      if (isTen && byte == 10) {
        newByter.add(byte);
      } else {
        byter.nyte();
      }
    } else {
      byter = null;
    }
  }

  void oneByte() => byte = byter.byte();

  PDFToken getToken() {
    if (ungetted.isNotEmpty) return pop();
    if (byterNull) return null;
    oneByte();
    if (byteNull) return null;
    if (isWhiteSpace) {
      newByter.clear();
      while (!byteNull && isWhiteSpace) {
        newByter.add(byte);
        oneByte();
      }
      ifNullNyte();
      return PDFToken(CHAR_WHITESPACE, newByter.clone(reset: true));
    } else if (isRegular) {
      newByter.clear();
      while (!byteNull && isRegular) {
        newByter.add(byte);
        oneByte();
      }
      ifNullNyte();
      return PDFToken(CHAR_REGULAR, newByter.clone(reset: true));
    } else {
      if (byte == 0x3C) {
        oneByte();
        if (byte == 0x3C) {
          return PDFToken(CHAR_DELIMITER, Byter('<<'.codeUnits));
        } else {
          byter.nyte();
          return PDFToken(CHAR_DELIMITER, Byter('<'.codeUnits));
        }
      } else if (byte == 0x3E) {
        oneByte();
        if (byte == 0x3E) {
          return PDFToken(CHAR_DELIMITER, Byter('>>'.codeUnits));
        } else {
          byter.nyte();
          return PDFToken(CHAR_DELIMITER, Byter('>'.codeUnits));
        }
      } else if (byte == 0x25) {
        newByter.clear();
        while (!byteNull) {
          newByter.add(byte);
          if (byte == 10 || byte == 13) {
            oneByte();
            break;
          }
          oneByte();
        }
        ifNullNyte(isTen: true);
        return PDFToken(CHAR_DELIMITER, newByter.clone(reset: true));
      }
      newByter.clear();
      newByter.add(byte);
      return PDFToken(CHAR_DELIMITER, newByter.clone(reset: true));
    }
  }

  PDFToken getTokenIgnoreWhiteSpace() {
    token = getToken();
    while (token != null && token.isWhiteSpace) {
      token = getToken();
    }
    return token;
  }

  List<PDFToken> getTokens() {
    var tokens = <PDFToken>[];
    token = getToken();
    while (token != null) {
      token = getToken();
      tokens.add(token);
    }
    return tokens;
  }

  int character() {
    if ([0, 9, 10, 12, 13, 32].contains(byte)) return CHAR_WHITESPACE;
    if ([0x28, 0x29, 0x3C, 0x3E, 0x5B, 0x5D, 0x7B, 0x7D, 0x2F, 0x25].contains(byte)) return CHAR_DELIMITER;
    return CHAR_REGULAR;
  }

  void unget(PDFToken value) => ungetted.add(value);

  PDFToken pop() {
    var l = ungetted.last;
    ungetted.removeLast();
    return l;
  }
}

class PDFObject {
  Byter objectId;
  Byter objectVer;
  List<PDFToken> content = [];
  List<PDFToken> stream = [];

  PDFDictionary dictionary;
  int dictionaryC = 0;

  PDFObject(this.objectId, this.objectVer, this.content) {
    parseStream();
  }

  bool get isStream => stream.isNotEmpty;

  List<PDFToken> copyWithoutWhiteSpace() {
    var result = <PDFToken>[];
    content.forEach((element) {
      if (!element.isWhiteSpace) result.add(element);
    });
    return result;
  }

  @override
  String toString() {
    var result = <String>[];
    result.add('Object ${objectId.str()} ${objectVer.str()}');
    result.add('Type: ${getType()}');
    result.add('Referencing: ${getReferences()}');
    result.add('Content: ${content.length} Stream: ${stream.length}');
    dictionary = PDFDictionary(List.from(content));
    result.add(JsonEncoder.withIndent('  ').convert(dictionary.parsed));
    result.add('');
    return result.join('\n');
  }

  void parseStream() {
    for (var i = 0; i < content.length; i++) {
      if (content[i].isRegular && content[i].isContains('stream')) {
        stream = content.sublist(i);
        content = content.sublist(0, i);
      }
    }
    if (isStream) {
      var position = stream.length - 1;
      if (position < 0) return;
      while (stream[position].isWhiteSpace && position >= 0) {
        position -= 1;
      }
      if (position < 0) return;
      var currentContent = stream[position];

      if (!currentContent.isRegular) return;
      if (!currentContent.isContains('endstream')) return;
      if (!currentContent.endWith('endstream')) return;
      var beforeContent = stream.sublist(0, position);
      var afterContent = stream.sublist(position + 1);
      stream.clear();
      stream.addAll(beforeContent);
      stream.add(PDFToken(currentContent.type, currentContent.endCut('endstream')));
      stream.add(PDFToken(currentContent.type, Byter('endstream'.codeUnits)));
      stream.addAll(afterContent);
    }
  }

  String getType() {
    dictionaryC = 0;
    var cons = copyWithoutWhiteSpace();
    var i = 0;
    for (var token in cons) {
      if (token.isDelimiter && token.isContains('<<')) {
        dictionaryC += 1;
      }
      if (token.isDelimiter && token.isContains('>>')) {
        dictionaryC -= 1;
      }
      if (dictionaryC == 1 && token.isDelimiter && token.isContains('/Type') && i < cons.length - 1) {
        return cons[i + 1].value.str();
      }
      i++;
    }
    return '';
  }

  String getReferences() {
    var cons = copyWithoutWhiteSpace();
    var references = <String>[];
    var i = 0;
    for (var token in cons) {
      if (i > 1 && token.isRegular && token.isContains('R')) {
        if (cons[i - 2].isRegular && cons[i - 2].isNumeric) {
          if (cons[i - 1].isRegular && cons[i - 1].isNumeric) {
            references.add('${cons[i - 2].value.str()} ${cons[i - 1].value.str()} R');
          }
        }
      }
      i++;
    }
    return references.join(' > ');
  }
}

class PDFTrailer {
  List<PDFToken> raw;
  List<PDFToken> data = [];
  List value = [];

  PDFTrailer(this.raw) {
    data.clear();
    for (var element in raw) {
      if (!element.isWhiteSpace) {
        data.add(element);
        value.add(element.value.str());
      }
    }
    if (data.isEmpty) return;
  }

  @override
  String toString() {
    return 'PDFTrailer{ ${value.join(' ')} }';
  }
}

class PDFDictionary {
  List<PDFToken> data = [];
  List<PDFToken> raw;
  dynamic parsed = {};
  int state = 0;
  List value = [];

  PDFDictionary(this.raw) {
    data.clear();
    for (var element in raw) {
      if (!element.isWhiteSpace) {
        data.add(element);
        value.add(element.value.str().trim());
      }
    }
    if (data.isEmpty) return;
    var token = popToken();
    if (token.isOpen()) parsed = parseDictionary(token);
  }

  @override
  String toString() {
    return 'PDFDictionary ${value.join(' ')}';
  }

  PDFToken popToken() {
    PDFToken res;
    if (data.isNotEmpty) {
      res = data.first;
      if (data.isNotEmpty) data.removeAt(0);
    }
    return res;
  }

  dynamic parseDictionary(PDFToken open) {
    var dictionary = {};
    var list = [];
    if (open.hasDelimiter('<<')) {
      var keyToken = popToken();
      while (keyToken != null && !keyToken.isClose()) {
        //find key
        var key = keyToken.strVal();

        //find value
        var valToken = popToken();
        if (valToken == null || valToken.isClose()) break;
        if (valToken.isOpen()) {
          dictionary[key] = parseDictionary(valToken);
        } else {
          var val = [];
          val.add(valToken.strVal());
          if (!valToken.isContains('/')) {
            while (data.isNotEmpty) {
              valToken = popToken();
              if (valToken.isContains('/') || valToken.isClose()) break;
              val.add(valToken.strVal());
            }
            if (!valToken.isClose()) unget(valToken);
          }
          dictionary[key] = val.join(' ');
        }
        keyToken = popToken();
      }
      return dictionary;
    }
    if (open.hasDelimiter('[') || open.hasDelimiter('(')) {
      var value = popToken();
      while (value != null) {
        if (value == null || value.isClose()) break;
        if (value.isOpen()) {
          list.add(parseDictionary(value));
        } else {
          list.add(value.strVal());
        }
        value = popToken();
      }
      return list.join(' ');
    }
    return {};
  }

  void unget(PDFToken token) {
    data.insert(0, token);
  }
}

class PDFComment {
  PDFToken content;

  PDFComment(this.content);

  @override
  String toString() {
    return 'PDFComment ${content.value.str()} ';
  }
}

class PDFXref {
  List<PDFToken> content;

  PDFXref(this.content);

  @override
  String toString() {
    return 'PDFXref{\n ${content.map((e) => e.value.str()).toList().join(' ').replaceAll('f', 'n').split('n').join('\n')} \n}';
  }
}

class PDFStartXref {
  PDFToken token;

  PDFStartXref(this.token);

  @override
  String toString() {
    return 'PDFStartXref{ ${token.value.str()} }';
  }
}

class PDFObjecter {
  final PDFTokenizer tokenizer;

  static int CONTEXT_NONE = 1;
  static int CONTEXT_OBJ = 2;
  static int CONTEXT_XREF = 3;
  static int CONTEXT_TRAILER = 4;

  int context = CONTEXT_NONE;
  PDFToken token;
  PDFToken token2;
  PDFToken token3;

  List<PDFToken> content = [];

  dynamic objectId;
  dynamic objectVer;

  PDFObjecter(this.tokenizer);

  bool get isContextNoNone => context != CONTEXT_NONE;

  bool get isContextObject => context == CONTEXT_OBJ;

  bool get isContextTrailer => context == CONTEXT_TRAILER;

  bool get isContextXref => context == CONTEXT_XREF;

  dynamic getObject() {
    while (true) {
      if (isContextObject) {
        token = tokenizer.getToken();
      } else {
        token = tokenizer.getTokenIgnoreWhiteSpace();
      }
      if (token == null) break;
      if (token.isDelimiter) {
        if (token.isComment()) {
          if (isContextObject) {
            content.add(token);
          } else {
            return PDFComment(token);
          }
        } else if (token.isSlash()) {
          token2 = tokenizer.getToken();
          if (token2.isRegular) {
            if (isContextNoNone) {
              var newt = Byter(token.value.buffer + token2.value.buffer);
              content.add(PDFToken(PDFTokenizer.CHAR_DELIMITER, newt));
            }
          } else {
            tokenizer.unget(token2);
            if (isContextNoNone) content.add(token);
          }
        } else if (isContextNoNone) content.add(token);
      } else if (token.isWhiteSpace) {
        if (isContextNoNone) content.add(token);
      } else {
        if (isContextObject) {
          if (token.isContains('endobj')) {
            var o = PDFObject(objectId, objectVer, List.from(content));
            context = CONTEXT_NONE;
            content.clear();
            return o;
          } else {
            content.add(token);
          }
        } else if (isContextTrailer) {
          if (token.isContains('startxref') || token.isContains('xref')) {
            var t = PDFTrailer(List.from(content));
            tokenizer.unget(token);
            context = CONTEXT_NONE;
            content.clear();
            return t;
          } else {
            content.add(token);
          }
        } else if (isContextXref) {
          if (token.isContains('trailer') || token.isContains('xref')) {
            var t = PDFXref(List.from(content));
            tokenizer.unget(token);
            context = CONTEXT_NONE;
            content.clear();
            return t;
          } else {
            content.add(token);
          }
        } else {
          if (token.isNumeric) {
            token2 = tokenizer.getTokenIgnoreWhiteSpace();
            if (token2.isNumeric) {
              token3 = tokenizer.getTokenIgnoreWhiteSpace();
              if (token3.isContains('obj')) {
                objectId = token.value;
                objectVer = token2.value;
                context = CONTEXT_OBJ;
              } else {
                tokenizer.unget(token3);
                tokenizer.unget(token2);
              }
            } else {
              tokenizer.unget(token2);
            }
          } else if (token.isContains('trailer')) {
            context = CONTEXT_TRAILER;
            content.add(token);
          } else if (token.isContains('xref')) {
            context = CONTEXT_XREF;
            content.add(token);
          } else if (token.isContains('startxref')) {
            token2 = tokenizer.getTokenIgnoreWhiteSpace();
            if (token2 != null && token2.isNumeric) {
              return PDFStartXref(token2);
            } else {
              tokenizer.unget(token2);
            }
          }
        }
      }
    }
    return null;
  }

  List<dynamic> getObjects([int id]) {
    var list = <dynamic>[];
    while (true) {
      var o = getObject();
      if (o == null) break;
      list.add(o);
    }
    return list;
  }

  static PDFObjecter fromFile(File file) => PDFObjecter(PDFTokenizer(Byter(file.readAsBytesSync())));
}


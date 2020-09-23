

// ignore_for_file: omit_local_variable_types

part of pdf;

class PdfXref {
  /// Creates a cross-reference for a Pdf Object
  /// @param id The object's ID
  /// @param offset The object's position in the file
  /// @param generation The object's generation, usually 0
  PdfXref(this.id, this.offset, {this.generation = 0});

  /// The id of a Pdf Object
  int id;

  /// The offset within the Pdf file
  int offset;

  /// The generation of the object, usually 0
  int generation = 0;

  /// @return The xref in the format of the xref section in the Pdf file
  String ref() {
    final String rs = offset.toString().padLeft(10, '0') +
        ' ' +
        generation.toString().padLeft(5, '0');

    if (generation == 65535) {
      return rs + ' f ';
    }
    return rs + ' n ';
  }
}

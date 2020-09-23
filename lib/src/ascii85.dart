// ignore_for_file: omit_local_variable_types

part of pdf;

class Ascii85Encoder extends Converter<Uint8List, Uint8List> {
  @override
  Uint8List convert(Uint8List input) {
    final Uint8List output = Uint8List(_maxEncodedLen(input.length) + 2);

    int outputOffset = 0;
    int inputOffset = 0;

    while (inputOffset < input.length) {
      output[outputOffset + 0] = 0;
      output[outputOffset + 1] = 0;
      output[outputOffset + 2] = 0;
      output[outputOffset + 3] = 0;
      output[outputOffset + 4] = 0;

      // Unpack 4 bytes into int to repack into base 85 5-byte.
      int value = 0;

      switch (input.length - inputOffset) {
        case 3:
          value |= input[inputOffset + 0] << 24;
          value |= input[inputOffset + 1] << 16;
          value |= input[inputOffset + 2] << 8;
          break;
        case 2:
          value |= input[inputOffset + 0] << 24;
          value |= input[inputOffset + 1] << 16;
          break;
        case 1:
          value |= input[inputOffset + 0] << 24;
          break;
        default:
          value |= input[inputOffset + 0] << 24;
          value |= input[inputOffset + 1] << 16;
          value |= input[inputOffset + 2] << 8;
          value |= input[inputOffset + 3];
      }

      // Special case: zero (!!!!!) shortens to z.
      if (value == 0 && input.length - inputOffset >= 4) {
        output[outputOffset] = 122;
        outputOffset++;
        inputOffset += 4;
        continue;
      }

      // Otherwise, 5 base 85 digits starting at !.
      for (int i = 4; i >= 0; i--) {
        output[outputOffset + i] = 33 + value % 85;
        value ~/= 85;
      }

      if (input.length - inputOffset < 4) {
        // If input was short, discard the low destination bytes.
        outputOffset += input.length - inputOffset + 1;
        break;
      }

      inputOffset += 4;
      outputOffset += 5;
    }

    output[outputOffset] = 0x7e;
    output[outputOffset + 1] = 0x3e;

    return output.sublist(0, outputOffset + 2);
  }

  int _maxEncodedLen(int length) => (length + 3) ~/ 4 * 5;
}

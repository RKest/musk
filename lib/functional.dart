import 'dart:typed_data';

class Functions {
  static bool doesStartWith(Uint8List what, Uint8List that) {
    print("START");
    for (int i = 0; i < what.length; i++)
    {
      print('WHAT: ${what[i]}, THAT: ${that[i]}');
      if (what[i] != that[i]){
        print('I: $i');
        return false;
      }
    }
    print("END");
    return true;
  }
}

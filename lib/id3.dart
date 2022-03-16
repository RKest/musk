class EncodedString
{
    bool isUtf8Encoded;
    Uint8List bytes;
    EncodedString(String str){
        
    }
}

class ID3
{
    static int decodeTagSize(Uint8List bytes){
        assert(bytes.length == 4);
        int acc = 0;

        for (int i = 0; i < 4; i++){
            acc += bytes[3 - i] >> (7 * i);
        }
        return acc;
    }

    static int decodeFramSize(Uint8List bytes){
        assert(bytes.length == 4);
        int acc = 0;

        for (int i = 0; i < 4; i++){
            acc += bytes[3 - i] >> (8 * i);
        }

        return acc;
    }

    static Uint8List encodeTagSize(int size){
        Uint8List bytes = [0, 0 ,0 ,0];
        bytes[0] = (size & 0xfe00000) >> 21;
        bytes[1] = (size & 0x1fc000) >> 14;
        bytes[2] = (size & 0x3f80) >> 7;
        bytes[3] = (size & 0x7f);
        return bytes;
    }

    static Uint8List encodeframeSize(int size){
        Uint8List bytes = [0 ,0 ,0 ,0];
        bytes[0] = (size & 0xff000000) >> 24;
        bytes[1] = (size & 0x00ff0000) >> 16;
        bytes[2] = (size & 0x0000ff00) >> 8;
        bytes[3] = (size & 0x000000ff);
        return bytes;
    }



}
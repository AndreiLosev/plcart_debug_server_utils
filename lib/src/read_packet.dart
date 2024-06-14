import 'dart:typed_data';

import 'package:future_soket/future_soket.dart';
import 'package:msgpack_dart/msgpack_dart.dart';

const packedPrefix = [165, 115, 116, 97, 114, 116];

class PackedPrefixException {
  final String message;

  PackedPrefixException(this.message);

  @override
  String toString() {
    return "$runtimeType : $message";
  }
}

Future<(int, dynamic)> readPacket(FutureSoket soket) async {
  final startBuf = await soket.read(6);

  if (!startPrefixIsvalid(startBuf)) {
    throw PackedPrefixException("start buffer: $startBuf");
  }

  var buf = ByteData.view((await soket.read(5)).buffer);
  final type = buf.getUint8(0);
  final dataLen = buf.getUint32(1);
  final payload = deserialize(await soket.read(dataLen));

  return (type, payload);
}

void writePacket(FutureSoket soket, int type, dynamic payload) {
  final bPayload = serialize(payload);
  final payloadLen = ByteData(4)..setInt32(0, bPayload.length);

  final buffer = Uint8List(11 + bPayload.length);
  setStartPrefix(buffer);
  buffer[6] = type;
  buffer[7] = payloadLen.getUint8(0);
  buffer[8] = payloadLen.getUint8(1);
  buffer[9] = payloadLen.getUint8(2);
  buffer[10] = payloadLen.getUint8(3);

  for (var i = 0; i < bPayload.length; i++) {
    buffer[11 + i] = bPayload[i];
  }

  soket.write(Uint8List.fromList(buffer));
}

bool startPrefixIsvalid(Uint8List readPrefix) {
  return packedPrefix[0] == readPrefix[0] &&
      packedPrefix[1] == readPrefix[1] &&
      packedPrefix[2] == readPrefix[2] &&
      packedPrefix[3] == readPrefix[3] &&
      packedPrefix[4] == readPrefix[4] &&
      packedPrefix[5] == readPrefix[5];
}

void setStartPrefix(Uint8List buffer) {
  buffer[0] = packedPrefix[0];
  buffer[1] = packedPrefix[1];
  buffer[2] = packedPrefix[2];
  buffer[3] = packedPrefix[3];
  buffer[4] = packedPrefix[4];
  buffer[5] = packedPrefix[5];
}

import 'dart:typed_data';

import 'package:msgpack_dart/msgpack_dart.dart';

enum ResponseStatus {
  ok,
  taskNotFound,
  eventNotFound,
  alreadySubscribed,
  internalError;

  int code() => switch (this) {
        ResponseStatus.ok => 0,
        ResponseStatus.taskNotFound => 10,
        ResponseStatus.alreadySubscribed => 15,
        ResponseStatus.eventNotFound => 20,
        ResponseStatus.internalError => 100,
      };
}

extension ToResponseStatus on int {
  ResponseStatus toResponseStatus() => switch (this) {
        0 => ResponseStatus.ok,
        10 => ResponseStatus.taskNotFound,
        15 => ResponseStatus.alreadySubscribed,
        20 => ResponseStatus.taskNotFound,
        100 => ResponseStatus.internalError,
        _ => throw Exception("invalid response status: $this"),
      };
}

class ServerResponse {
  late final ResponseStatus responseStatus;
  late final Map message;

  ServerResponse(this.responseStatus, this.message);

  ServerResponse.ok([this.message = const {'message': 'success'}])
      : responseStatus = ResponseStatus.ok;

  ServerResponse.fromBytes(Uint8List bytes) {
    final map = deserialize(bytes) as Map;
    responseStatus = (map['responseStatus'] as int).toResponseStatus();
    message = map['message'] as Map;
  }
}

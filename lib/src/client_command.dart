import 'dart:typed_data';

import 'package:msgpack_dart/msgpack_dart.dart';

enum CommandKind {
  runEvent,
  subscribeTask,
  unsubscribeTask;

  int code() => switch (this) {
        CommandKind.runEvent => 10,
        CommandKind.subscribeTask => 20,
        CommandKind.unsubscribeTask => 30,
      };
}

extension ToCommandKind on int {
  CommandKind toCommandKind() => switch (this) {
        10 => CommandKind.runEvent,
        20 => CommandKind.subscribeTask,
        30 => CommandKind.unsubscribeTask,
        _ => throw Exception("invalide CommandKind code: $this"),
      };
}

class ClientCommand<T> {
  final CommandKind kind;
  final T payload;

  ClientCommand(this.kind, this.payload);
}

class RunEventPayload {
  late final String eventName;
  late final List positionArguments;
  late final Map<Symbol, dynamic> namedArguments;

  RunEventPayload(Map map) {
    eventName = map['eventName'];
    positionArguments = map['positionArguments'];
    namedArguments = {};
    for (var item in (map['namedArguments'] as Map).entries) {
      namedArguments[Symbol(item.key)] = item.value;
    }
  }
}

ClientCommand parseClientCommand(Uint8List bytes) {
  final map = deserialize(bytes) as Map;
  final kind = (map['CommandKind'] as int).toCommandKind();
  return switch (kind) {
    CommandKind.runEvent => ClientCommand(kind, map['payload']),
    CommandKind.subscribeTask => ClientCommand(kind, map['payload']),
    CommandKind.unsubscribeTask => ClientCommand(kind, map['payload']),
  };
}

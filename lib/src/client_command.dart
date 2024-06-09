import 'dart:typed_data';

import 'package:msgpack_dart/msgpack_dart.dart';

enum CommandKind {
  getRegisteredEvents,
  getRegisteredTasks,
  runEvent,
  subscribeTask,
  unsubscribeTask,
  setTaskValue;

  int code() => switch (this) {
        CommandKind.getRegisteredEvents => 3,
        CommandKind.getRegisteredTasks => 5,
        CommandKind.runEvent => 10,
        CommandKind.subscribeTask => 20,
        CommandKind.unsubscribeTask => 30,
        CommandKind.setTaskValue => 40,
      };
}

extension ToCommandKind on int {
  CommandKind toCommandKind() => switch (this) {
        3 => CommandKind.getRegisteredEvents,
        5 => CommandKind.getRegisteredTasks,
        10 => CommandKind.runEvent,
        20 => CommandKind.subscribeTask,
        30 => CommandKind.unsubscribeTask,
        40 => CommandKind.setTaskValue,
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

class SetTaskValuePayload {
  final Object value;
  final int? index;
  final String? sIndex;
  final ActionValuePayload? action;

  SetTaskValuePayload(Map map)
      : value = map['value'],
        index = map['index'],
        sIndex = map['sIndex'],
        action = map['action'];
}

enum ActionValuePayload {
  add,
  remove;
}

ClientCommand parseClientCommand(Uint8List bytes) {
  final map = deserialize(bytes) as Map;
  final kind = (map['CommandKind'] as int).toCommandKind();
  return switch (kind) {
    CommandKind.getRegisteredEvents => ClientCommand(kind, null),
    CommandKind.getRegisteredTasks => ClientCommand(kind, null),
    CommandKind.runEvent =>
      ClientCommand(kind, RunEventPayload(map['payload'])),
    CommandKind.subscribeTask => ClientCommand(kind, map['payload'] as String),
    CommandKind.unsubscribeTask =>
      ClientCommand(kind, map['payload'] as String),
    CommandKind.setTaskValue => ClientCommand(kind, map['payload']),
  };
}

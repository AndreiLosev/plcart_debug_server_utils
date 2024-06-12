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

class ClientCommand {
  final CommandKind kind;
  final Object? payload;

  ClientCommand(this.kind, this.payload);

  Uint8List toBytes() {
    final serializabe = switch (payload) {
      RunEventPayload() => (payload as RunEventPayload).toSerivalipzbe(),
      SetTaskValuePayload() =>
        (payload as SetTaskValuePayload).toSerivalipzbe(),
      _ => payload,
    };
    return serialize({
      'kind': kind.code(),
      'payload': serializabe,
    });
  }
}

class RunEventPayload {
  late final String eventName;
  late final List positionArguments;
  late final Map<String, dynamic> namedArguments;

  RunEventPayload(this.eventName, this.positionArguments, this.namedArguments);

  RunEventPayload.fromMap(Map map) {
    eventName = map['eventName'];
    positionArguments = map['positionArguments'];
    namedArguments = map['namedArguments'];
  }

  Map<String, dynamic> toSerivalipzbe() {
    return {
      'eventName': eventName,
      'positionArguments': positionArguments,
      'namedArguments': namedArguments,
    };
  }
}

class SetTaskValuePayload {
  final String taskName;
  final Object value;
  final int? index;
  final String? sIndex;
  final ActionValuePayload? action;

  SetTaskValuePayload(Map map)
      : taskName = map['taskName'],
        value = map['value'],
        index = map['index'],
        sIndex = map['sIndex'],
        action = (map['action'] as int?)?.toActionValuePayload();

  Map<String, dynamic> toSerivalipzbe() {
    return {
      'taskName': taskName,
      'value': value,
      'index': index,
      'sIndex': sIndex,
      'action': action?.code(),
    };
  }
}

enum ActionValuePayload {
  add,
  remove;

  int code() => switch (this) {
        ActionValuePayload.add => 1,
        ActionValuePayload.remove => 2,
      };
}

extension ToActionValuePayload on int {
  ActionValuePayload toActionValuePayload() => switch (this) {
        1 => ActionValuePayload.add,
        2 => ActionValuePayload.remove,
        _ => throw Exception("invalid ActionValuePayload code: $this")
      };
}

ClientCommand parseClientCommand(Uint8List bytes) {
  final map = deserialize(bytes) as Map;
  final kind = (map['CommandKind'] as int).toCommandKind();
  return switch (kind) {
    CommandKind.getRegisteredEvents => ClientCommand(kind, null),
    CommandKind.getRegisteredTasks => ClientCommand(kind, null),
    CommandKind.runEvent =>
      ClientCommand(kind, RunEventPayload.fromMap(map['payload'])),
    CommandKind.subscribeTask => ClientCommand(kind, map['payload'] as String),
    CommandKind.unsubscribeTask =>
      ClientCommand(kind, map['payload'] as String),
    CommandKind.setTaskValue => ClientCommand(kind, map['payload']),
  };
}

import 'package:debug_server_utils/debug_server_utils.dart';

enum CommandKind {
  getRegisteredEvents,
  getRegisteredTasks,
  getAllErrors,
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
        CommandKind.getAllErrors => 50,
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
        50 => CommandKind.getAllErrors,
        _ => throw Exception("invalide CommandKind code: $this"),
      };
}

abstract interface class CommandPayload {
  Map<String, dynamic> toMap();
}

class ClientCommand {
  final CommandKind kind;
  final CommandPayload? payload;

  ClientCommand(this.kind, this.payload);
}

class SimplePayload implements CommandPayload {
  String value;

  SimplePayload(Map payload) : value = payload['value'];

  @override
  Map<String, dynamic> toMap() {
    return {'value': value};
  }
}

class RunEventPayload implements CommandPayload {
  late final String eventName;
  late final List positionArguments;
  late final Map<String, dynamic> namedArguments;

  RunEventPayload(this.eventName, this.positionArguments, this.namedArguments);

  RunEventPayload.fromMap(Map map) {
    eventName = map['eventName'];
    positionArguments = map['positionArguments'];
    namedArguments = (map['namedArguments'] as Map).cast();
  }

  @override
  Map<String, dynamic> toMap() {
    return {
      'eventName': eventName,
      'positionArguments': positionArguments,
      'namedArguments': namedArguments,
    };
  }
}

class SetTaskValuePayload implements CommandPayload {
  final ForseValue value;

  SetTaskValuePayload(this.value);

  @override
  Map<String, dynamic> toMap() {
    return value.toMap();
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

ClientCommand parseClientCommand(int type, dynamic payload) {
  final kind = type.toCommandKind();
  return switch (kind) {
    CommandKind.getRegisteredEvents => ClientCommand(kind, null),
    CommandKind.getRegisteredTasks => ClientCommand(kind, null),
    CommandKind.runEvent =>
      ClientCommand(kind, RunEventPayload.fromMap(payload)),
    CommandKind.subscribeTask => ClientCommand(kind, SimplePayload(payload)),
    CommandKind.unsubscribeTask => ClientCommand(kind, SimplePayload(payload)),
    CommandKind.setTaskValue =>
      ClientCommand(kind, SetTaskValuePayload(payload)),
  };
}

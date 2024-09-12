import 'dart:convert';

enum Action {
  assign,
  add,
  remove,
  removeLast;

  static Action parse(String str) {
    switch (str) {
      case '=':
        return Action.assign;
      case ' add ':
        return Action.add;
      case ' remove ':
        return Action.remove;
      case ' removeLast ':
        return Action.removeLast;
      default:
        throw Exception("unknown action: $str");
    }
  }

  @override
  String toString() {
    return switch (this) {
      Action.assign => '=',
      Action.add => ' add ',
      Action.remove => ' remove ',
      Action.removeLast => ' removeLast ',
    };
  }
}

class ForseValue {
  final String task;
  late final String field;
  late final List<String> keys;
  late final dynamic value;
  late final Action action;

  ForseValue(this.task, this.field, this.keys, this.value, this.action);

  ForseValue.fromMap(Map map)
      : task = map['task'],
        field = map['field'],
        keys = (map['keys'] as List).cast(),
        value = map['value'],
        action = Action.parse(map['action']);

  ForseValue.parse(this.task, String text, Iterable<String> fields) {
    action = _getLeftAndRight(text);
    final res = text.split(action.toString()).map((e) => e.trim()).take(2);
    final fieldAndKeys = res.first.trim();
    final sValue = res.last.trim();

    value = _parseValue(sValue);

    for (var fieldName in fields) {
      if (fieldAndKeys.startsWith(fieldName)) {
        field = fieldName;
        text = fieldAndKeys.replaceFirst(fieldName, "");
        break;
      }
    }

    keys = _parseKeys(text);
  }

  Map<String, dynamic> toMap() => {
        "task": task,
        "field": field,
        "keys": keys,
        "value": value,
        "action": action.toString(),
      };

  static Action _getLeftAndRight(String text) {
    for (var type in Action.values) {
      if (text.contains(type.toString())) {
        return type;
      }
    }

    throw Exception("unknown action in: $text");
  }

  static List<String> _parseKeys(String text) {
    return text
        .split('.')
        .map(_parseBrackets)
        .expand((e) => e)
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static Iterable<String> _parseBrackets(String s) {
    final matches = RegExp("\\[([a-zA-Z0-9]|_)+\\]").allMatches(s);
    if (matches.isEmpty) {
      return [s];
    }
    final result = matches.map((m) {
      return m[0]!.substring(1, m[0]!.length - 1).trim();
    });

    return switch (matches.first.start > 0) {
      true => [s.substring(0, matches.first.start), ...result],
      false => result,
    };
  }

  static Object? _parseValue(String sValue) {
    if (sValue == 'null') {
      return null;
    }

    final bValue = bool.tryParse(sValue, caseSensitive: false);
    if (bValue != null) {
      return bValue;
    }

    final iValue = int.tryParse(sValue);
    if (iValue != null) {
      return iValue;
    }

    final dValue = double.tryParse(sValue);
    if (dValue != null) {
      return dValue;
    }

    if (sValue.startsWith("#T")) {
      return sValue;
    }

    final isString = switch (sValue.startsWith("'")) {
      true => sValue.endsWith("'"),
      false => switch (sValue.startsWith('"')) {
          true => sValue.endsWith('"'),
          false => false,
        },
    };

    if (isString) {
      return sValue.substring(1, sValue.length - 1);
    }

    try {
      return jsonDecode(sValue);
    } on FormatException {
      throw Exception(
          "It is not possible to parse a value from a string: $sValue");
    }
  }
}

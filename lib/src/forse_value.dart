import 'dart:convert';

enum Action {
  assign,
  add,
  remove;

  static Action parse(String str) {
    switch (str) {
      case 'assign':
        return Action.assign;
      case 'add':
        return Action.add;
      case 'remove':
        return Action.remove;
      default:
        throw Exception("unknown action: $str");
    }
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
    final (a, d) = _getLeftAndRight(text);
    action = a;
    final res = text.split(d).map((e) => e.trim()).take(2);
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
        "action": action,
      };

  static (Action, String) _getLeftAndRight(String text) {
    if (text.contains('=')) {
      return (Action.assign, '=');
    } else if (text.contains(' add ')) {
      return (Action.add, ' add ');
    } else if (text.contains(' remove ')) {
      return (Action.remove, ' remove ');
    } else {
      throw Exception("unknown action in: $text");
    }
  }

  static List<String> _parseKeys(String text) {
    return text
        .split('.')
        .map((i) {
          final matches = RegExp("\\[([a-zA-Z0-9]|_)+\\]").allMatches(i);
          if (matches.isEmpty) {
            return [i];
          }
          final result = matches.map((m) {
            return m[0]!.substring(1, m[0]!.length - 1).trim();
          });

          return switch (matches.first.start > 0) {
            true => [i.substring(0, matches.first.start), ...result],
            false => result,
          };
        })
        .expand((e) => e)
        .toList();
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

    try {
      return jsonDecode(sValue);
    } on FormatException {
      throw Exception(
          "It is not possible to parse a value from a string: $sValue");
    }
  }
}

import 'package:flutter_qjs/flutter_qjs.dart';

class JsEngine {
  JsEngine._();

  static eval(Map<String, dynamic> injectObj, String code) {
    final engine = FlutterQjs()..dispatch();
    _inject(engine, injectObj, '');

    try {
      return engine.evaluate(code);
    } catch (e) {
      print('[JsEngine] Fail to eval script. \n$e');
    } finally {
      engine.port.close();
    }
  }

  static _inject(
      FlutterQjs engine, Map<String, dynamic> injectObj, String path) {
    final JSInvokable setToObject =
        engine.evaluate('(key, value) => this$path[key] = value;');
    final JSInvokable setPropertyToObject = engine.evaluate(
        '(key, getter, setter) => Object.defineProperty(this$path, key, {get: getter, set: setter})');
    for (final item in injectObj.entries) {
      if (item.value is Function) {
        setToObject.invoke([item.key, IsolateFunction(item.value)]);
      } else if (item.value is ScriptProperty) {
        final sp = item.value as ScriptProperty;
        setPropertyToObject.invoke(
            [item.key, IsolateFunction(sp.getter), IsolateFunction(sp.setter)]);
      } else if (item.value is Map<String, dynamic>) {
        engine.evaluate("this$path['${item.key}'] = {};");
        _inject(engine, item.value, "$path['${item.key}']");
      } else {
        setToObject.invoke([item.key, item.value]);
      }
    }
    setToObject.free();
  }
}

class ScriptProperty {
  late GetterFunction getter;
  late SetterFunction setter;
  ScriptProperty(this.getter, this.setter);
}

typedef GetterFunction = dynamic Function();
typedef SetterFunction = void Function(dynamic value);

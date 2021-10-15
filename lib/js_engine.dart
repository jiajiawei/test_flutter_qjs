import 'package:flutter_qjs/flutter_qjs.dart';

class JsEngine {
  JsEngine._();

  static Future eval(Map<String, dynamic> injectObj, String code) async {
    final engine = FlutterQjs()..dispatch();
    await _inject(engine, injectObj, '');

    final awaitCode = code
        .replaceAll('print', 'await print')
        .replaceAll('alert', 'await alert')
        .replaceAll('parameters', 'await parameters')
        .replaceAllMapped(RegExp('await (parameters.[\\w]+.value[\\s]*=)'),
            (match) => match.group(1)!)
        .replaceAll('controls', 'await controls')
        .replaceAllMapped(RegExp('await (controls.[\\w]+.[\\w]+[\\s]*=)'),
            (match) => match.group(1)!)
        .replaceAll('rootControl', 'await rootControl')
        .replaceAllMapped(RegExp('await (rootControl.[\\w]+[\\s]*=)'),
            (match) => match.group(1)!)
        .replaceAll('template', 'await template')
        .replaceAllMapped(RegExp('await (template.[\\w]+[\\s]*=)'),
            (match) => match.group(1)!)
        .replaceAll('excelLib', 'await excelLib')
        .replaceAll('eventLib', 'await eventLib')
        .replaceAll('ugLib', 'await ugLib');

    try {
      return await engine.evaluate('''
              (async () => {
                $awaitCode
              })()
            ''');
    } catch (e) {
      print('[JsEngine/io] Fail to eval script. \n$e');
    } finally {
      engine.port.close();
    }
  }

  static Future _inject(
      FlutterQjs engine, Map<String, dynamic> injectObj, String path) async {
    final JSInvokable setToObject =
        await engine.evaluate('(key, value) => this$path[key] = value;');
    final JSInvokable setPropertyToObject = await engine.evaluate(
        '(key, getter, setter) => Object.defineProperty(this$path, key, {get: getter, set: setter})');
    for (final item in injectObj.entries) {
      if (item.value is Function) {
        await setToObject.invoke([item.key, IsolateFunction(item.value)]);
      } else if (item.value is ScriptProperty) {
        final sp = item.value as ScriptProperty;
        await setPropertyToObject.invoke(
            [item.key, IsolateFunction(sp.getter), IsolateFunction(sp.setter)]);
      } else if (item.value is Map<String, dynamic>) {
        await engine.evaluate("this$path['${item.key}'] = {};");
        await _inject(engine, item.value, "$path['${item.key}']");
      } else {
        await setToObject.invoke([item.key, item.value]);
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

library source_gen.json_serial.generator;

import 'dart:async';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/utilities_dart.dart';
import 'package:mustache4dart/mustache4dart.dart';

import 'package:source_gen/source_gen.dart';
import 'package:source_gen/src/utils.dart';

import 'json_serializable.dart';

part 'json_serializable_template.dart';

// TODO: toJson option to omit null/empty values
class JsonSerializableGenerator
    extends GeneratorForAnnotation<JsonSerializable> {
  const JsonSerializableGenerator();

  @override
  Future<String> generateForAnnotatedElement(
      Element element, JsonSerializable annotation) async {
    
    if (element is! ClassElement) {
      var friendlyName = frieldlyNameForElement(element);
      throw new InvalidGenerationSourceError(
          'Generator cannot target `$friendlyName`.',
          todo: 'Remove the JsonSerializable annotation from `$friendlyName`.');
    }
    
    var context = <String, dynamic>{};

    var classElement = element as ClassElement;
    var className = classElement.name;
    
    context['className'] = className;
    
    var fieldTypes = classElement.fields.fold(<String, FieldElement>{},
        (map, field) {
      map[field.name] = field;
      return map;
    }) as Map<String, FieldElement>;
    
    //Build mixin class
    if (annotation.createToJson) {

      // Get all of the fields that need to be assigned
      // TODO: support overriding the field set with an annotation option
      var fields = classElement.fields.fold(<Map<String, dynamic>>[],
          (list, field) {
        list.add({
          "name": field.name,
          "type": field.type.name,
          "value": _fieldToJsonMapValue(field.name, field),
          "printComma": true
        });
        return list;
        
      }) as List<Map<String, dynamic>>;
      
      if (!fields.isEmpty) fields.last['printComma'] = false;
      
      context['fields'] = fields;
      context['createToJson'] = true;
    
    }
    
    //Build factory
    if (annotation.createFactory) {
    
      // Get the default constructor
      // TODO: allow overriding the ctor used for the factory
      var ctor = classElement.constructors.singleWhere((ce) => ce.name == '');
      
      // creating a copy so it can be mutated
      var fieldsToSet = new Map<String, FieldElement>.from(fieldTypes);
      
      var ctorArgs = <Map<String, dynamic>>[];
      
      for (var arg in ctor.parameters) {
        var field = fieldTypes[arg.name];
  
        if (field == null) {
          if (arg.parameterKind == ParameterKind.REQUIRED) {
            throw 'Cannot populate the required constructor argument: ${arg.displayName}.';
          }
          continue;
        }
        
        ctorArgs.add({
          "named": arg.parameterKind == ParameterKind.NAMED,
          "name": arg.name,
          "value": _jsonMapAccessToField(arg.name, fieldTypes[arg.name]),
          "printComma": true
        });
        fieldsToSet.remove(arg.name);
        
      }
      
      if (!ctorArgs.isEmpty) ctorArgs.last["printComma"] = false;
      
      var finalFields = fieldsToSet.values.where((field) => field.isFinal).toSet();
  
      if (finalFields.isNotEmpty) {
        throw new InvalidGenerationSourceError(
            'Generator cannot target `$className`.',
            todo: 'Make the following fields writable or add them to the '
            'constructor with matching names: '
            '${finalFields.map((field) => field.name).join(', ')}.');
      }
      
      var ctorFieldsToSet = <Map<String, dynamic>>[];
      fieldsToSet.forEach((name, field) {
        ctorFieldsToSet.add({
          "name": name,
          "value": _jsonMapAccessToField(name, fieldTypes[name]),
        });
      });
      
      if (!ctorFieldsToSet.isEmpty) ctorFieldsToSet.last['printSemicolon'] = true;
    
      context['ctorArgs'] = ctorArgs;
      context['ctorFieldsToSet'] = ctorFieldsToSet;
      context['createFactory'] = true;
      
    }

    return render(template, context);
  }

  @override
  String toString() => 'JsonGenerator';
}

String _fieldToJsonMapValue(String name, FieldElement field) {
  var result = name;

  if (_isDartDateTime(field.type)) {
    return "$name == null ? null : ${name}.toIso8601String()";
  }

  return result;
}

String _jsonMapAccessToField(String name, FieldElement field) {
  var result = "json['$name']";

  if (_isDartDateTime(field.type)) {
    // TODO: this does not take into account that dart:core could be
    // imported with another name
    return "json['$name'] == null ? null : DateTime.parse($result)";
  }

  return result;
}

bool _isDartDateTime(DartType type) {
  return type.element.library.isDartCore && type.name == 'DateTime';
}

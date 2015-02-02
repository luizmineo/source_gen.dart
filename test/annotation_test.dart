import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:unittest/unittest.dart';
import 'package:source_gen/src/utils.dart';
import 'package:analyzer/src/generated/element.dart';
import 'annotation_test/annotations.dart' as defs;

import 'package:source_gen/generator.dart' as gen;

void main() {
  group('match annotations', () {
    LibraryElement libElement;

    setUp(() {
      libElement = _getTestLibElement();
    });

    // name: same, different
    // annotation location: same lib, same lib + part, different lib

    test('annotated with class', () {
      var annotatedClass = _getAnnotationForClass(libElement, 'CtorNoParams');
      var annotation = annotatedClass.metadata.single;
      var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
      expect(matched, isTrue);
    });

    test('annotated with class in a part', () {
      ClassElement annotatedClass =
          _getAnnotationForClass(libElement, 'CtorNoParamsInPart');
      var annotation = annotatedClass.metadata.single;
      var matched = matchAnnotation(defs.PublicAnnotationClass, annotation);
      expect(matched, isTrue);
    });

    test('class in a part annotated with class', () {
      var annotatedClass = _getAnnotationForClass(libElement, 'CtorNoParams');
      var annotation = annotatedClass.metadata.single;
      var matched =
          matchAnnotation(defs.PublicAnnotationClassInPart, annotation);
      expect(matched, isFalse, reason: 'not annotated with that type');
    });

    test('class in a part annotated with class in a part', () {
      ClassElement annotatedClass =
          _getAnnotationForClass(libElement, 'CtorNoParamsInPart');
      var annotation = annotatedClass.metadata.single;
      var matched =
          matchAnnotation(defs.PublicAnnotationClassInPart, annotation);
      expect(matched, isFalse);
    });
  });
}

class _MyAnnotationGen
    extends gen.GeneratorForAnnotation<defs.PublicAnnotationClass> {
  _MyAnnotationGen();

  generateForAnnotatedElement(
      Element element, defs.PublicAnnotationClass annotation) {}
}

LibraryElement _getTestLibElement() {
  var annotatedClassesFilePath =
      p.join(_packagePath, 'test/annotation_test/annotated_classes.dart');
  return getCompilationUnit(
      _packagePath, annotatedClassesFilePath).element.library;
}

ClassElement _getAnnotationForClass(LibraryElement lib, String className) {
  return lib.units
      .expand((cu) => cu.types)
      .singleWhere((cd) => cd.name == className);
}

final _scriptPath = p.fromUri(Platform.script);

final _packagePath = () {
  var currentScriptPath = _scriptPath;

  var testDir = p.dirname(currentScriptPath);
  assert(p.basename(testDir) == 'test');

  return p.dirname(testDir);
}();
library source_gen.test.find_libraries;

import 'dart:async';

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source_io.dart';
import 'package:path/path.dart' as p;
import 'package:unittest/unittest.dart';
import 'package:source_gen/src/io.dart';
import 'package:source_gen/src/utils.dart';

import 'test_utils.dart';

void main() {
  group('check source files against expected libraries', () {
    AnalysisContext context;

    setUp(() async {
      if (context == null) {
        context = await _getContext();
      }
    });

    _testFileMap.forEach((inputPath, expectedLibPath) {
      test(inputPath, () {
        var fullInputPath = _testFilePath(inputPath);

        var libElement = getLibraryElementForSourceFile(context, fullInputPath);

        var libSource = libElement.source as FileBasedSource;

        var fullLibPath = _testFilePath(expectedLibPath);

        expect(p.fromUri(libSource.uri), fullLibPath);
      });
    });
  });
}

@deprecated
Future<AnalysisContext> _getContext() async {
  var context = await getAnalysisContextForProjectPath(getPackagePath());

  var testFilesPath = p.join(getPackagePath(), 'test', 'test_files');

  await getLibraryElements(getFiles(testFilesPath), context).drain();

  expect(context != null, isTrue);

  return context;
}

String _testFilePath(String name) =>
    p.join(getPackagePath(), 'test', 'test_files', name);

const _testFileMap = const {
  'annotated_classes.dart': 'annotated_classes.dart',
  'annotated_classes_part.dart': 'annotated_classes.dart',
  'annotations.dart': 'annotations.dart',
  'annotation_part.dart': 'annotations.dart',
};

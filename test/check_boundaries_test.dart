import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_boundaries.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('gramotune_boundaries_');
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('accepts an import the matrix allows', () async {
    await _write(
      root,
      'packages/engine/lib/good.dart',
      "import 'package:engine_api/engine_api.dart';\n",
    );

    expect(findViolations(root), isEmpty);
  });

  test('fails when the engine imports Flutter', () async {
    await _write(
      root,
      'packages/engine/lib/bad.dart',
      "import 'package:flutter/material.dart';\n",
    );

    final violations = findViolations(root);
    expect(violations, hasLength(1));
    expect(violations.single.message, contains('flutter'));
    expect(violations.single.file, 'packages/engine/lib/bad.dart');
  });

  test('fails when engine_api imports anything but meta', () async {
    await _write(
      root,
      'packages/engine_api/lib/bad.dart',
      "import 'package:collection/collection.dart';\n",
    );

    final violations = findViolations(root);
    expect(violations, hasLength(1));
    expect(violations.single.message, contains('allowed: meta'));
  });

  test('fails when the library imports the engine', () async {
    await _write(
      root,
      'packages/music_library/lib/bad.dart',
      "import 'package:engine/engine.dart';\n",
    );

    expect(
      findViolations(root).single.message,
      contains('must never import package:engine'),
    );
  });

  test('fails when a package imports dart:ffi without permission', () async {
    await _write(
      root,
      'packages/music_library/lib/bad.dart',
      "import 'dart:ffi';\n",
    );

    expect(findViolations(root).single.message, contains('dart:ffi'));
  });

  test('reports a package with no boundary rule', () async {
    await _write(root, 'packages/unknown/lib/thing.dart', '// no imports\n');

    expect(findViolations(root).single.message, contains('no boundary rule'));
  });

  test('the composition root may import everything', () async {
    await _write(
      root,
      'app/lib/main.dart',
      "import 'package:flutter/material.dart';\n"
          "import 'package:engine/engine.dart';\n",
    );

    expect(findViolations(root), isEmpty);
  });
}

Future<void> _write(Directory root, String relative, String contents) async {
  final file = File('${root.path}/$relative');
  await file.parent.create(recursive: true);
  await file.writeAsString(contents);
}

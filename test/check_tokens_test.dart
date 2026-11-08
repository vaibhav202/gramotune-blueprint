import 'dart:io';

import 'package:test/test.dart';

import '../tool/check_tokens.dart';

void main() {
  late Directory root;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('gramotune_tokens_');
  });

  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('flags a literal color outside the token packages', () async {
    await _write(
      root,
      'app/lib/bad.dart',
      'const color = Color(0xFF112233);\n',
    );

    expect(findTokenViolations(root).single.rule, 'literal-color');
  });

  test('allows literal colors inside skin tokens', () async {
    await _write(
      root,
      'packages/skin/lib/tokens.dart',
      'const color = Color(0xFF112233);\n',
    );

    expect(findTokenViolations(root), isEmpty);
  });

  test('flags print but not debugPrint', () async {
    await _write(
      root,
      'app/lib/bad.dart',
      "debugPrint('fine');\nprint('not fine');\n",
    );

    final violations = findTokenViolations(root);
    expect(violations, hasLength(1));
    expect(violations.single.rule, 'print');
  });

  test('ignores calls mentioned in line comments', () async {
    await _write(
      root,
      'app/lib/ok.dart',
      '// never print() a color like Color(0xFF000000)\n',
    );

    expect(findTokenViolations(root), isEmpty);
  });

  test('flags isLeaf: true in the engine', () async {
    await _write(
      root,
      'packages/engine/lib/pump.dart',
      'call(isLeaf: true);\n',
    );

    expect(findTokenViolations(root).single.rule, 'isLeaf');
  });

  test('allows the Flutter host MainActivity.kt', () async {
    await _write(
      root,
      'app/android/app/src/main/kotlin/app/gramotune/MainActivity.kt',
      'package app.gramotune\n',
    );

    expect(findTokenViolations(root), isEmpty);
  });

  test('flags a hand-written Kotlin file elsewhere', () async {
    await _write(
      root,
      'packages/platform_android/android/Helper.kt',
      'package app.gramotune\n',
    );

    expect(findTokenViolations(root).single.rule, 'native-source');
  });
}

Future<void> _write(Directory root, String relative, String contents) async {
  final file = File('${root.path}/$relative');
  await file.parent.create(recursive: true);
  await file.writeAsString(contents);
}

// Static token and source-hygiene checks for docs/08-testing-spec.md §10.
// Wired into tool/check.sh.
import 'dart:io';

/// One static-rule finding.
class Violation {
  /// Creates a violation.
  const Violation({
    required this.file,
    required this.rule,
    required this.message,
  });

  /// Path relative to the repository root.
  final String file;

  /// Short rule id, for tests and logs.
  final String rule;

  /// What went wrong.
  final String message;

  @override
  String toString() => '$file [$rule]: $message';
}

/// Packages whose token files may contain literal colors (AGENTS.md §8).
const Set<String> colorTokenPackages = <String>{'skin', 'ui_kit'};

/// Engine files exempt from the `isLeaf` ban. Empty until a pure function needs
/// the annotation; add file paths relative to the repository root.
const Set<String> isLeafAllowedFiles = <String>{};

/// Kotlin or Java that the Flutter host project requires.
const Set<String> allowedNativeFiles = <String>{
  'app/android/app/src/main/kotlin/app/gramotune/MainActivity.kt',
};

final RegExp _literalColor = RegExp(
  r'\bColor\s*\(|\bColor\.from(?:ARGB|RGBO)\s*\(|\bColors\.',
);
final RegExp _printCall = RegExp(r'(?:^|[^\w.])print\s*\(');
final RegExp _isLeafTrue = RegExp(r'isLeaf\s*:\s*true');

/// Scans `lib/` sources and the repository for violations.
List<Violation> findTokenViolations(
  Directory root, {
  Set<String> isLeafExempt = isLeafAllowedFiles,
  Set<String> nativeAllowlist = allowedNativeFiles,
}) {
  final violations = <Violation>[];
  for (final entry in _packageRoots(root).entries) {
    final package = entry.key;
    final lib = Directory('${entry.value.path}/lib');
    for (final file in _dartFiles(lib)) {
      final relative = _relative(root, file);
      final code = _stripLineComments(file.readAsStringSync());
      if (!colorTokenPackages.contains(package) &&
          _literalColor.hasMatch(code)) {
        violations.add(
          Violation(
            file: relative,
            rule: 'literal-color',
            message: 'literal colors live in skin or ui_kit tokens only',
          ),
        );
      }
      if (_printCall.hasMatch(code)) {
        violations.add(
          Violation(
            file: relative,
            rule: 'print',
            message: 'use the project logger, not print()',
          ),
        );
      }
      if (package == 'engine' &&
          !isLeafExempt.contains(relative) &&
          _isLeafTrue.hasMatch(code)) {
        violations.add(
          Violation(
            file: relative,
            rule: 'isLeaf',
            message: 'blocking native calls must not be isLeaf (D-005)',
          ),
        );
      }
    }
  }
  violations.addAll(_nativeSources(root, nativeAllowlist));
  return violations;
}

Iterable<Violation> _nativeSources(
  Directory root,
  Set<String> allowlist,
) sync* {
  for (final entity in root.listSync(recursive: true, followLinks: false)) {
    if (entity is! File) {
      continue;
    }
    final relative = _relative(root, entity);
    if (!relative.endsWith('.kt') && !relative.endsWith('.java')) {
      continue;
    }
    if (_isSkipped(relative)) {
      continue;
    }
    if (allowlist.contains(relative) ||
        relative.endsWith('GeneratedPluginRegistrant.java')) {
      continue;
    }
    yield Violation(
      file: relative,
      rule: 'native-source',
      message:
          'no hand-written Kotlin or Java outside the Flutter host '
          '(AGENTS.md §7); use jnigen (D-012)',
    );
  }
}

bool _isSkipped(String relative) {
  final parts = relative.split(RegExp(r'[/\\]'));
  return parts.any(
    (part) =>
        part == '.dart_tool' ||
        part == '.gradle' ||
        part == '.idea' ||
        part == 'build',
  );
}

Map<String, Directory> _packageRoots(Directory root) {
  final roots = <String, Directory>{};
  final packages = Directory('${root.path}/packages');
  if (packages.existsSync()) {
    for (final entity in packages.listSync()) {
      if (entity is Directory && Directory('${entity.path}/lib').existsSync()) {
        roots[_basename(entity.path)] = entity;
      }
    }
  }
  final app = Directory('${root.path}/app');
  if (Directory('${app.path}/lib').existsSync()) {
    roots['app'] = app;
  }
  return roots;
}

List<File> _dartFiles(Directory directory) {
  if (!directory.existsSync()) {
    return const <File>[];
  }
  return directory
      .listSync(recursive: true, followLinks: false)
      .whereType<File>()
      .where((file) => file.path.endsWith('.dart'))
      .toList(growable: false);
}

String _stripLineComments(String contents) {
  final buffer = StringBuffer();
  for (final line in contents.split('\n')) {
    final index = line.indexOf('//');
    buffer.writeln(index >= 0 ? line.substring(0, index) : line);
  }
  return buffer.toString();
}

String _basename(String path) => path.split(RegExp(r'[/\\]')).last;

String _relative(Directory root, FileSystemEntity entity) {
  final prefix = root.path.endsWith(Platform.pathSeparator)
      ? root.path
      : '${root.path}${Platform.pathSeparator}';
  return entity.path.startsWith(prefix)
      ? entity.path.substring(prefix.length)
      : entity.path;
}

void main() {
  final violations = findTokenViolations(Directory.current);
  if (violations.isEmpty) {
    stdout.writeln(
      'check_tokens: OK (no literal colors outside tokens, no print(), '
      'no isLeaf: true, no stray Kotlin/Java)',
    );
    return;
  }
  stderr.writeln('check_tokens: ${violations.length} violation(s)');
  for (final violation in violations) {
    stderr.writeln('  $violation');
  }
  exitCode = 1;
}

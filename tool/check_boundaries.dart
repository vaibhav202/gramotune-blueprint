// Package boundary check for AGENTS.md §5. Wired into tool/check.sh.
//
// The rules below are the import matrix, nothing more. Tests live in
// test/check_boundaries_test.dart.
import 'dart:io';

/// The import rules for one package.
class PackageRule {
  /// Creates a rule.
  const PackageRule({
    this.allowedPackages,
    this.bannedPackages = const <String>{},
    this.bannedDartLibraries = const <String>{},
  });

  /// When not null, every `package:` import must come from this allowlist.
  final Set<String>? allowedPackages;

  /// Package names that may never be imported.
  final Set<String> bannedPackages;

  /// `dart:` libraries that may never be imported (for example `ffi`, `ui`).
  final Set<String> bannedDartLibraries;
}

/// The matrix from AGENTS.md §5. Keep the two in sync.
const Map<String, PackageRule> defaultRules = <String, PackageRule>{
  'engine_api': PackageRule(
    allowedPackages: <String>{'meta'},
    bannedDartLibraries: <String>{'ffi', 'ui'},
  ),
  'engine': PackageRule(
    allowedPackages: <String>{'engine_api', 'ffi'},
    bannedDartLibraries: <String>{'ui'},
  ),
  'music_library': PackageRule(
    bannedDartLibraries: <String>{'ffi', 'ui'},
    bannedPackages: <String>{
      'flutter',
      'flutter_test',
      'engine',
      'engine_api',
      'ui_kit',
      'skin',
      'sources',
      'platform_android',
      'app',
      'jni',
    },
  ),
  'sources': PackageRule(
    bannedDartLibraries: <String>{'ffi', 'ui'},
    bannedPackages: <String>{
      'flutter',
      'flutter_test',
      'engine',
      'ui_kit',
      'skin',
      'platform_android',
      'app',
    },
  ),
  'platform_android': PackageRule(
    bannedPackages: <String>{
      'flutter',
      'flutter_test',
      'engine',
      'engine_api',
      'ui_kit',
      'skin',
      'app',
    },
  ),
  'skin': PackageRule(
    bannedPackages: <String>{
      'flutter_test',
      'engine',
      'engine_api',
      'music_library',
      'sources',
      'platform_android',
      'app',
    },
  ),
  'ui_kit': PackageRule(
    bannedPackages: <String>{
      'flutter_test',
      'engine',
      'engine_api',
      'music_library',
      'sources',
      'platform_android',
      'app',
    },
  ),
  // The composition root may import everything.
  'app': PackageRule(),
};

/// One forbidden import.
class Violation {
  /// Creates a violation.
  const Violation({
    required this.file,
    required this.uri,
    required this.message,
  });

  /// Path relative to the repository root.
  final String file;

  /// The offending import URI.
  final String uri;

  /// What went wrong.
  final String message;

  @override
  String toString() => '$file: $message ($uri)';
}

final RegExp _directive = RegExp(
  r'''^\s*(?:import|export)\s+['"]([^'"]+)['"]''',
  multiLine: true,
);

final RegExp _packageUri = RegExp(r'^package:([^/]+)/');

/// Scans every workspace `lib/` directory and returns the rule violations.
List<Violation> findViolations(
  Directory root, {
  Map<String, PackageRule> rules = defaultRules,
}) {
  final violations = <Violation>[];
  for (final entry in _packageRoots(root).entries) {
    final package = entry.key;
    final rule = rules[package];
    if (rule == null) {
      violations.add(
        Violation(
          file: _relative(root, entry.value),
          uri: '',
          message: 'no boundary rule for package "$package"',
        ),
      );
      continue;
    }
    for (final file in _dartFiles(Directory('${entry.value.path}/lib'))) {
      final relative = _relative(root, file);
      for (final match in _directive.allMatches(file.readAsStringSync())) {
        final uri = match.group(1)!;
        final violation = _check(rule, relative, uri);
        if (violation != null) {
          violations.add(violation);
        }
      }
    }
  }
  return violations;
}

Violation? _check(PackageRule rule, String file, String uri) {
  final package = _packageUri.firstMatch(uri)?.group(1);
  if (package != null) {
    final allowed = rule.allowedPackages;
    if (allowed != null && !allowed.contains(package)) {
      return Violation(
        file: file,
        uri: uri,
        message:
            'may not import package:$package '
            '(allowed: ${allowed.join(', ')})',
      );
    }
    if (allowed == null && rule.bannedPackages.contains(package)) {
      return Violation(
        file: file,
        uri: uri,
        message: 'must never import package:$package',
      );
    }
    return null;
  }
  if (uri.startsWith('dart:')) {
    final library = uri.substring(5).split('/').first;
    if (rule.bannedDartLibraries.contains(library)) {
      return Violation(
        file: file,
        uri: uri,
        message: 'must never import dart:$library',
      );
    }
  }
  return null;
}

/// Package name to package directory, for every workspace member.
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
  final violations = findViolations(Directory.current);
  if (violations.isEmpty) {
    stdout.writeln(
      'check_boundaries: OK (${defaultRules.length} packages, '
      'no forbidden imports)',
    );
    return;
  }
  stderr.writeln('check_boundaries: ${violations.length} violation(s)');
  for (final violation in violations) {
    stderr.writeln('  $violation');
  }
  exitCode = 1;
}

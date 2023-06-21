import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:path/path.dart' as p;

const _arbFolderArgName = 'arb-folder';
const _referenceFileName = 'reference-file';

/// {@template sample_command}
///
/// `i18n_checker diff -a /path/to/folder -r intl_fr.arb`
/// A [Command] to exemplify a sub command
/// {@endtemplate}
class DiffCheckCommand extends Command<int> {
  /// {@macro sample_command}
  DiffCheckCommand({
    required Logger logger,
  }) : _logger = logger {
    argParser
      ..addOption(
        _arbFolderArgName,
        abbr: 'a',
        help: 'Path to folder containing arb files',
      )
      ..addOption(
        _referenceFileName,
        abbr: 'r',
        help: 'Reference file',
      );
  }

  @override
  String get description {
    return 'Find missing key in i18n files based on default ref file';
  }

  @override
  String get name => 'diff';

  final Logger _logger;

  @override
  Future<int> run() async {
    final arbFolderPath = argResults![_arbFolderArgName] as String?;
    final referenceFile = argResults![_referenceFileName] as String?;

    if (arbFolderPath == null || referenceFile == null) {
      _logger.err('❌ - You need to specify both arb folder and reference file');
      return ExitCode.usage.code;
    }

    final refFilePath = '$arbFolderPath/$referenceFile';

    if (!Directory(arbFolderPath).existsSync()) {
      _logger.err('❌ - Arb folder does not exist');
      return ExitCode.usage.code;
    }

    if (!File(refFilePath).existsSync()) {
      _logger.err('❌ - Reference file does not exist');
      return ExitCode.usage.code;
    }

    if (!_validateFolderContent(arbFolderPath)) {
      _logger.err('❌ - Arb folder did not contain arb files');
      return ExitCode.usage.code;
    }

    if (_findKeyMismatches(arbFolderPath, refFilePath)) {
      return ExitCode.usage.code;
    }

    _logger.success('✅ - No difference found.');
    return ExitCode.success.code;
  }

  bool _validateFolderContent(String path) {
    final directory = Directory(path);
    return directory.listSync().any((element) {
      return p.extension(element.path) == '.arb';
    });
  }

  bool _findKeyMismatches(String arbFolderPath, String refFilePath) {
    final referenceContent = File(refFilePath).readAsLinesSync()
      ..removeLast()
      ..removeAt(0);

    final i18nDir = Directory(arbFolderPath);
    final files = i18nDir.listSync().where((value) {
      return p.extension(value.path) == '.arb' && value.path != refFilePath;
    });

    var mismatchFound = false;

    for (final line in referenceContent) {
      final key = extractKeyFromLine(line);

      for (final fileEntity in files) {
        final file = File(fileEntity.path);
        final found = file.readAsLinesSync().any((line) => line.contains(key));

        if (!found) {
          mismatchFound = true;
          _logger.err('❗ - Key $key was not found in ${file.path}');
        }
      }
    }

    return mismatchFound;
  }

  String extractKeyFromLine(String line) {
    return line.split(':').first.trim();
  }
}

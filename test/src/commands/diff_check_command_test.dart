import 'package:i18n_checker/src/commands/commands.dart';
import 'package:mason_logger/mason_logger.dart';
import 'package:test/test.dart';

void main() {
  late DiffCheckCommand command;

  setUp(() {
    command = DiffCheckCommand(
      logger: Logger(),
    );
  });
  test(
    'Run method Returns a 64 code when a key is not found in a ref file',
    () {
      expect(command.run(), completion(ExitCode.usage.code));
    },
  );
}

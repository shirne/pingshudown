import 'dart:io';

import 'package:args/args.dart';

import 'src/driver/down_driver.dart';

void main(List<String> arguments) async {
  const argId = 'id';
  const argStart = 'start';
  const argHelp = 'help';

  final parser = ArgParser()
    ..addCommand(
        'pingshu',
        ArgParser()
          ..addOption(argId, help: 'id', abbr: 'i')
          ..addOption(argStart,
              help: 'start chapter', abbr: 'n', defaultsTo: '1')
          ..addFlag(argHelp,
              help: 'show help message', abbr: 'h', negatable: false))
    ..addCommand(
        'ting55',
        ArgParser()
          ..addOption(argId, help: 'id', abbr: 'i')
          ..addOption(argStart,
              help: 'start chapter', abbr: 'n', defaultsTo: '1')
          ..addFlag(argHelp,
              help: 'show help message', abbr: 'h', negatable: false))
    ..addCommand(
        'tianya',
        ArgParser()
          ..addOption(argId, help: 'id', abbr: 'i')
          ..addOption(argStart,
              help: 'start chapter', abbr: 'n', defaultsTo: '1')
          ..addFlag(argHelp,
              help: 'show help message', abbr: 'h', negatable: false))
    ..addCommand(
        'lanren',
        ArgParser()
          ..addOption(argId, help: 'id', abbr: 'i')
          ..addOption(argStart,
              help: 'start chapter', abbr: 'n', defaultsTo: '0')
          ..addFlag(argHelp,
              help: 'show help message', abbr: 'h', negatable: false))
    ..addCommand(
        'gdbzkz',
        ArgParser()
          ..addOption(argId, help: 'id', abbr: 'i')
          ..addOption(argStart,
              help: 'start chapter', abbr: 'n', defaultsTo: '0')
          ..addFlag(argHelp,
              help: 'show help message', abbr: 'h', negatable: false))
    ..addCommand(
        'xscc',
        ArgParser()
          ..addOption(argId, help: 'id', abbr: 'i')
          ..addOption(argStart,
              help: 'start chapter', abbr: 'n', defaultsTo: '0')
          ..addFlag(argHelp,
              help: 'show help message', abbr: 'h', negatable: false))
    ..addCommand(
        'zongheng',
        ArgParser()
          ..addOption(argId, help: 'id', abbr: 'i')
          ..addOption(argStart,
              help: 'start chapter', abbr: 'n', defaultsTo: '0')
          ..addFlag(argHelp,
              help: 'show help message', abbr: 'h', negatable: false))
    ..addCommand(
        'honglou',
        ArgParser()
          ..addOption(argId, help: 'id', abbr: 'i')
          ..addOption(argStart,
              help: 'start chapter', abbr: 'n', defaultsTo: '0')
          ..addFlag(argHelp,
              help: 'show help message', abbr: 'h', negatable: false))
    ..addCommand(
        'm3u8',
        ArgParser()
          ..addOption(argId, help: 'id', abbr: 'i')
          ..addOption(argStart,
              help: 'start chapter', abbr: 'n', defaultsTo: '0')
          ..addFlag(argHelp,
              help: 'show help message', abbr: 'h', negatable: false))
    ..addOption(argId, help: 'id for pingshu', abbr: 'i')
    ..addOption(argStart,
        help: 'start chapter for pingshu', abbr: 'n', defaultsTo: '1')
    ..addFlag(argHelp, help: 'show help message', abbr: 'h', negatable: false);

  ArgResults results = parser.parse(arguments);

  if (results.wasParsed(argHelp)) {
    stdout.write('commands:\n  ');
    stdout.writeln(parser.commands.keys.join('\n  '));
    stdout.writeln('\noptions:');
    stdout.write(parser.usage);
    return;
  }

  String cmd = results.command?.name ?? 'pingshu';

  if (results.command != null) {
    results = results.command!;

    if (results.wasParsed(argHelp)) {
      stdout.write(parser.commands[results.name!]!.usage);
      return;
    }
  }

  String? psId;
  if (results.wasParsed(argId)) {
    psId = results[argId].toString();
  } else {
    stdout.writeln(parser.usage);
    stdout.writeln('Please input $cmd id:');
    psId = stdin.readLineSync();
    if (psId == null) {
      stdout.writeln('Error: need $cmd id!');
      return;
    }
  }
  int start = int.parse(results[argStart].toString());

  await DownDriver.driver(cmd, psId).start(startId: start);
  stdout.writeln('Download finished, please enter any key to exit...');
  stdin.readLineSync();
}

import 'dart:io';

import 'package:args/args.dart';

import 'download.dart';

void main(List<String> arguments) async {
  const argId = 'id';
  const argStart = 'start';
  final parser = ArgParser()
    ..addOption(argId, help: 'pingshu id', abbr: 'i')
    ..addOption(argStart, help: 'start chapter', abbr: 'n', defaultsTo: '1');

  final results = parser.parse(arguments);

  String? psId;
  if (results.wasParsed(argId)) {
    psId = results[argId].toString();
  } else {
    stdout.writeln('Please input pingshu id:');
    psId = stdin.readLineSync();
    if (psId == null) {
      stdout.writeln('Error: need pingshu id!');
      return;
    }
  }
  int start = int.parse(results[argStart].toString());

  await Download(psId).start(startId: start);
}

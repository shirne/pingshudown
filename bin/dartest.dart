import 'dart:io';

import 'download.dart';

void main(List<String> arguments) async {
  String? psId;
  if (arguments.isEmpty) {
    print('Please input pingshu id:');
    psId = stdin.readLineSync();
    if (psId == null) {
      print('Need pingshu id');
      return;
    }
  } else {
    psId = arguments[0];
  }
  int start = 1;
  if (arguments.length > 1) {
    start = int.parse(arguments[1]);
  }
  await Download(psId).start(startId: start);
}

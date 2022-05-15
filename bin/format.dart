import 'dart:io';

void main(List<String> arguments) {
  File file = File(arguments[0]);
  List<String> lines = file.readAsLinesSync();
  List<String> newContent = [];
  int i = -1;
  for (String line in lines) {
    if (line.startsWith(RegExp(r"第[一二三四五六七八九十零廿百]+章"))) {
      newContent.add("\n\r$line\n\r");
      i++;
      continue;
    }
    if (i >= 0 &&
        line.isNotEmpty &&
        !(line.startsWith('「') ||
            line.startsWith('*') ||
            line.startsWith('＊')) &&
        !(newContent[i].endsWith('\n\r') ||
            newContent[i].endsWith('。') ||
            newContent[i].endsWith('」') ||
            newContent[i].endsWith('—') ||
            newContent[i].endsWith('＊') ||
            newContent[i].endsWith('*'))) {
      newContent[i] += line;
    } else {
      newContent.add(line);
      i++;
    }
  }

  File newFile = File(arguments[0].replaceFirst('.txt', '-f.txt'));

  String content = newContent.join("\r\n");
  newFile.writeAsStringSync(content.replaceAll(RegExp(r'"([^"]+)"'), r'「$1」'));
}

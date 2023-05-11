import 'dart:io';

import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;

import 'down_driver.dart';

class TianyaDown extends DownDriver {
  static const baseUrl = 'https://www.tianyabook.com/';
  static const userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36 Edg/98.0.1108.56';

  final String bookId;
  final List<String> urls = [];

  String title = '';
  late File file;

  TianyaDown(this.bookId)
      : super(
            'tianya',
            Dio(BaseOptions(baseUrl: baseUrl, headers: {
              'User-Agent': userAgent,
              'Origin': baseUrl,
              'Referer': '$baseUrl/',
            })));

  @override
  Future<void> download(int idx) async {
    final html = await getHtml(urls[idx]);
    final dom = parse(html);
    final characterTitle = dom.querySelector('.readTitle')?.text ?? '';
    //String content = dom.querySelector('.entry-text .m-post')?.text ?? '';

    final content = dom.querySelector('#htmlContent');
    final tags = content?.querySelectorAll('.booktag');
    if (tags != null) {
      for (var i in tags) {
        i.remove();
      }
    }
    final contents = content?.text ?? '';

    final sink = file.openWrite(mode: FileMode.append);
    sink.writeAll(["\n\n$idx.$characterTitle\n", contents]);
    await sink.flush();
    sink.close();
    stdout.writeln('${urls[idx]} $characterTitle fetched');
  }

  @override
  Future<void> start({int startId = 0}) async {
    final html = await getHtml('shu/$bookId.html');
    Map<String, String> infos = {};
    final dom = parse(html);

    title = dom.querySelector('.bookTitle')?.text ??
        dom.head?.querySelector('title')?.text ??
        '';
    stdout.writeln('title: $title');
    final spans = dom.querySelectorAll('.booktag a');
    for (Element e in spans) {
      final str = e.attributes['title']?.split('：');
      if (str != null && str.isNotEmpty && str.length > 1) {
        infos[str[0]] = str[1];
      }
    }
    final infoBox = dom.querySelector('#bookIntro');
    if (infoBox != null) infos['intro'] = infoBox.text;

    stdout.writeln('infos: $infos');
    final box = dom.querySelector('#list-chapterAll');
    if (box == null) {
      stdout.writeln('Parse link error');
      return;
    }

    final links = box.querySelectorAll('dd a');
    if (links.isNotEmpty) {
      for (Element link in links) {
        final url = link.attributes['href'];
        if (url != null && url.isNotEmpty && !url.startsWith('javascript:')) {
          urls.add(url);
        }
      }
    }
    file = File('${Directory.current.absolute.path}/books/$title.txt');
    if (file.existsSync()) {
      file.deleteSync();
    }
    file.createSync(recursive: true);
    file.writeAsStringSync("$title\n\n$infos");
    while (startId < urls.length) {
      await download(startId);
      startId++;
    }
  }
}

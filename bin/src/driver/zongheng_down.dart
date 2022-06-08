import 'dart:io';

import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;

import 'down_driver.dart';

class ZonghengDown extends DownDriver {
  static const baseUrl = 'http://book.zongheng.com/';
  static const userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36 Edg/98.0.1108.56';

  final String bookId;
  final List<String> urls = [];

  String title = '';
  late File file;

  ZonghengDown(this.bookId)
      : super(
            'zongheng',
            Dio(BaseOptions(baseUrl: baseUrl, headers: {
              'User-Agent': userAgent,
              'Origin': baseUrl,
              'Referer': '$baseUrl/',
            })));

  @override
  Future<void> download(int idx) async {
    final html = await getHtml(urls[idx]);
    final dom = parse(html);
    final characterTitle = dom.querySelector('.title_txtbox')?.text ?? '';
    //String content = dom.querySelector('.entry-text .m-post')?.text ?? '';

    final content = [];
    final parts = dom.querySelector('.reader_box .content')?.children;
    if (parts != null) {
      for (Element e in parts) {
        content.add(e.text.trim() + "\n");
      }
    }

    final sink = file.openWrite(mode: FileMode.append);
    sink.writeAll(["\n\n$characterTitle\n", ...content]);
    await sink.flush();
    sink.close();
    stdout.writeln('$characterTitle fetched');
  }

  @override
  Future<void> start({int startId = 0}) async {
    final html = await getHtml('showchapter/$bookId.html');
    Map<String, String> infos = {};
    final dom = parse(html);
    final infoBox = dom.querySelector('.book-meta');
    if (infoBox == null) {
      stdout.writeln('Parse info error');
      return;
    }
    title = infoBox.querySelector('h1')?.text ??
        dom.head?.querySelector('title')?.text ??
        '';
    stdout.writeln('title: $title');
    final spans = infoBox.querySelectorAll('p span');
    for (Element e in spans) {
      final str = e.text.split('：');
      if (str.isNotEmpty && str.length > 1) {
        infos[str[0]] = str[1];
      }
    }
    stdout.writeln('infos: $infos');
    final links = dom.querySelectorAll('.chapter-list li a');
    if (links.isEmpty) {
      stdout.writeln('Parse link error');
      return;
    }

    for (Element link in links) {
      final url = link.attributes['href'];
      if (url != null) {
        urls.add(url);
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

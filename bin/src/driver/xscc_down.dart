import 'dart:io';

import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;

import 'down_driver.dart';

class XsccDown extends DownDriver {
  static const baseUrl = 'https://www.85xscc.com/';
  static const userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36 Edg/98.0.1108.56';

  final String bookId;
  final List<String> urls = [];

  String title = '';
  late File file;

  XsccDown(this.bookId)
      : super(
            'xscc',
            Dio(BaseOptions(baseUrl: baseUrl, headers: {
              'User-Agent': userAgent,
              'Origin': baseUrl,
              'Referer': '$baseUrl/',
            })));

  @override
  Future<void> download(int idx) async {
    final html = await getHtml(urls[idx]);
    final dom = parse(html);
    final characterTitle = dom.querySelector('.entry-tit h1')?.text ?? '';
    //String content = dom.querySelector('.entry-text .m-post')?.text ?? '';

    final content = [];
    final parts = dom.querySelector('.entry-text .m-post')?.children;
    if (parts != null) {
      for (Element e in parts) {
        content.add("${e.text.trim()}\n");
      }
    }

    final sink = file.openWrite(mode: FileMode.append);
    sink.writeAll(["\n\n$idx.$characterTitle\n", ...content]);
    await sink.flush();
    sink.close();
    stdout.writeln('$characterTitle fetched');
  }

  @override
  Future<void> start({int startId = 0}) async {
    final html = await getHtml('book/$bookId/');
    Map<String, String> infos = {};
    final dom = parse(html);
    final infoBox = dom.querySelector('.book-intro');
    if (infoBox == null) {
      stdout.writeln('Parse info error');
      return;
    }
    title = infoBox.querySelector('h1')?.text ??
        dom.head?.querySelector('title')?.text ??
        '';
    stdout.writeln('title: $title');
    final spans = infoBox.querySelectorAll('p');
    for (Element e in spans) {
      final str = e.text.split('：');
      if (str.isNotEmpty && str.length > 1) {
        infos[str[0]] = str[1];
      }
    }
    stdout.writeln('infos: $infos');
    final headers = dom.querySelectorAll('h2.ac');
    if (headers.isEmpty) {
      stdout.writeln('Parse link error');
      return;
    }

    for (Element e in headers) {
      if (e.text.contains('最新章节')) {
        continue;
      }
      final links = e.nextElementSibling?.querySelectorAll('ul li a');
      if (links != null && links.isNotEmpty) {
        for (Element link in links) {
          final url = link.attributes['href'];
          if (url != null) {
            urls.add(url);
          }
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

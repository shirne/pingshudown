import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import 'down_driver.dart';

class LanrenDown extends DownDriver {
  final RegExp titleReg = RegExp(
    r'<title>([^<]*)</title>',
    multiLine: true,
    dotAll: true,
    caseSensitive: false,
  );
  final RegExp cTitleReg = RegExp(
    r'<div\s+class="h-play"><h1>([^<]*)</h1></div>',
    multiLine: true,
    dotAll: true,
    caseSensitive: false,
  );
  final RegExp descReg = RegExp(
    r'<span\s+class="detail-content"\s+style="display: none;"\s*>(.*?)</span>',
    multiLine: true,
    dotAll: true,
    caseSensitive: false,
  );

  final RegExp itemReg = RegExp(
    r'<li\s+.*?id="(\d+)"><a title="([^"]+)" href="([^"]+)"[^>]*>.*?</a></li>',
    multiLine: true,
    dotAll: true,
    caseSensitive: false,
  );

  final RegExp urlReg = RegExp(
    r'var now="([^"]+)"',
    multiLine: true,
    dotAll: true,
    caseSensitive: false,
  );

  static const baseUrl = 'https://www.lanrentingshu.net';
  static const userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36 Edg/98.0.1108.56';

  final Dio dio;
  final CookieJar cookieJar = CookieJar();

  final String psId;
  int total;
  String title;
  String dir;

  final List<List<String>> urls = [];

  LanrenDown(this.psId, {this.title = '', this.dir = '', this.total = 0})
      : dio = Dio(BaseOptions(baseUrl: baseUrl, headers: {
          'User-Agent': userAgent,
          'Origin': baseUrl,
          'Referer': '$baseUrl/',
        })),
        super('lanren') {
    dio.interceptors.add(CookieManager(cookieJar));
    cookieJar.loadForRequest(Uri.parse(baseUrl));
  }

  @override
  Future<void> start({int startId = 1}) async {
    final response = await dio.get('/video/?$psId-0-0.html',
        options: Options(responseType: ResponseType.stream));
    final html = await getHtml(response);
    if (title.isEmpty) {
      final aTitle = titleReg.firstMatch(html);
      title = aTitle?.group(1)?.split('有声书在线收听_')[0] ?? '';
    }
    final aDesc = descReg.firstMatch(html);
    dir = Directory.current.absolute.path + '/down/$psId-$title/';
    if (!Directory(dir).existsSync()) {
      Directory(dir).createSync(recursive: true);
    }
    File('${dir}desc.txt').writeAsStringSync(aDesc?.group(1) ?? '');
    final items = itemReg.allMatches(html);
    for (RegExpMatch item in items) {
      urls.add([item.group(1) ?? "", item.group(2) ?? "", item.group(3) ?? ""]);
    }
    if (urls.isEmpty) {
      stdout.writeln("Not found any chapters!");
      return;
    }
    await download(startId);
  }

  @override
  Future<void> download(int idx) async {
    try {
      Response response = await dio.get(urls[idx][2],
          options: Options(responseType: ResponseType.stream));
      final html = await getHtml(response);
      final url = urlReg.firstMatch(html)?.group(1);
      if (url != null) {
        try {
          await dio.download(url, '$dir${urls[idx][1]}');
          stdout.writeln("Download $idx success!");
        } on DioError catch (_) {
          stdout.writeln('Download $idx error, Retring...');
          await Future.delayed(Duration(seconds: 1));
          await download(idx);
          return;
        }
      } else {
        stdout.writeln("Chapter $idx has no media url!");
      }
      if (total == 0 || idx < total) {
        if (idx + 1 < urls.length) {
          await download(idx + 1);
        }
      } else if (total > 0) {
        stdout.writeln('Download finish, total $idx');
      }
    } on DioError catch (error) {
      if (!(error.type == DioErrorType.response &&
          error.response?.statusCode == 404)) {
        stdout.writeln(
            'Fetch(${error.requestOptions.uri.toString()}, ${error.type}, ${error.response?.statusCode ?? ''}) $idx info error: ${error.message}, Retring...');
        await Future.delayed(Duration(seconds: 1));
        await download(idx);
      } else {
        stdout.writeln('Download finish, total ${idx - 1}');
      }
    }
  }
}

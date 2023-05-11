import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';

import 'down_driver.dart';

class Ting55Down extends DownDriver {
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
    r'<meta\s+name="description"\s+content="([^>]*)"\s*/?>',
    multiLine: true,
    dotAll: true,
    caseSensitive: false,
  );
  final RegExp metaXtReg = RegExp(
    r'<meta\s+name="_c"\s+content="([^>]*)"\s*/?>',
    multiLine: true,
    dotAll: true,
    caseSensitive: false,
  );
  final RegExp metaLReg = RegExp(
    r'<meta\s+name="_l"\s+content="([^>]*)"\s*/?>',
    multiLine: true,
    dotAll: true,
    caseSensitive: false,
  );
  static const baseUrl = 'https://ting55.com';
  static const userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36 Edg/98.0.1108.56';

  final CookieJar cookieJar = CookieJar();

  final String psId;
  int total;
  String title;
  String dir;

  Ting55Down(this.psId, {this.title = '', this.dir = '', this.total = 0})
      : super(
            'ting55',
            Dio(BaseOptions(baseUrl: baseUrl, headers: {
              'User-Agent': userAgent,
              'Origin': baseUrl,
              'Referer': '$baseUrl/',
            }))) {
    dio.interceptors.add(CookieManager(cookieJar));
    cookieJar.loadForRequest(Uri.parse(baseUrl));
  }

  @override
  Future<void> start({int startId = 1}) async {
    if (title.isEmpty) {
      final response = await dio.get('/book/$psId',
          options: Options(responseType: ResponseType.stream));
      final html = await decodeHtml(response);
      final aTitle = titleReg.firstMatch(html);
      title = aTitle?.group(1)?.split('_播音')[0] ?? '';
      final aDesc = descReg.firstMatch(html);
      dir = '${Directory.current.absolute.path}/down/$psId-$title/';
      if (!Directory(dir).existsSync()) {
        Directory(dir).createSync(recursive: true);
      }
      File('${dir}desc.txt').writeAsStringSync(aDesc?.group(1) ?? '');
    }
    await download(startId);
  }

  @override
  Future<void> download(int idx) async {
    String title = '';
    String metaXt;
    String metaL;
    try {
      Response response = await dio.get('/book/$psId-$idx',
          options: Options(responseType: ResponseType.stream));
      final html = await decodeHtml(response);
      title = cTitleReg.firstMatch(html)?.group(1) ?? '';
      title = title.contains(' ') ? title.substring(title.indexOf(' ')) : '';

      metaXt = metaXtReg.firstMatch(html)?.group(1) ?? '';
      metaL = metaLReg.firstMatch(html)?.group(1) ?? '1';

      stdout.writeln("get $idx title: $title, $metaXt, $metaL");
    } on DioError catch (error) {
      if (!(error.type == DioErrorType.response &&
          error.response?.statusCode == 404)) {
        stdout.writeln(
            'Fetch(${error.requestOptions.uri.toString()}) $idx title error, Retring...');
        await Future.delayed(Duration(seconds: 1));
        await download(idx);
      } else {
        stdout.writeln('Download finish, total ${idx - 1}');
      }
      return;
    }

    try {
      Response response = await dio.post('/nlinka',
          data: FormData.fromMap({
            'bookId': psId,
            'isPay': 0,
            'page': idx,
          }),
          options: Options(
            responseType: ResponseType.json,
            headers: {
              'User-Agent': userAgent,
              'Referer': '${baseUrl}book/$psId-$idx',
              'X-Requested-With': 'XMLHttpRequest',
              'xt': metaXt,
              'l': metaL,
            },
          ));
      final Map<String, dynamic> data = jsonDecode(response.data);
      final url = data['url']?.toString();
      if (url != null) {
        try {
          await dio.download(
            '$url?v=${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
            '$dir$title-${idx.toString().padLeft(4, '0')}.mp3',
          );
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
        await download(idx + 1);
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

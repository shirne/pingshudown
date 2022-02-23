import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:charset/charset.dart';
import 'package:dio/dio.dart';

import 'down_driver.dart';

class PingshuDown extends DownDriver {
  final RegExp titleReg = RegExp(r'<title>([^<]*)</title>',
      multiLine: true, dotAll: true, caseSensitive: false);
  final RegExp descReg = RegExp(
      r'<meta\s+name="description"\s+content="([^>]*)"\s*/?>',
      multiLine: true,
      dotAll: true,
      caseSensitive: false);
  static const baseUrl = 'http://m.zgpingshu.com/';
  static const userAgent =
      'Mozilla/5.0 (iPhone; CPU iPhone OS 13_2_3 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/13.0.3 Mobile/15E148 Safari/604.1';

  final Dio dio;

  final String psId;
  int total;
  String title;
  String dir;

  PingshuDown(this.psId, {this.title = '', this.dir = '', this.total = 0})
      : dio = Dio(BaseOptions(baseUrl: baseUrl, headers: {
          'User-Agent': userAgent,
          'Referer': '${baseUrl}play/$psId/',
        })),
        super('pingshu');

  @override
  Future<void> start({int startId = 1}) async {
    if (title.isEmpty) {
      final response = await dio.get('play/$psId/',
          options: Options(responseType: ResponseType.stream));
      final html = await getHtml(response);
      final aTitle = titleReg.firstMatch(html);
      title = aTitle?.group(1)?.split(' ')[0] ?? '';
      final aDesc = descReg.firstMatch(html);
      dir = Directory.current.absolute.path + '/down/$psId-$title/';
      if (!Directory(dir).existsSync()) {
        Directory(dir).createSync(recursive: true);
      }
      File('${dir}desc.txt').writeAsStringSync(aDesc?.group(1) ?? '');
    }
    await download(startId);
  }

  @override
  Future<void> download(int idx) async {
    try {
      Response response = await dio.post(
        'playdata/$psId/${idx > 1 ? idx : 'index'}.html',
        options: Options(responseType: ResponseType.json),
      );
      final Map<String, dynamic> data = jsonDecode(response.data);
      final url = data['urlpath']?.toString();
      if (url != null) {
        try {
          await dio.download(url.replaceFirst('.flv', '.mp3'),
              '$dir$title-${idx.toString().padLeft(3, '0')}.mp3');
          stdout.writeln("Download $idx success!");
        } on DioError catch (_) {
          stdout.writeln('Download $idx error, Retring...');
          await Future.delayed(Duration(seconds: 1));
          await download(idx);
          return;
        }
      }
      if (total == 0 || idx < total) {
        await download(idx + 1);
      } else if (total > 0) {
        stdout.writeln('Download finish, total $idx');
      }
    } on DioError catch (error) {
      if (!(error.type == DioErrorType.response &&
          error.response?.statusCode == 404)) {
        stdout.writeln('Fetch $idx info error, Retring...');
        await Future.delayed(Duration(seconds: 1));
        await download(idx);
      } else {
        stdout.writeln('Download finish, total ${idx - 1}');
      }
    }
  }
}

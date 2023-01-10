//https://long.lgtcpnb.cn/videos1/eefac645f99fee4f5f34ab9dd7f9685d/eefac645f99fee4f5f34ab9dd7f9685d.m3u8

import 'dart:io';

import 'package:dio/dio.dart';

import 'down_driver.dart';

class M3u8Down extends DownDriver {
  final String url;
  final String name;
  static const userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36 Edg/98.0.1108.56';

  final List<String> urls = [];
  String dir = '';

  M3u8Down._(this.url, this.name, String baseUrl)
      : super(
          'swwx',
          Dio(
            BaseOptions(baseUrl: baseUrl, headers: {
              'User-Agent': userAgent,
              'Origin': baseUrl,
              'Referer': '$baseUrl/',
            }),
          ),
        );

  factory M3u8Down(String url) {
    final idx = url.lastIndexOf('/');

    String baseUrl = url.substring(0, idx);
    return M3u8Down._(
      url,
      url.substring(idx + 1).replaceAll('.m3u8', ''),
      baseUrl,
    );
  }

  @override
  Future<void> download(int idx) {
    // TODO: implement download
    throw UnimplementedError();
  }

  @override
  Future<void> start({int startId = 1}) async {
    dir = '${Directory.current.absolute.path}/down/$name/';
    if (!Directory(dir).existsSync()) {
      Directory(dir).createSync(recursive: true);
    }
    final response = await dio.get(
      url,
      options: Options(responseType: ResponseType.stream),
    );
    final text = await decodeHtml(response);
    File('$dir$name.m3u8').writeAsStringSync(text);
  }
}

import 'package:dio/dio.dart';

import 'down_driver.dart';

class SwwxDown extends DownDriver {
  static const baseUrl = 'https://www.swzw.la/';
  static const userAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/98.0.4758.102 Safari/537.36 Edg/98.0.1108.56';

  SwwxDown()
      : super(
            'swwx',
            Dio(BaseOptions(baseUrl: baseUrl, headers: {
              'User-Agent': userAgent,
              'Origin': baseUrl,
              'Referer': '$baseUrl/',
            })));

  @override
  Future<void> download(int idx) {
    // TODO: implement download
    throw UnimplementedError();
  }

  @override
  Future<void> start({int startId = 1}) {
    // TODO: implement start
    throw UnimplementedError();
  }
}

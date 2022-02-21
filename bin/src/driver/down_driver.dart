import 'dart:convert';
import 'dart:typed_data';

import 'package:charset/charset.dart';
import 'package:dio/dio.dart';

import 'pingshu_down.dart';
import 'ting55_down.dart';

abstract class DownDriver {
  final RegExp charsetReg = RegExp(
    r'<meta\s+charset="([^>]*)"\s*/?>',
    multiLine: true,
    dotAll: true,
    caseSensitive: false,
  );

  final String driverName;
  DownDriver(this.driverName);

  factory DownDriver.driver(
    String driver,
    String psId, {
    String title = '',
    String dir = '',
    int total = 0,
  }) {
    switch (driver) {
      case 'ting55':
        return Ting55Down(psId, title: title, dir: dir, total: total);
      default:
        return PingshuDown(psId, title: title, dir: dir, total: total);
    }
  }

  Future<String> getHtml(Response response) async {
    final stream = await (response.data as ResponseBody).stream.toList();
    final result = BytesBuilder();
    for (Uint8List subList in stream) {
      result.add(subList);
    }
    final data = result.takeBytes();
    String html = utf8.decode(data, allowMalformed: true);
    final aCharset = charsetReg.firstMatch(html);
    final charset = aCharset?.group(1)?.toLowerCase();
    if (charset == 'gbk' || charset == 'gb2312') {
      html = gbk.decode(data);
    }
    return html;
  }

  Future<void> start({int startId = 1});
  Future<void> download(int idx);
}

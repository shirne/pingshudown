import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:charset/charset.dart';
import 'package:dio/dio.dart';

import 'gdbzkz_down.dart';
import 'lanren_down.dart';
import 'pingshu_down.dart';
import 'ting55_down.dart';
import 'xscc_down.dart';
import 'zongheng_down.dart';

abstract class DownDriver {
  final RegExp charsetReg = RegExp(
    r'<meta\s+charset="([^>]*)"\s*/?>',
    multiLine: true,
    dotAll: true,
    caseSensitive: false,
  );

  final String driverName;

  final Dio dio;

  DownDriver(this.driverName, this.dio) {
    stdout.writeln('$driverName initialized');
  }

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
      case 'lanren':
        return LanrenDown(psId, title: title, dir: dir, total: total);
      case 'gdbzkz':
        return GdbzkzDown(psId);
      case 'xscc':
        return XsccDown(psId);
      case 'zongheng':
        return ZonghengDown(psId);
      default:
        return PingshuDown(psId, title: title, dir: dir, total: total);
    }
  }

  Future<String> getHtml(String url) async {
    try {
      Response response = await dio.get(
        url,
        options: Options(responseType: ResponseType.stream),
      );
      return await decodeHtml(response);
    } on DioError catch (err) {
      print(url);
      print(err.message);
      return '';
    }
  }

  Future<String> decodeHtml(Response response) async {
    final stream = await (response.data as ResponseBody).stream.toList();
    final result = BytesBuilder();
    for (Uint8List subList in stream) {
      result.add(subList);
    }
    final data = result.takeBytes();
    String html = utf8.decode(data, allowMalformed: true);
    final aCharset = charsetReg.firstMatch(html);
    final charset = aCharset?.group(1)?.toLowerCase();
    if (charset != null && charset.toLowerCase() != 'utf-8') {
      html = Charset.getByName(charset)?.decode(data) ?? html;
    }
    return html;
  }

  Future<void> start({int startId = 1});
  Future<void> download(int idx);
}

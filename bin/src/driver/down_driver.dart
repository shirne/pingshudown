import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:charset/charset.dart';
import 'package:dio/dio.dart';

import 'gdbzkz_down.dart';
import 'honglou_down.dart';
import 'lanren_down.dart';
import 'm3u8_down.dart';
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
      case 'honglou':
        return HonglouDown(psId);
      case 'm3u8':
        return M3u8Down(psId);
      default:
        return PingshuDown(psId, title: title, dir: dir, total: total);
    }
  }

  Future<String> getHtml(String url, {int retry = 3, int delay = 1}) async {
    try {
      final response = await dio.get(
        url,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: true,
          maxRedirects: 3,
          receiveDataWhenStatusError: true,
        ),
      );
      return await decodeHtml(response);
    } on DioError catch (err) {
      print(err.message);
      if (retry > 0) {
        await Future.delayed(Duration(seconds: delay));
        return getHtml(url, retry: retry - 1, delay: delay + 1);
      }
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

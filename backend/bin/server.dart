import 'dart:convert';
import 'dart:io';

import 'package:posyandu_backend/api.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart';

/// CORS sederhana supaya app Flutter Web juga bisa memanggil API.
Middleware cors() => (inner) => (req) async {
      const h = {
        'access-control-allow-origin': '*',
        'access-control-allow-headers': 'authorization, content-type',
        'access-control-allow-methods': 'GET, POST, PUT, DELETE, OPTIONS',
      };
      if (req.method == 'OPTIONS') return Response.ok('', headers: h);
      final res = await inner(req);
      return res.change(headers: h);
    };

Middleware catchErrors() => (inner) => (req) async {
      try {
        return await inner(req);
      } catch (e, st) {
        stderr.writeln('ERROR ${req.method} ${req.url}: $e\n$st');
        return Response.internalServerError(
          body: jsonEncode({
            'error': 'Terjadi kesalahan pada server.',
            // Detail hanya untuk pengembangan; set SHOW_ERRORS=0 untuk menyembunyikan.
            if (Platform.environment['SHOW_ERRORS'] != '0') 'detail': e.toString(),
          }),
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      }
    };

void main(List<String> args) async {
  final handler = const Pipeline()
      .addMiddleware(logRequests())
      .addMiddleware(cors())
      .addMiddleware(catchErrors())
      .addHandler(buildApi().call);

  final port = int.parse(Platform.environment['PORT'] ?? '8080');
  final server = await serve(handler, InternetAddress.anyIPv4, port);
  print('Posyandu MBG API berjalan di port ${server.port}');
}

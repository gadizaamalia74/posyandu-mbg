import 'package:shelf/shelf.dart';

import 'util.dart';

class Session {
  final String type; // 'staff' | 'ibu'
  final int id;
  final String role; // 'admin' | 'kader' | 'ibu'
  final String nama;
  Session(this.type, this.id, this.role, this.nama);
}

/// Sesi disimpan di memori: restart server = semua pengguna harus login ulang.
final Map<String, Session> sessions = {};

typedef AuthHandler = Future<Response> Function(Request req, Session s);

Session? _session(Request req) {
  final h = req.headers['authorization'] ?? '';
  if (!h.startsWith('Bearer ')) return null;
  return sessions[h.substring(7).trim()];
}

/// Hanya admin & kader.
Handler staff(AuthHandler fn) => (req) async {
      final s = _session(req);
      if (s == null) return fail('Belum login', 401);
      if (s.type != 'staff') return fail('Akses ditolak', 403);
      return fn(req, s);
    };

/// Hanya admin.
Handler admin(AuthHandler fn) => (req) async {
      final s = _session(req);
      if (s == null) return fail('Belum login', 401);
      if (s.role != 'admin') return fail('Hanya admin yang boleh', 403);
      return fn(req, s);
    };

/// Hanya ibu balita.
Handler ibu(AuthHandler fn) => (req) async {
      final s = _session(req);
      if (s == null) return fail('Belum login', 401);
      if (s.type != 'ibu') return fail('Akses ditolak', 403);
      return fn(req, s);
    };

/// Siapa saja yang sudah login.
Handler anyUser(AuthHandler fn) => (req) async {
      final s = _session(req);
      if (s == null) return fail('Belum login', 401);
      return fn(req, s);
    };

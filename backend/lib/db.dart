import 'dart:io';

import 'package:mysql_client/mysql_client.dart';

/// Koneksi database (pengganti includes/config.php di PHP).
/// Bisa diubah lewat environment variable: DB_HOST, DB_PORT, DB_USER, DB_PASS, DB_NAME.
class Db {
  static final _env = Platform.environment;

  static final MySQLConnectionPool pool = MySQLConnectionPool(
    host: _env['DB_HOST'] ?? '127.0.0.1',
    port: int.parse(_env['DB_PORT'] ?? '3306'),
    userName: _env['DB_USER'] ?? 'root',
    password: _env['DB_PASS'] ?? '',
    maxConnections: 10,
    databaseName: _env['DB_NAME'] ?? 'posyandu_flamboyan',
    // MySQL 8 (caching_sha2_password) butuh secure=true; MariaDB/XAMPP biasanya false.
    secure: (_env['DB_SECURE'] ?? '0') == '1',
  );

  /// SELECT -> daftar Map (semua nilai bertipe String?)
  static Future<List<Map<String, String?>>> query(
    String sql, [
    Map<String, dynamic>? params,
  ]) async {
    final result = await pool.execute(sql, params);
    return result.rows.map((r) => r.assoc()).toList();
  }

  static Future<Map<String, String?>?> one(
    String sql, [
    Map<String, dynamic>? params,
  ]) async {
    final rows = await query(sql, params);
    return rows.isEmpty ? null : rows.first;
  }

  /// INSERT/UPDATE/DELETE -> jumlah baris terpengaruh
  static Future<int> exec(String sql, [Map<String, dynamic>? params]) async {
    final result = await pool.execute(sql, params);
    return result.affectedRows.toInt();
  }

  /// INSERT -> id baru
  static Future<int> insert(String sql, [Map<String, dynamic>? params]) async {
    final result = await pool.execute(sql, params);
    return result.lastInsertID.toInt();
  }
}

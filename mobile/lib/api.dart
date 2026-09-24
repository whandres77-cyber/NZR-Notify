import 'dart:convert';
import 'package:http/http.dart' as http;
import 'config.dart';

class Api {
  static Uri _u(String path) => Uri.parse('${AppConfig.apiBaseUrl}$path');

  static Future<List<dynamic>> getList(String path) async {
    final r = await http.get(_u(path));
    if (r.statusCode >= 400) throw Exception(r.body);
    return jsonDecode(r.body) as List<dynamic>;
  }

  static Future<Map<String, dynamic>> getMap(String path) async {
    final r = await http.get(_u(path));
    if (r.statusCode >= 400) throw Exception(r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {
    final r = await http.post(
      _u(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (r.statusCode >= 400) throw Exception(r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> patch(String path, Map<String, dynamic> body) async {
    final r = await http.patch(
      _u(path),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );
    if (r.statusCode >= 400) throw Exception(r.body);
    return jsonDecode(r.body) as Map<String, dynamic>;
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

import '../model/semester_model.dart';

class SemesterRepository {
  final String baseUrl;
  final Future<String?> Function() getToken;

  SemesterRepository({
    required this.baseUrl,
    required this.getToken,
  });

  /// ============================
  /// GET SEMESTER LIST
  /// ============================
  Future<List<SemesterModel>> getSemesters({
    required int instId,
  }) async {
    final token = await getToken();
    if (token == null) {
      throw Exception('Token not found');
    }

    final uri = Uri.parse('$baseUrl/semester/get');

    final response = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'inst_id': instId,
        'flag_valid': true,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch semester');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;

    if (decoded['success'] != true) {
      throw Exception(decoded['message'] ?? 'Unknown error');
    }

    final List data = decoded['data'];

    return data
        .map(
          (e) => SemesterModel.fromJson(
            e as Map<String, dynamic>,
          ),
        )
        .toList();
  }
}
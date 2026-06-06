import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/job_model.dart';

class ApiService {
  Future<List<JobModel>> fetchJobs({int page = 1}) async {
    try {
      final response = await http.get(Uri.parse('https://www.arbeitnow.com/api/job-board-api'));
      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        final data = decoded['data'] as List;

        return data.map((jsonItem) => JobModel.fromJson(jsonItem)).toList();
      } else {
        throw Exception('Failed to load jobs from API');
      }
    } catch (e) {
      throw Exception('Failed to load jobs: $e');
    }
  }
}

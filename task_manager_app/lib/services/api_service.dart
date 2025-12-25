import 'package:dio/dio.dart';
import '../models/task.dart';

class ApiService {
  // CHANGE THIS URL based on your device (see note above)
  final Dio _dio = Dio(BaseOptions(baseUrl: 'http://127.0.0.1:3000/api'));

  // 1. Get All Tasks
  Future<List<Task>> getTasks() async {
    try {
      final response = await _dio.get('/tasks');
      final List data = response.data['data'];
      return data.map((json) => Task.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to load tasks: $e');
    }
  }

  // 2. Classify Task (Preview)
  Future<Map<String, dynamic>> classifyTask(String title, String description) async {
    try {
      final response = await _dio.post('/classify', data: {
        'title': title,
        'description': description,
      });
      return response.data;
    } catch (e) {
      throw Exception('Failed to analyze task: $e');
    }
  }

  // 3. Create Task
  Future<Task> createTask(String title, String description, {
    String? category,
    String? priority,
    String? assignedTo,
    String? dueDate,
  }) async {
    try {
      final response = await _dio.post('/tasks', data: {
        'title': title,
        'description': description,
        if (category != null) 'category': category,
        if (priority != null) 'priority': priority,
        if (assignedTo != null) 'assigned_to': assignedTo,
        if (dueDate != null) 'due_date': dueDate,
      });
      return Task.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to create task: $e');
    }
  }

  // 4. Update Task
  Future<Task> updateTask(String id, Map<String, dynamic> updates) async {
    try {
      final response = await _dio.patch('/tasks/$id', data: updates);
      return Task.fromJson(response.data);
    } catch (e) {
      throw Exception('Failed to update task: $e');
    }
  }

  // 5. Delete Task
  Future<void> deleteTask(String id) async {
    try {
      await _dio.delete('/tasks/$id');
    } catch (e) {
      throw Exception('Failed to delete task: $e');
    }
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task.dart';
import '../services/api_service.dart';

// 1. The API Provider
final apiServiceProvider = Provider((ref) => ApiService());

// 2. The List of Tasks (AsyncValue handles loading/error states automatically)
final tasksProvider = FutureProvider<List<Task>>((ref) async {
  return ref.read(apiServiceProvider).getTasks();
});

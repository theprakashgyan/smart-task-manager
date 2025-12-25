class Task {
  final String? id;
  final String title;
  final String description;
  final String category;
  final String priority;
  final String status;
  final List<String> suggestedActions;
  final String? assignedTo;
  final String? dueDate;

  Task({
    this.id,
    required this.title,
    this.description = '',
    this.category = 'general',
    this.priority = 'low',
    this.status = 'pending',
    this.suggestedActions = const [],
    this.assignedTo,
    this.dueDate,
  });

  // Convert JSON from API to Dart Object
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'],
      title: json['title'],
      description: json['description'] ?? '',
      category: json['category'] ?? 'general',
      priority: json['priority'] ?? 'low',
      status: json['status'] ?? 'pending',
      suggestedActions: List<String>.from(json['suggested_actions'] ?? []),
      assignedTo: json['assigned_to'],
      dueDate: json['due_date'],
    );
  }

  // Convert Dart Object to JSON for API
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
    };
  }
}

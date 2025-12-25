import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/task_provider.dart';
import '../models/task.dart';
import 'create_task_sheet.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    // Watch the task list provider
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Task Manager')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const CreateTaskSheet(),
        ),
        child: const Icon(Icons.add),
      ),
      body: tasksAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (tasks) {
          // Filter tasks
          final filteredTasks = tasks.where((t) {
            final matchesSearch = t.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                t.description.toLowerCase().contains(_searchQuery.toLowerCase());
            final matchesCategory = _selectedCategory == null || t.category == _selectedCategory;
            return matchesSearch && matchesCategory;
          }).toList();

          return Column(
            children: [
              // 1. Summary Section
              _buildSummaryCards(tasks),

              // 2. Search & Filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: "Search tasks...",
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(vertical: 0),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val),
                ),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildFilterChip('All', null),
                    ...['scheduling', 'finance', 'technical', 'safety'].map(
                      (c) => _buildFilterChip(c.toUpperCase(), c),
                    ),
                  ],
                ),
              ),

              // 3. Task List
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => ref.refresh(tasksProvider.future),
                  child: ListView.builder(
                    itemCount: filteredTasks.length,
                    itemBuilder: (context, index) {
                      final task = filteredTasks[index];
                      return Dismissible(
                        key: ValueKey(task.id),
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) async {
                          try {
                            await ref.read(apiServiceProvider).deleteTask(task.id!);
                            ref.refresh(tasksProvider);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Task deleted")));
                          } catch (e) {
                             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Failed to delete: $e")));
                             ref.refresh(tasksProvider); // Undo optimistic delete visual if error
                          }
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: ListTile(
                            onTap: () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => CreateTaskSheet(taskToEdit: task),
                            ),
                            leading: _getPriorityIcon(task.priority),
                            title: Text(task.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (task.description.isNotEmpty) Text(task.description),
                                const SizedBox(height: 5),
                                Wrap(
                                  spacing: 8,
                                  children: [
                                    Chip(
                                      label: Text(task.category.toUpperCase()),
                                      backgroundColor: _getCategoryColor(task.category),
                                      labelStyle: const TextStyle(color: Colors.white, fontSize: 10),
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: VisualDensity.compact,
                                    ),
                                    if (task.dueDate != null)
                                      Chip(
                                        avatar: const Icon(Icons.calendar_today, size: 12),
                                        label: Text(DateFormat('MMM d').format(DateTime.parse(task.dueDate!))),
                                        backgroundColor: Colors.grey.shade200,
                                        labelStyle: const TextStyle(fontSize: 10),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                    if (task.assignedTo != null)
                                      Chip(
                                        avatar: const Icon(Icons.person, size: 12),
                                        label: Text(task.assignedTo!),
                                        backgroundColor: Colors.blue.shade50,
                                        labelStyle: const TextStyle(fontSize: 10, color: Colors.blue),
                                        visualDensity: VisualDensity.compact,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            isThreeLine: true,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String? category) {
    final isSelected = _selectedCategory == category;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => setState(() => _selectedCategory = category),
        backgroundColor: Colors.grey.shade200,
        selectedColor: Colors.blue.shade200,
      ),
    );
  }

  // --- Helper Widgets ---

  Widget _buildSummaryCards(List<Task> tasks) {
    int high = tasks.where((t) => t.priority == 'high').length;
    int pending = tasks.where((t) => t.status == 'pending').length;

    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _summaryCard('Pending', '$pending', Colors.orange),
          _summaryCard('High Priority', '$high', Colors.red),
          _summaryCard('Total', '${tasks.length}', Colors.blue),
        ],
      ),
    );
  }

  Widget _summaryCard(String title, String count, Color color) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Column(
          children: [
            Text(count,
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(title, style: TextStyle(color: color)),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'technical':
        return Colors.blue;
      case 'scheduling':
        return Colors.purple;
      case 'finance':
        return Colors.green;
      case 'safety':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _getPriorityIcon(String priority) {
    if (priority == 'high') return const Icon(Icons.warning, color: Colors.red);
    if (priority == 'medium')
      return const Icon(Icons.priority_high, color: Colors.orange);
    return const Icon(Icons.low_priority, color: Colors.green);
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../models/task.dart';
import '../providers/task_provider.dart';

class CreateTaskSheet extends ConsumerStatefulWidget {
  final Task? taskToEdit;
  const CreateTaskSheet({super.key, this.taskToEdit});

  @override
  ConsumerState<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends ConsumerState<CreateTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _assignedController = TextEditingController();
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    if (widget.taskToEdit != null) {
      final t = widget.taskToEdit!;
      _titleController.text = t.title;
      _descController.text = t.description;
      if (t.assignedTo != null) _assignedController.text = t.assignedTo!;
      if (t.dueDate != null) _dueDate = DateTime.parse(t.dueDate!);
      _selectedCategory = t.category;
      _selectedPriority = t.priority;
    }
  }

  bool _isClassifying = false;
  Map<String, dynamic>? _classification;
  
  // Overrides
  String? _selectedCategory;
  String? _selectedPriority;

  Future<void> _analyzeTask() async {
    if (_titleController.text.isEmpty) return;
    
    setState(() => _isClassifying = true);
    
    try {
      final api = ref.read(apiServiceProvider);
      // We need to add classify to ApiService, but for now we can infer or add it.
      // Wait, ApiService update corresponds to backend update.
      // I'll update ApiService first or inline the call? 
      // Better to update ApiService.
      // For now, I'll assume ApiService has classifyTask.
      final result = await api.classifyTask(_titleController.text, _descController.text);
      
      setState(() {
        _classification = result;
        _selectedCategory = result['category'];
        _selectedPriority = result['priority'];
        
        // Auto-fill entities if any
        final entities = result['extracted_entities'];
        if (entities != null) {
            if (entities['person'] != null) _assignedController.text = entities['person'];
            // formatting date is complex, skipping auto-fill for date picker from "tomorrow" string for now
        }
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => _isClassifying = false);
    }
  }

  Future<void> _saveTask() async {
    if (_titleController.text.isEmpty) return;

    try {
      if (widget.taskToEdit != null) {
        await ref.read(apiServiceProvider).updateTask(widget.taskToEdit!.id!, {
           'title': _titleController.text,
           'description': _descController.text,
           'category': _selectedCategory,
           'priority': _selectedPriority,
           'assigned_to': _assignedController.text.isNotEmpty ? _assignedController.text : null,
           'due_date': _dueDate?.toIso8601String(),
        });
      } else {
        await ref.read(apiServiceProvider).createTask(
          _titleController.text,
          _descController.text,
          category: _selectedCategory,
          priority: _selectedPriority,
          assignedTo: _assignedController.text.isNotEmpty ? _assignedController.text : null,
          dueDate: _dueDate?.toIso8601String(),
        );
      }
      
      ref.refresh(tasksProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error saving: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16, 
        right: 16, 
        top: 16
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(widget.taskToEdit != null ? "Edit Task" : "New Smart Task", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context))
            ],
          ),
          
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(labelText: "Task Title (e.g. Schedule urgent meeting)"),
            onChanged: (_) => setState(() => _classification = null), // Reset if changed
          ),
          TextField(
            controller: _descController,
            decoration: const InputDecoration(labelText: "Description"),
            maxLines: 2,
          ),
          const SizedBox(height: 10),
          
          // Action Bar: Date, Assign, Preview
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.calendar_today, color: _dueDate != null ? Colors.blue : Colors.grey),
                onPressed: () async {
                  final date = await showDatePicker(context: context, firstDate: DateTime.now(), lastDate: DateTime(2030), initialDate: DateTime.now());
                  if (date != null) setState(() => _dueDate = date);
                },
              ),
              if (_dueDate != null) Text(DateFormat('MMM d').format(_dueDate!)),
              
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: _assignedController,
                  decoration: const InputDecoration(hintText: "Assign to...", border: InputBorder.none, icon: Icon(Icons.person_outline)),
                ),
              ),
              
              ElevatedButton.icon(
                icon: _isClassifying ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.auto_awesome),
                label: const Text("Analyze"),
                onPressed: _analyzeTask,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.purple.shade50),
              )
            ],
          ),
          
          if (_classification != null) ...[
            const Divider(),
            const Text("AI Suggestions", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple)),
            const SizedBox(height: 10),
            
            // Category & Priority Overrides
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    items: ['general', 'scheduling', 'finance', 'technical', 'safety']
                        .map((c) => DropdownMenuItem(value: c, child: Text(c.toUpperCase()))).toList(),
                    onChanged: (v) => setState(() => _selectedCategory = v),
                    decoration: const InputDecoration(labelText: "Category", border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedPriority,
                    items: ['low', 'medium', 'high']
                        .map((p) => DropdownMenuItem(value: p, child: Text(p.toUpperCase()))).toList(),
                    onChanged: (v) => setState(() => _selectedPriority = v),
                    decoration: const InputDecoration(labelText: "Priority", border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
             const SizedBox(height: 10),
             if (_classification!['suggested_actions'] != null)
               Wrap(
                 spacing: 8,
                 children: (_classification!['suggested_actions'] as List).map((a) => Chip(
                   label: Text(a), 
                   backgroundColor: Colors.purple.withOpacity(0.1),
                   labelStyle: const TextStyle(fontSize: 10),
                 )).toList(),
               )
          ],
          
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _saveTask,
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            child: Text(widget.taskToEdit != null ? "Update Task" : "Create Task"),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

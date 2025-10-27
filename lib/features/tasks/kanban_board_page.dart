import 'package:flutter/material.dart';
import '../../services/task_service.dart';

class KanbanBoardPage extends StatelessWidget {
  final String projectId;
  const KanbanBoardPage({super.key, required this.projectId});

  @override
  Widget build(BuildContext context) {
    final service = TaskService();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks (Kanban)')
      ),
      body: StreamBuilder<List<Task>>(
        stream: service.getProjectTasks(projectId),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final tasks = snap.data!;
          final todo = tasks.where((t) => t.status == TaskStatus.todo).toList();
          final doing = tasks.where((t) => t.status == TaskStatus.inProgress).toList();
          final done = tasks.where((t) => t.status == TaskStatus.completed).toList();
          return _KanbanBoard(
            projectId: projectId,
            todo: todo,
            doing: doing,
            done: done,
            onMove: (task, status) async {
              await service.updateTask(projectId: projectId, taskId: task.id, status: status);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTaskDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreateTaskDialog(BuildContext context) async {
    final service = TaskService();
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Task'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Title')),
            TextField(controller: descCtrl, decoration: const InputDecoration(labelText: 'Description')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );

    if (confirmed == true) {
      await service.createTask(projectId: projectId, title: titleCtrl.text.trim(), description: descCtrl.text.trim());
    }
  }
}

class _KanbanBoard extends StatelessWidget {
  final String projectId;
  final List<Task> todo;
  final List<Task> doing;
  final List<Task> done;
  final Future<void> Function(Task task, TaskStatus status) onMove;

  const _KanbanBoard({
    required this.projectId,
    required this.todo,
    required this.doing,
    required this.done,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columnWidth = constraints.maxWidth / 3;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _KanbanColumn(
                width: columnWidth,
                title: 'To Do',
                color: Colors.grey.shade200,
                tasks: todo,
                onAccept: (t) => onMove(t, TaskStatus.todo),
              ),
              _KanbanColumn(
                width: columnWidth,
                title: 'In Progress',
                color: Colors.blue.shade50,
                tasks: doing,
                onAccept: (t) => onMove(t, TaskStatus.inProgress),
              ),
              _KanbanColumn(
                width: columnWidth,
                title: 'Done',
                color: Colors.green.shade50,
                tasks: done,
                onAccept: (t) => onMove(t, TaskStatus.completed),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final String title;
  final Color color;
  final List<Task> tasks;
  final double width;
  final void Function(Task) onAccept;

  const _KanbanColumn({
    required this.title,
    required this.color,
    required this.tasks,
    required this.width,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: MediaQuery.of(context).size.height - 120,
      padding: const EdgeInsets.all(12),
      child: DragTarget<Task>(
        onWillAccept: (data) => true,
        onAccept: onAccept,
        builder: (context, list, rejects) {
          return Card(
            color: color,
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const Divider(height: 1),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: tasks.length,
                    itemBuilder: (context, i) => _TaskCard(task: tasks[i]),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  const _TaskCard({required this.task});

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<Task>(
      data: task,
      feedback: Material(
        color: Colors.transparent,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: _card(context, dragging: true),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.4, child: _card(context)),
      child: _card(context),
    );
  }

  Widget _card(BuildContext context, {bool dragging = false}) {
    final service = TaskService();
    return Card(
      elevation: dragging ? 8 : 1,
      child: ListTile(
        title: Text(task.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: task.description != null && task.description!.isNotEmpty ? Text(task.description!) : null,
        trailing: PopupMenuButton<String>(
          onSelected: (v) async {
            if (v == 'edit') {
              // TODO: implement edit page
            }
            if (v == 'delete') {
              await service.deleteTask(task.projectId, task.id);
            }
            if (v == 'toggle') {
              await service.toggleTaskStatus(task.projectId, task.id, task.status);
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'toggle', child: Text('Toggle Done')),
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
          ],
        ),
      ),
    );
  }
}

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Get all tasks for a project
  Stream<List<Task>> getProjectTasks(String projectId) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  // Get tasks assigned to a user
  Stream<List<Task>> getUserTasks(String userId) {
    return _firestore
        .collectionGroup('tasks')
        .where('assignedTo', isEqualTo: userId)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  // Get tasks by status
  Stream<List<Task>> getTasksByStatus(String projectId, TaskStatus status) {
    return _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .where('status', isEqualTo: status.toString())
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();
    });
  }

  // Create a new task
  Future<String> createTask({
    required String projectId,
    required String title,
    String? description,
    String? assignedTo,
    DateTime? dueDate,
    TaskPriority priority = TaskPriority.medium,
    List<String> checklist = const [],
    List<String> attachments = const [],
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) throw Exception('User not authenticated');

    final taskRef = _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc();

    final task = Task(
      id: taskRef.id,
      projectId: projectId,
      title: title,
      description: description,
      createdBy: currentUser.uid,
      assignedTo: assignedTo,
      status: TaskStatus.todo,
      priority: priority,
      dueDate: dueDate,
      checklist: checklist.map((item) => ChecklistItem(text: item, completed: false)).toList(),
      attachments: attachments,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await taskRef.set(task.toMap());

    // Create notification for assignee
    if (assignedTo != null && assignedTo != currentUser.uid) {
      await _firestore.collection('notifications').add({
        'userId': assignedTo,
        'title': 'New Task Assigned',
        'body': 'You have been assigned: $title',
        'type': 'task',
        'data': {'taskId': taskRef.id, 'projectId': projectId},
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return taskRef.id;
  }

  // Update task
  Future<void> updateTask({
    required String projectId,
    required String taskId,
    String? title,
    String? description,
    String? assignedTo,
    DateTime? dueDate,
    TaskStatus? status,
    TaskPriority? priority,
    List<ChecklistItem>? checklist,
    List<String>? attachments,
  }) async {
    final updates = <String, dynamic>{
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (title != null) updates['title'] = title;
    if (description != null) updates['description'] = description;
    if (assignedTo != null) updates['assignedTo'] = assignedTo;
    if (dueDate != null) updates['dueDate'] = Timestamp.fromDate(dueDate);
    if (status != null) updates['status'] = status.toString();
    if (priority != null) updates['priority'] = priority.toString();
    if (checklist != null) {
      updates['checklist'] = checklist.map((item) => item.toMap()).toList();
    }
    if (attachments != null) updates['attachments'] = attachments;

    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .update(updates);
  }

  // Toggle task completion
  Future<void> toggleTaskStatus(String projectId, String taskId, TaskStatus currentStatus) async {
    final newStatus = currentStatus == TaskStatus.completed
        ? TaskStatus.inProgress
        : TaskStatus.completed;

    await updateTask(
      projectId: projectId,
      taskId: taskId,
      status: newStatus,
    );
  }

  // Toggle checklist item
  Future<void> toggleChecklistItem(
    String projectId,
    String taskId,
    int itemIndex,
  ) async {
    final taskDoc = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .get();

    final task = Task.fromFirestore(taskDoc);
    final updatedChecklist = List<ChecklistItem>.from(task.checklist);
    updatedChecklist[itemIndex] = ChecklistItem(
      text: updatedChecklist[itemIndex].text,
      completed: !updatedChecklist[itemIndex].completed,
    );

    await updateTask(
      projectId: projectId,
      taskId: taskId,
      checklist: updatedChecklist,
    );
  }

  // Add checklist item
  Future<void> addChecklistItem(
    String projectId,
    String taskId,
    String text,
  ) async {
    final taskDoc = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .get();

    final task = Task.fromFirestore(taskDoc);
    final updatedChecklist = List<ChecklistItem>.from(task.checklist)
      ..add(ChecklistItem(text: text, completed: false));

    await updateTask(
      projectId: projectId,
      taskId: taskId,
      checklist: updatedChecklist,
    );
  }

  // Delete task
  Future<void> deleteTask(String projectId, String taskId) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .delete();
  }

  // Add attachment
  Future<void> addAttachment(
    String projectId,
    String taskId,
    String attachmentUrl,
  ) async {
    await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .doc(taskId)
        .update({
      'attachments': FieldValue.arrayUnion([attachmentUrl]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Get task statistics for a project
  Future<TaskStats> getTaskStats(String projectId) async {
    final snapshot = await _firestore
        .collection('projects')
        .doc(projectId)
        .collection('tasks')
        .get();

    final tasks = snapshot.docs.map((doc) => Task.fromFirestore(doc)).toList();

    return TaskStats(
      total: tasks.length,
      todo: tasks.where((t) => t.status == TaskStatus.todo).length,
      inProgress: tasks.where((t) => t.status == TaskStatus.inProgress).length,
      completed: tasks.where((t) => t.status == TaskStatus.completed).length,
      overdue: tasks.where((t) => t.isOverdue).length,
    );
  }
}

// Task Model
class Task {
  final String id;
  final String projectId;
  final String title;
  final String? description;
  final String createdBy;
  final String? assignedTo;
  final TaskStatus status;
  final TaskPriority priority;
  final DateTime? dueDate;
  final List<ChecklistItem> checklist;
  final List<String> attachments;
  final DateTime createdAt;
  final DateTime updatedAt;

  Task({
    required this.id,
    required this.projectId,
    required this.title,
    this.description,
    required this.createdBy,
    this.assignedTo,
    required this.status,
    required this.priority,
    this.dueDate,
    this.checklist = const [],
    this.attachments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isOverdue {
    if (dueDate == null) return false;
    if (status == TaskStatus.completed) return false;
    return DateTime.now().isAfter(dueDate!);
  }

  int get checklistProgress {
    if (checklist.isEmpty) return 0;
    final completed = checklist.where((item) => item.completed).length;
    return ((completed / checklist.length) * 100).round();
  }

  factory Task.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      projectId: data['projectId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'],
      createdBy: data['createdBy'] ?? '',
      assignedTo: data['assignedTo'],
      status: TaskStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => TaskStatus.todo,
      ),
      priority: TaskPriority.values.firstWhere(
        (e) => e.toString() == data['priority'],
        orElse: () => TaskPriority.medium,
      ),
      dueDate: data['dueDate'] != null
          ? (data['dueDate'] as Timestamp).toDate()
          : null,
      checklist: (data['checklist'] as List<dynamic>?)
              ?.map((item) => ChecklistItem.fromMap(item))
              .toList() ??
          [],
      attachments: List<String>.from(data['attachments'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'projectId': projectId,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'assignedTo': assignedTo,
      'status': status.toString(),
      'priority': priority.toString(),
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'checklist': checklist.map((item) => item.toMap()).toList(),
      'attachments': attachments,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class ChecklistItem {
  final String text;
  final bool completed;

  ChecklistItem({required this.text, required this.completed});

  Map<String, dynamic> toMap() {
    return {'text': text, 'completed': completed};
  }

  factory ChecklistItem.fromMap(Map<String, dynamic> map) {
    return ChecklistItem(
      text: map['text'] ?? '',
      completed: map['completed'] ?? false,
    );
  }
}

enum TaskStatus {
  todo,
  inProgress,
  completed,
}

enum TaskPriority {
  low,
  medium,
  high,
  urgent,
}

class TaskStats {
  final int total;
  final int todo;
  final int inProgress;
  final int completed;
  final int overdue;

  TaskStats({
    required this.total,
    required this.todo,
    required this.inProgress,
    required this.completed,
    required this.overdue,
  });
}

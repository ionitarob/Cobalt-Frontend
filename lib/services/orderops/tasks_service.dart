import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../models/orderops/my_task.dart';

class TasksService {
  TasksService._();
  static final TasksService instance = TasksService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<List<MyTask>> getMyTasks({String? assignedTo}) async {
    final params = <String, String>{};
    if (assignedTo != null && assignedTo.isNotEmpty) params['assigned_to'] = assignedTo;

    final resp = await _dio.get<dynamic>('/orderops/my-tasks', queryParameters: params);
    final body = resp.data as Map? ?? {};
    final orderTasks = (body['order_tasks'] as List? ?? [])
        .map((e) => MyTask.fromJson({
              ...Map<String, dynamic>.from(e as Map),
              'type': 'order',
            }))
        .toList();
    final aprovTasks = (body['aprov_tasks'] as List? ?? [])
        .map((e) => MyTask.fromJson({
              ...Map<String, dynamic>.from(e as Map),
              'type': 'aprovisionamiento',
            }))
        .toList();
    return [...orderTasks, ...aprovTasks];
  }

  Future<void> toggleOrderTask(int idnbr, int taskId, bool done) async {
    await _dio.patch(
      '/orderops/agent-orders/$idnbr/tasks/$taskId',
      data: {'done': done},
    );
  }

  Future<void> toggleAprovTask(int aprovId, int taskId, bool done) async {
    await _dio.patch(
      '/orderops/aprovisionamiento/$aprovId/tasks/$taskId',
      data: {'done': done},
    );
  }
}

import 'package:dio/dio.dart';

import '../../core/api_client.dart';
import '../../models/orderops/order_task.dart';

class TemplatesService {
  TemplatesService._();
  static final TemplatesService instance = TemplatesService._();

  Dio get _dio => ApiClient.instance.dio;

  Future<List<ChecklistTemplate>> getTemplates({String? family}) async {
    final params = <String, String>{};
    if (family != null && family.isNotEmpty) params['family'] = family;

    final resp = await _dio.get<dynamic>('/orderops/checklist-templates', queryParameters: params);
    final list = resp.data is List
        ? resp.data as List
        : ((resp.data as Map?))?['results'] as List? ?? [];
    return list
        .map((e) => ChecklistTemplate.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  Future<ChecklistTemplate> createTemplate({
    required String name,
    String? description,
    String? family,
  }) async {
    final body = <String, dynamic>{'name': name};
    if (description != null && description.isNotEmpty) body['description'] = description;
    if (family != null && family.isNotEmpty) body['family'] = family;

    final resp = await _dio.post<dynamic>('/orderops/checklist-templates', data: body);
    return ChecklistTemplate.fromJson(Map<String, dynamic>.from(resp.data as Map));
  }

  Future<void> updateTemplate(
    int id, {
    String? name,
    String? description,
    String? family,
  }) async {
    final body = <String, dynamic>{};
    if (name != null) body['name'] = name;
    if (description != null) body['description'] = description;
    if (family != null) body['family'] = family;
    await _dio.patch('/orderops/checklist-templates/$id', data: body);
  }

  Future<void> deleteTemplate(int id) async {
    await _dio.delete('/orderops/checklist-templates/$id');
  }

  Future<ChecklistTemplateItem> addItem(int templateId, String titulo) async {
    final resp = await _dio.post<dynamic>(
      '/orderops/checklist-templates/$templateId/items',
      data: {'titulo': titulo},
    );
    return ChecklistTemplateItem.fromJson(Map<String, dynamic>.from(resp.data as Map));
  }

  Future<void> deleteItem(int templateId, int itemId) async {
    await _dio.delete('/orderops/checklist-templates/$templateId/items/$itemId');
  }

  Future<List<AgentOrderTask>> applyTemplate(int templateId, int idnbr) async {
    final resp = await _dio.post<dynamic>(
      '/orderops/checklist-templates/$templateId/apply',
      data: {'idnbr': idnbr},
    );
    final list = (resp.data as Map?)?['tasks'] as List? ?? [];
    return list
        .map((e) => AgentOrderTask.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  }
}

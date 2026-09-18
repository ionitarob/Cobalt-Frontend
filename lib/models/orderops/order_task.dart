class AgentOrderTask {
  final int id;
  final int idnbr;
  final String titulo;
  final bool done;
  final int sortOrder;

  const AgentOrderTask({
    required this.id,
    required this.idnbr,
    required this.titulo,
    this.done = false,
    this.sortOrder = 0,
  });

  AgentOrderTask copyWith({bool? done}) => AgentOrderTask(
        id: id, idnbr: idnbr, titulo: titulo,
        done: done ?? this.done, sortOrder: sortOrder,
      );

  factory AgentOrderTask.fromJson(Map<String, dynamic> j) => AgentOrderTask(
        id: (j['id'] as num?)?.toInt() ?? 0,
        idnbr: (j['idnbr'] as num?)?.toInt() ?? 0,
        titulo: j['titulo'] as String? ?? '',
        done: j['done'] as bool? ?? false,
        sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
      );
}

class ChecklistTemplateItem {
  final int id;
  final int templateId;
  final String titulo;
  final int sortOrder;

  const ChecklistTemplateItem({
    required this.id,
    required this.templateId,
    required this.titulo,
    this.sortOrder = 0,
  });

  factory ChecklistTemplateItem.fromJson(Map<String, dynamic> j) =>
      ChecklistTemplateItem(
        id: (j['id'] as num?)?.toInt() ?? 0,
        templateId: (j['template'] as num?)?.toInt() ?? 0,
        titulo: j['titulo'] as String? ?? '',
        sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
      );
}

class ChecklistTemplate {
  final int id;
  final String name;
  final String? description;
  final String? family;
  final DateTime? createdAt;
  final List<ChecklistTemplateItem> items;

  const ChecklistTemplate({
    required this.id,
    required this.name,
    this.description,
    this.family,
    this.createdAt,
    this.items = const [],
  });

  factory ChecklistTemplate.fromJson(Map<String, dynamic> j) =>
      ChecklistTemplate(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: j['name'] as String? ?? '',
        description: j['description'] as String?,
        family: j['family'] as String?,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'].toString())
            : null,
        items: (j['items'] as List? ?? [])
            .map((e) => ChecklistTemplateItem.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

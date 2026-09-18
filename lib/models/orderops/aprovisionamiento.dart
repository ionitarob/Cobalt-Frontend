class AprovisionamientoServicio {
  final int id;
  final String servicio;
  final String? detalles;
  final bool done;
  final int sortOrder;

  const AprovisionamientoServicio({
    required this.id,
    required this.servicio,
    this.detalles,
    this.done = false,
    this.sortOrder = 0,
  });

  AprovisionamientoServicio copyWith({bool? done}) => AprovisionamientoServicio(
        id: id, servicio: servicio, detalles: detalles,
        done: done ?? this.done, sortOrder: sortOrder,
      );

  factory AprovisionamientoServicio.fromJson(Map<String, dynamic> j) =>
      AprovisionamientoServicio(
        id: (j['id'] as num?)?.toInt() ?? 0,
        servicio: j['servicio'] as String? ?? '',
        detalles: j['detalles'] as String?,
        done: j['done'] as bool? ?? false,
        sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
      );
}

class AprovisionamientoTask {
  final int id;
  final String titulo;
  final bool done;
  final int sortOrder;

  const AprovisionamientoTask({
    required this.id,
    required this.titulo,
    this.done = false,
    this.sortOrder = 0,
  });

  AprovisionamientoTask copyWith({bool? done}) => AprovisionamientoTask(
        id: id, titulo: titulo, done: done ?? this.done, sortOrder: sortOrder,
      );

  factory AprovisionamientoTask.fromJson(Map<String, dynamic> j) =>
      AprovisionamientoTask(
        id: (j['id'] as num?)?.toInt() ?? 0,
        titulo: j['titulo'] as String? ?? '',
        done: j['done'] as bool? ?? false,
        sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
      );
}

class AprovisionamientoRecord {
  final int id;
  final String customer;
  final String? orderNbr;
  final String? notas;
  final String estado; // pendiente | enlazado
  final int? linkedIdnbr;
  final String? family;
  final String? subfamilies;
  final String? prioridad;
  final String? assignedTo;
  final String? assignedToName;
  final bool autoApply;
  final DateTime? createdAt;
  final List<AprovisionamientoServicio> servicios;
  final List<AprovisionamientoTask> tasks;

  const AprovisionamientoRecord({
    required this.id,
    required this.customer,
    this.orderNbr,
    this.notas,
    this.estado = 'pendiente',
    this.linkedIdnbr,
    this.family,
    this.subfamilies,
    this.prioridad,
    this.assignedTo,
    this.assignedToName,
    this.autoApply = true,
    this.createdAt,
    this.servicios = const [],
    this.tasks = const [],
  });

  bool get isLinked => estado == 'enlazado' && linkedIdnbr != null;
  int get taskDoneCount => tasks.where((t) => t.done).length;

  AprovisionamientoRecord copyWith({
    List<AprovisionamientoTask>? tasks,
    List<AprovisionamientoServicio>? servicios,
    String? estado,
    int? linkedIdnbr,
  }) =>
      AprovisionamientoRecord(
        id: id,
        customer: customer,
        orderNbr: orderNbr,
        notas: notas,
        estado: estado ?? this.estado,
        linkedIdnbr: linkedIdnbr ?? this.linkedIdnbr,
        family: family,
        subfamilies: subfamilies,
        prioridad: prioridad,
        assignedTo: assignedTo,
        assignedToName: assignedToName,
        autoApply: autoApply,
        createdAt: createdAt,
        servicios: servicios ?? this.servicios,
        tasks: tasks ?? this.tasks,
      );

  factory AprovisionamientoRecord.fromJson(Map<String, dynamic> j) =>
      AprovisionamientoRecord(
        id: (j['id'] as num?)?.toInt() ?? 0,
        customer: j['customer'] as String? ?? '',
        orderNbr: j['order_nbr'] as String?,
        notas: j['notas'] as String?,
        estado: j['estado'] as String? ?? 'pendiente',
        linkedIdnbr: (j['linked_idnbr'] as num?)?.toInt(),
        family: j['family'] as String?,
        subfamilies: j['subfamilies'] as String?,
        prioridad: j['prioridad'] as String?,
        assignedTo: j['assigned_to'] as String?,
        assignedToName: j['assigned_to_name'] as String?,
        autoApply: j['auto_apply'] as bool? ?? true,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'].toString())
            : null,
        servicios: (j['servicios'] as List? ?? [])
            .map((e) => AprovisionamientoServicio.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
        tasks: (j['tasks'] as List? ?? [])
            .map((e) => AprovisionamientoTask.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList(),
      );
}

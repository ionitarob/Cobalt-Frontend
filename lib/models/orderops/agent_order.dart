class AgentOrder {
  final int idnbr;
  final String orderNbr;
  final String customer;
  final DateTime? orderDate;
  final String estado;
  final String prioridad;
  final String? family;
  final List<String> subfamilies;
  final List<String> completedFamilies;
  final String agentStatus;
  final bool isBlocked;
  final String? assignedTo;
  final String? assignedToName;
  final String? sourcePrimaryDesc;
  final String? sourceCommentsExcerpt;
  final String? sourcePrimarySku;
  final String? department;
  final bool archived;
  final double llmConfidence;
  final String riskLevel;
  final int planTotal;
  final int planDone;
  final double planProgressPct;
  final String? stopReason;
  final DateTime? completedAt;
  final String? completionSummary;
  final String? completionAuthor;
  final int? proyecto;
  final int qualityPhotosCount;
  // Pre-computed lowercase for client-side search
  final String _searchOrderNbr;
  final String _searchCustomer;
  final String _searchDesc;

  AgentOrder({
    required this.idnbr,
    required this.orderNbr,
    required this.customer,
    this.orderDate,
    required this.estado,
    required this.prioridad,
    this.family,
    this.subfamilies = const [],
    this.completedFamilies = const [],
    required this.agentStatus,
    this.isBlocked = false,
    this.assignedTo,
    this.assignedToName,
    this.sourcePrimaryDesc,
    this.sourceCommentsExcerpt,
    this.sourcePrimarySku,
    this.department,
    this.archived = false,
    this.llmConfidence = 0.0,
    this.riskLevel = 'low',
    this.planTotal = 0,
    this.planDone = 0,
    this.planProgressPct = 0.0,
    this.stopReason,
    this.completedAt,
    this.completionSummary,
    this.completionAuthor,
    this.proyecto,
    this.qualityPhotosCount = 0,
  })  : _searchOrderNbr = orderNbr.toLowerCase().replaceAll('-', ''),
        _searchCustomer = customer.toLowerCase(),
        _searchDesc = (sourcePrimaryDesc ?? '').toLowerCase();

  String get subfamiliesDisplay => subfamilies.join(', ');

  bool matchesSearch(String query) {
    final q = query.toLowerCase().replaceAll('-', '');
    return _searchOrderNbr.contains(q) ||
        _searchCustomer.contains(q) ||
        _searchDesc.contains(q);
  }

  factory AgentOrder.fromJson(Map<String, dynamic> j) {
    List<String> parseList(dynamic v) {
      if (v is List) return v.map((e) => e.toString()).toList();
      if (v is String) return v.split(',').where((s) => s.isNotEmpty).toList();
      return [];
    }

    double? parseDouble(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v);
      return null;
    }

    final oNbr = j['order_nbr'] as String? ?? 'UNKNOWN';
    final cust = j['customer'] as String? ?? '';
    final desc = j['source_primary_desc'] as String? ?? '';

    return AgentOrder(
      idnbr: j['idnbr'] as int? ?? 0,
      orderNbr: oNbr,
      customer: cust,
      orderDate: j['order_date'] != null ? DateTime.tryParse(j['order_date']) : null,
      estado: j['estado'] as String? ?? '',
      prioridad: j['prioridad'] as String? ?? '',
      family: j['family'] as String?,
      subfamilies: parseList(j['subfamilies']),
      completedFamilies: parseList(j['completed_families']),
      agentStatus: j['agent_status'] as String? ?? 'pending',
      isBlocked: j['is_blocked'] == 1 || j['is_blocked'] == true,
      assignedTo: j['assigned_to'] as String?,
      assignedToName: j['assigned_to_name'] as String?,
      sourcePrimaryDesc: desc.isNotEmpty ? desc : null,
      sourceCommentsExcerpt: j['source_comments_excerpt'] as String?,
      sourcePrimarySku: j['source_primary_sku'] as String?,
      department: j['department'] as String?,
      archived: j['archived'] as bool? ?? false,
      llmConfidence: parseDouble(j['llm_confidence']) ?? 0.0,
      riskLevel: j['risk_level'] as String? ?? 'low',
      planTotal: j['plan_total'] as int? ?? 0,
      planDone: j['plan_done'] as int? ?? 0,
      planProgressPct: parseDouble(j['plan_progress_pct']) ?? 0.0,
      stopReason: j['stop_reason'] as String?,
      completedAt: j['completed_at'] != null ? DateTime.tryParse(j['completed_at']) : null,
      completionSummary: j['completion_summary'] as String?,
      completionAuthor: j['completion_author'] as String?,
      proyecto: j['proyecto_id'] as int?,
      qualityPhotosCount: j['quality_photos_count'] as int? ?? 0,
    );
  }
}

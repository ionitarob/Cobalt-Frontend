import 'agent_order.dart';

class OrderOpsDetail {
  final AgentOrder agentOrder;
  final List<WorkItem> workItems;
  final List<AgentOrderQualityLog> qualityLogs;
  final List<AgentOrderPhoto> photos;
  final List<AgentOrderObservation> observations;
  final List<AgentOrderService> services;
  final Map<String, dynamic>? latestLlm;
  final Map<String, dynamic>? sourceOrder;

  const OrderOpsDetail({
    required this.agentOrder,
    required this.workItems,
    required this.qualityLogs,
    required this.photos,
    required this.observations,
    required this.services,
    this.latestLlm,
    this.sourceOrder,
  });

  factory OrderOpsDetail.fromJson(Map<String, dynamic> j) {
    return OrderOpsDetail(
      agentOrder: AgentOrder.fromJson(
          (j['agent_order'] as Map<String, dynamic>?) ?? {}),
      workItems: (j['work_items'] as List? ?? [])
          .map((e) => WorkItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      qualityLogs: (j['quality_logs'] as List? ?? [])
          .map((e) =>
              AgentOrderQualityLog.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      photos: (j['photos'] as List? ?? [])
          .map((e) =>
              AgentOrderPhoto.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      observations: (j['observations'] as List? ?? [])
          .map((e) => AgentOrderObservation.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
      services: (j['services'] as List? ?? [])
          .map((e) =>
              AgentOrderService.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      latestLlm: j['latest_llm'] as Map<String, dynamic>?,
      sourceOrder: j['source_order'] as Map<String, dynamic>?,
    );
  }
}

// ---------------------------------------------------------------------------

class AgentOrderObservation {
  final int id;
  final int idnbr;
  final int? proyectoId;
  final String author;
  final String body;
  final DateTime createdAt;

  const AgentOrderObservation({
    required this.id,
    required this.idnbr,
    this.proyectoId,
    required this.author,
    required this.body,
    required this.createdAt,
  });

  factory AgentOrderObservation.fromJson(Map<String, dynamic> j) {
    return AgentOrderObservation(
      id: (j['id'] as num?)?.toInt() ?? 0,
      idnbr: (j['idnbr'] as num?)?.toInt() ?? 0,
      proyectoId: (j['proyecto_id'] as num?)?.toInt(),
      author: j['author'] as String? ?? '',
      body: j['body'] as String? ?? '',
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'].toString()) ??
              DateTime.utc(1970)
          : DateTime.utc(1970),
    );
  }
}

// ---------------------------------------------------------------------------

class AgentOrderPhoto {
  final int id;
  final int idnbr;
  final int? proyectoId;
  final String author;
  final String fileName;
  final String filePath;
  final String scope;
  final DateTime uploadedAt;

  const AgentOrderPhoto({
    required this.id,
    required this.idnbr,
    this.proyectoId,
    required this.author,
    required this.fileName,
    required this.filePath,
    required this.scope,
    required this.uploadedAt,
  });

  factory AgentOrderPhoto.fromJson(Map<String, dynamic> j) {
    return AgentOrderPhoto(
      id: (j['id'] as num?)?.toInt() ?? 0,
      idnbr: (j['idnbr'] as num?)?.toInt() ?? 0,
      proyectoId: (j['proyecto_id'] as num?)?.toInt(),
      author: j['author'] as String? ?? '',
      fileName: j['file_name'] as String? ?? '',
      filePath: j['file_path'] as String? ?? '',
      scope: j['scope'] as String? ?? '',
      uploadedAt: j['uploaded_at'] != null
          ? DateTime.tryParse(j['uploaded_at'].toString()) ??
              DateTime.utc(1970)
          : DateTime.utc(1970),
    );
  }
}

// ---------------------------------------------------------------------------

class AgentOrderService {
  final int id;
  final String family;
  final String description;
  final String? skuConfig;
  final double coste;
  final double margen;
  final double orderUnitPrice;
  final double theoreticalPvd;
  final String? collectionInfo;
  final bool isManual;
  final int? manualId;

  const AgentOrderService({
    required this.id,
    required this.family,
    required this.description,
    this.skuConfig,
    required this.coste,
    required this.margen,
    required this.orderUnitPrice,
    required this.theoreticalPvd,
    this.collectionInfo,
    required this.isManual,
    this.manualId,
  });

  factory AgentOrderService.fromJson(Map<String, dynamic> j) {
    double asDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return AgentOrderService(
      id: (j['id'] as num?)?.toInt() ?? 0,
      family: j['family'] as String? ?? '',
      description: j['description'] as String? ?? '',
      skuConfig: j['sku_config'] as String?,
      coste: asDouble(j['coste']),
      margen: asDouble(j['margen']),
      orderUnitPrice: asDouble(j['order_unit_price']),
      theoreticalPvd: asDouble(j['theoretical_pvd']),
      collectionInfo: j['collection_info'] as String?,
      isManual: j['is_manual'] as bool? ?? false,
      manualId: (j['manual_id'] as num?)?.toInt(),
    );
  }
}

// ---------------------------------------------------------------------------

class AgentServiceAlert {
  final int idnbr;
  final String orderNbr;
  final String customer;
  final String sku;
  final String description;
  final double coste;
  final double theoreticalPvd;
  final double orderUnitPrice;
  final String colorState;
  final String status;
  final String? notes;
  final DateTime? orderDate;

  const AgentServiceAlert({
    required this.idnbr,
    required this.orderNbr,
    required this.customer,
    required this.sku,
    required this.description,
    required this.coste,
    required this.theoreticalPvd,
    required this.orderUnitPrice,
    required this.colorState,
    required this.status,
    this.notes,
    this.orderDate,
  });

  factory AgentServiceAlert.fromJson(Map<String, dynamic> j) {
    double asDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    return AgentServiceAlert(
      idnbr: (j['idnbr'] as num?)?.toInt() ?? 0,
      orderNbr: j['order_nbr'] as String? ?? '',
      customer: j['customer'] as String? ?? '',
      sku: j['sku'] as String? ?? '',
      description: j['description'] as String? ?? '',
      coste: asDouble(j['coste']),
      theoreticalPvd: asDouble(j['theoretical_pvd']),
      orderUnitPrice: asDouble(j['order_unit_price']),
      colorState: j['color_state'] as String? ?? 'green',
      status: j['status'] as String? ?? 'pending',
      notes: j['notes'] as String?,
      orderDate: j['order_date'] != null
          ? DateTime.tryParse(j['order_date'].toString())
          : null,
    );
  }
}

// ---------------------------------------------------------------------------

class WorkItem {
  final int workItemId;
  final int idnbr;
  final String type;
  final String description;
  final String status;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const WorkItem({
    required this.workItemId,
    required this.idnbr,
    required this.type,
    required this.description,
    required this.status,
    this.assignedTo,
    required this.createdAt,
    this.updatedAt,
  });

  factory WorkItem.fromJson(Map<String, dynamic> j) {
    return WorkItem(
      workItemId: (j['work_item_id'] as num?)?.toInt() ?? 0,
      idnbr: (j['idnbr'] as num?)?.toInt() ?? 0,
      type: j['type'] as String? ?? '',
      description: j['description'] as String? ?? '',
      status: j['status'] as String? ?? 'open',
      assignedTo: j['assigned_to'] as String?,
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'].toString()) ??
              DateTime.utc(1970)
          : DateTime.utc(1970),
      updatedAt: j['updated_at'] != null
          ? DateTime.tryParse(j['updated_at'].toString())
          : null,
    );
  }
}

// ---------------------------------------------------------------------------

class AgentOrderQualityLog {
  final int id;
  final int idnbr;
  final String level;
  final String author;
  final String message;
  final DateTime createdAt;

  const AgentOrderQualityLog({
    required this.id,
    required this.idnbr,
    required this.level,
    required this.author,
    required this.message,
    required this.createdAt,
  });

  factory AgentOrderQualityLog.fromJson(Map<String, dynamic> j) {
    return AgentOrderQualityLog(
      id: (j['id'] as num?)?.toInt() ?? 0,
      idnbr: (j['idnbr'] as num?)?.toInt() ?? 0,
      level: j['level'] as String? ?? 'Info',
      author: j['author'] as String? ?? '',
      message: j['message'] as String? ?? '',
      createdAt: j['created_at'] != null
          ? DateTime.tryParse(j['created_at'].toString()) ??
              DateTime.utc(1970)
          : DateTime.utc(1970),
    );
  }
}

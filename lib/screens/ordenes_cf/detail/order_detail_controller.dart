
import 'package:flutter/foundation.dart';

import '../../../core/auth_service.dart';
import '../../../models/orderops/order_detail.dart';
import '../../../models/orderops/order_task.dart';
import '../../../services/orderops/order_detail_service.dart';
import '../../../services/orderops/orders_service.dart';
import '../../../services/orderops/tasks_service.dart';
import '../../../services/orderops/templates_service.dart';

class OrderDetailController extends ChangeNotifier {
  OrderDetailController({required this.idnbr});

  final int idnbr;

  OrderOpsDetail? _detail;
  List<AgentOrderTask> _tasks = [];
  List<AgentServiceAlert> _alerts = [];
  bool _loading = false;
  bool _saving = false;
  String? _error;

  final OrderDetailService _svc = OrderDetailService.instance;

  OrderOpsDetail? get detail => _detail;
  List<AgentOrderTask> get tasks => _tasks;
  List<AgentServiceAlert> get alerts => _alerts;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get error => _error;
  bool get isPrivileged =>
      ['admin', 'chief'].contains(AuthService.instance.currentUser?.role ?? '');
  bool get canViewFinancials => isPrivileged;

  // ── Load ─────────────────────────────────────────────────────────────────

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final r = await Future.wait<dynamic>([
        _svc.getOrderDetail(idnbr),
        _svc.getOrderTasks(idnbr),
        _svc.getServiceAlerts(idnbr),
      ]);
      _detail = r[0] as OrderOpsDetail;
      _tasks = (r[1] as List).cast<AgentOrderTask>();
      _alerts = (r[2] as List).cast<AgentServiceAlert>();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }
    // Services are fetched separately — a failure here must not block the rest of the view.
    if (_detail != null) {
      try {
        final fetchedServices = await _svc.getOrderServices(idnbr);
        if (fetchedServices.isNotEmpty) {
          _detail = _withServices(fetchedServices);
        }
      } catch (_) {
        // Keep whatever services came from getOrderDetail (likely empty).
      }
    }
    _loading = false;
    notifyListeners();
  }

  // ── Helpers — rebuild immutable detail with mutated lists ─────────────────

  OrderOpsDetail _withObservations(List<AgentOrderObservation> obs) =>
      OrderOpsDetail(
        agentOrder: _detail!.agentOrder,
        workItems: _detail!.workItems,
        qualityLogs: _detail!.qualityLogs,
        photos: _detail!.photos,
        observations: obs,
        services: _detail!.services,
        latestLlm: _detail!.latestLlm,
        sourceOrder: _detail!.sourceOrder,
      );

  OrderOpsDetail _withPhotos(List<AgentOrderPhoto> photos) => OrderOpsDetail(
        agentOrder: _detail!.agentOrder,
        workItems: _detail!.workItems,
        qualityLogs: _detail!.qualityLogs,
        photos: photos,
        observations: _detail!.observations,
        services: _detail!.services,
        latestLlm: _detail!.latestLlm,
        sourceOrder: _detail!.sourceOrder,
      );

  OrderOpsDetail _withServices(List<AgentOrderService> services) =>
      OrderOpsDetail(
        agentOrder: _detail!.agentOrder,
        workItems: _detail!.workItems,
        qualityLogs: _detail!.qualityLogs,
        photos: _detail!.photos,
        observations: _detail!.observations,
        services: services,
        latestLlm: _detail!.latestLlm,
        sourceOrder: _detail!.sourceOrder,
      );

  // ── Estado / AgentOrder mutations (reload required for nested model) ──────

  Future<void> updateEstado(String estado,
      {String? stopReason, bool force = false}) async {
    _saving = true;
    notifyListeners();
    try {
      await OrdersService.instance.updateAgentOrder(
        idnbr,
        estado: estado,
        forceEstado: force,
        stopReason: stopReason,
      );
      _detail = await _svc.getOrderDetail(idnbr);
    } catch (e) {
      _error = e.toString();
    }
    _saving = false;
    notifyListeners();
  }

  Future<void> updateFamily(List<String> subfamilies) async {
    _saving = true;
    notifyListeners();
    try {
      await OrdersService.instance
          .updateAgentOrder(idnbr, subfamilies: subfamilies);
      _detail = await _svc.getOrderDetail(idnbr);
    } catch (e) {
      _error = e.toString();
    }
    _saving = false;
    notifyListeners();
  }

  Future<void> updateAssignee({String? userId, String? name}) async {
    _saving = true;
    notifyListeners();
    try {
      await OrdersService.instance.updateAgentOrder(
        idnbr,
        assignedTo: userId,
        assignedToName: name,
      );
      _detail = await _svc.getOrderDetail(idnbr);
    } catch (e) {
      _error = e.toString();
    }
    _saving = false;
    notifyListeners();
  }

  Future<void> linkProject(int? proyectoId) async {
    _saving = true;
    notifyListeners();
    try {
      await OrdersService.instance
          .updateAgentOrder(idnbr, proyectoId: proyectoId);
      _detail = await _svc.getOrderDetail(idnbr);
    } catch (e) {
      _error = e.toString();
    }
    _saving = false;
    notifyListeners();
  }

  // ── Observations ──────────────────────────────────────────────────────────

  Future<void> addObservation(String body) async {
    if (_detail == null) return;
    _saving = true;
    notifyListeners();
    try {
      final obs = await _svc.addObservation(idnbr, body);
      _detail = _withObservations([..._detail!.observations, obs]);
    } catch (e) {
      _error = e.toString();
    }
    _saving = false;
    notifyListeners();
  }

  Future<void> editObservation(int obsId, String newBody) async {
    if (_detail == null) return;
    _saving = true;
    final prev = _detail!.observations.toList();
    _detail = _withObservations(
      _detail!.observations
          .map((o) => o.id == obsId
              ? AgentOrderObservation(
                  id: o.id,
                  idnbr: o.idnbr,
                  proyectoId: o.proyectoId,
                  author: o.author,
                  body: newBody,
                  createdAt: o.createdAt,
                )
              : o)
          .toList(),
    );
    notifyListeners();
    try {
      await _svc.editObservation(idnbr, obsId, newBody);
    } catch (e) {
      _detail = _withObservations(prev);
      _error = e.toString();
    }
    _saving = false;
    notifyListeners();
  }

  Future<void> deleteObservation(int obsId) async {
    if (_detail == null) return;
    _saving = true;
    final prev = _detail!.observations.toList();
    _detail = _withObservations(
        _detail!.observations.where((o) => o.id != obsId).toList());
    notifyListeners();
    try {
      await _svc.deleteObservation(idnbr, obsId);
    } catch (e) {
      _detail = _withObservations(prev);
      _error = e.toString();
    }
    _saving = false;
    notifyListeners();
  }

  // ── Photos ────────────────────────────────────────────────────────────────

  Future<void> uploadFile({
    required Uint8List bytes,
    required String fileName,
    required String scope,
  }) async {
    if (_detail == null) return;
    _saving = true;
    notifyListeners();
    try {
      final photo = await _svc.uploadFile(idnbr,
          bytes: bytes, fileName: fileName, scope: scope);
      _detail = _withPhotos([..._detail!.photos, photo]);
    } catch (e) {
      _error = e.toString();
    }
    _saving = false;
    notifyListeners();
  }

  Future<void> deleteFile(int photoId) async {
    if (_detail == null) return;
    _saving = true;
    final prev = _detail!.photos.toList();
    _detail =
        _withPhotos(_detail!.photos.where((p) => p.id != photoId).toList());
    notifyListeners();
    try {
      await _svc.deleteFile(idnbr, photoId);
    } catch (e) {
      _detail = _withPhotos(prev);
      _error = e.toString();
    }
    _saving = false;
    notifyListeners();
  }

  // ── Tasks ─────────────────────────────────────────────────────────────────

  Future<void> addTask(String titulo) async {
    _saving = true;
    notifyListeners();
    try {
      final task = await _svc.addTask(idnbr, titulo);
      _tasks = [..._tasks, task];
    } catch (e) {
      _error = e.toString();
    }
    _saving = false;
    notifyListeners();
  }

  Future<void> toggleTask(int taskId, bool done) async {
    _saving = true;
    final prev = _tasks.toList();
    _tasks = _tasks
        .map((t) => t.id == taskId ? t.copyWith(done: done) : t)
        .toList();
    notifyListeners();
    try {
      await TasksService.instance.toggleOrderTask(idnbr, taskId, done);
    } catch (e) {
      _tasks = prev;
      _error = e.toString();
    }
    _saving = false;
    notifyListeners();
  }

  Future<void> deleteTask(int taskId) async {
    _saving = true;
    final prev = _tasks.toList();
    _tasks = _tasks.where((t) => t.id != taskId).toList();
    notifyListeners();
    try {
      await _svc.deleteTask(idnbr, taskId);
    } catch (e) {
      _tasks = prev;
      _error = e.toString();
    }
    _saving = false;
    notifyListeners();
  }

  Future<void> applyTemplate(int templateId) async {
    _saving = true;
    notifyListeners();
    try {
      final newTasks =
          await TemplatesService.instance.applyTemplate(templateId, idnbr);
      _tasks = [..._tasks, ...newTasks];
    } catch (e) {
      _error = e.toString();
    }
    _saving = false;
    notifyListeners();
  }

  // ── Manual services ───────────────────────────────────────────────────────

  Future<void> addManualService(Map<String, dynamic> data) async {
    if (_detail == null) return;
    _saving = true;
    notifyListeners();
    try {
      await _svc.addManualService(idnbr, data);
      final services = await _svc.getOrderServices(idnbr);
      _detail = _withServices(services);
    } catch (e) {
      _error = e.toString();
    }
    _saving = false;
    notifyListeners();
  }

  Future<void> removeManualService(int manualId) async {
    if (_detail == null) return;
    _saving = true;
    final prev = _detail!.services.toList();
    _detail = _withServices(
        _detail!.services.where((s) => s.manualId != manualId).toList());
    notifyListeners();
    try {
      await _svc.removeManualService(idnbr, manualId);
      final services = await _svc.getOrderServices(idnbr);
      _detail = _withServices(services);
    } catch (e) {
      _detail = _withServices(prev);
      _error = e.toString();
    }
    _saving = false;
    notifyListeners();
  }

  // ── Service alerts ────────────────────────────────────────────────────────

  Future<void> updateServiceAlert(
      String sku, String status, String notes) async {
    _saving = true;
    final prev = _alerts.toList();
    _alerts = _alerts
        .map((a) => a.sku == sku
            ? AgentServiceAlert(
                idnbr: a.idnbr,
                orderNbr: a.orderNbr,
                customer: a.customer,
                sku: a.sku,
                description: a.description,
                coste: a.coste,
                theoreticalPvd: a.theoreticalPvd,
                orderUnitPrice: a.orderUnitPrice,
                colorState: a.colorState,
                status: status,
                notes: notes,
                orderDate: a.orderDate,
              )
            : a)
        .toList();
    notifyListeners();
    try {
      await _svc.updateServiceAlert(idnbr, sku, status, notes);
    } catch (e) {
      _alerts = prev;
      _error = e.toString();
    }
    _saving = false;
    notifyListeners();
  }

}

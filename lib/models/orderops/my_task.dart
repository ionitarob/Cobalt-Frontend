enum MyTaskType { order, aprovisionamiento }

class MyTask {
  final int id;
  final MyTaskType type;
  final int? idnbr;
  final int? aprovisionamientoId;
  final String orderNbr;
  final String customer;
  final String titulo;
  final bool done;
  final int sortOrder;

  const MyTask({
    required this.id,
    required this.type,
    this.idnbr,
    this.aprovisionamientoId,
    required this.orderNbr,
    required this.customer,
    required this.titulo,
    this.done = false,
    this.sortOrder = 0,
  });

  MyTask copyWith({bool? done}) => MyTask(
        id: id,
        type: type,
        idnbr: idnbr,
        aprovisionamientoId: aprovisionamientoId,
        orderNbr: orderNbr,
        customer: customer,
        titulo: titulo,
        done: done ?? this.done,
        sortOrder: sortOrder,
      );

  factory MyTask.fromJson(Map<String, dynamic> j) {
    final rawType = j['type'] as String? ?? 'order';
    return MyTask(
      id: (j['id'] as num?)?.toInt() ?? 0,
      type: rawType == 'aprovisionamiento'
          ? MyTaskType.aprovisionamiento
          : MyTaskType.order,
      idnbr: (j['idnbr'] as num?)?.toInt(),
      aprovisionamientoId:
          (j['aprovisionamiento_id'] as num?)?.toInt(),
      orderNbr: j['order_nbr'] as String? ?? '',
      customer: j['customer'] as String? ?? '',
      titulo: j['titulo'] as String? ?? '',
      done: j['done'] as bool? ?? false,
      sortOrder: (j['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

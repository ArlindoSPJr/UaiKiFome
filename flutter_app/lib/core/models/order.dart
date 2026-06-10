import 'order_item.dart';

enum OrderStatus {
  CRIADO,
  ACEITO,
  ENTREGADOR_DESIGNADO,
  EM_ENTREGA,
  ENTREGUE;

  String get label => switch (this) {
    CRIADO => 'Recebido',
    ACEITO => 'Aceito',
    ENTREGADOR_DESIGNADO => 'Entregador a caminho',
    EM_ENTREGA => 'Em entrega',
    ENTREGUE => 'Entregue',
  };
}

class Order {
  final String id;
  final String clientId;
  final String restaurantId;
  final String? deliveryPersonId;
  final OrderStatus status;
  final double total;
  final String deliveryAddress;
  final List<OrderItem> items;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Order({
    required this.id,
    required this.clientId,
    required this.restaurantId,
    this.deliveryPersonId,
    required this.status,
    required this.total,
    required this.deliveryAddress,
    this.items = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as String,
    clientId: json['clientId'] as String,
    restaurantId: json['restaurantId'] as String,
    deliveryPersonId: json['deliveryPersonId'] as String?,
    status: OrderStatus.values.firstWhere((s) => s.name == json['status']),
    total: (json['total'] as num).toDouble(),
    deliveryAddress: json['deliveryAddress'] as String,
    items: (json['items'] as List<dynamic>?)
        ?.map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
        .toList() ?? [],
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );

  Order copyWith({OrderStatus? status, DateTime? updatedAt}) => Order(
    id: id,
    clientId: clientId,
    restaurantId: restaurantId,
    deliveryPersonId: deliveryPersonId,
    status: status ?? this.status,
    total: total,
    deliveryAddress: deliveryAddress,
    items: items,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}

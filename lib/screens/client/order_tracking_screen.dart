import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_widget.dart';

class OrderTrackingScreen extends StatefulWidget {
  final Order order;

  const OrderTrackingScreen({Key? key, required this.order}) : super(key: key);

  @override
  State<OrderTrackingScreen> createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final _orderService = OrderService();
  List<Map<String, dynamic>> _trackingHistory = [];
  bool _isLoading = true;
  String _error = '';

  @override
  void initState() {
    super.initState();
    _loadTrackingHistory();
  }

  Future<void> _loadTrackingHistory() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      // Cargar historial de seguimiento desde el servicio
      final response = await _orderService.getOrderTrackingHistory(widget.order.id);

      if (response.success && response.data != null) {
        setState(() {
          _trackingHistory = response.data!;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Error al cargar historial de seguimiento';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  // CORREGIDO: Mapeo de estados a colores
  Color _getStatusColor(String status) {
    switch (status) {
      case 'entregado':
        return Colors.green;
      case 'en_proceso':
        return Colors.orange;
      case 'enviado':
        return Colors.blue.shade700;
      case 'confirmado':
        return Colors.blue;
      case 'pendiente':
        return Colors.amber;
      case 'cancelado':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  // CORREGIDO: Texto legible para estados
  String _getStatusText(String status) {
    switch (status) {
      case 'entregado':
        return 'Entregado';
      case 'en_proceso':
        return 'En Proceso';
      case 'enviado':
        return 'Enviado';
      case 'confirmado':
        return 'Confirmado';
      case 'pendiente':
        return 'Pendiente';
      case 'cancelado':
        return 'Cancelado';
      default:
        return status;
    }
  }

  // CORREGIDO: Íconos para cada estado
  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'entregado':
        return Icons.check_circle;
      case 'en_proceso':
        return Icons.build;
      case 'enviado':
        return Icons.local_shipping;
      case 'confirmado':
        return Icons.thumb_up;
      case 'pendiente':
        return Icons.pending;
      case 'cancelado':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Seguimiento de Pedido'),
      ),
      body: _isLoading
          ? const CustomLoadingIndicator(message: 'Cargando seguimiento...')
          : _error.isNotEmpty
              ? CustomErrorWidget(
                  message: _error,
                  onRetry: _loadTrackingHistory,
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Información del pedido
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Información del Pedido',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Número de pedido:'),
                      Text('#${widget.order.id}'),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Fecha:'),
                      Text(_formatDate(widget.order.fechaPedido)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total:'),
                      Text(
                        'S/. ${widget.order.montoTotal.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                  if (widget.order.numeroSeguimiento != null && widget.order.numeroSeguimiento!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Número de seguimiento:'),
                        Text(
                          widget.order.numeroSeguimiento!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estado actual:'),
                      Chip(
                        label: Text(
                          _getStatusText(widget.order.estadoPedido),
                          style: const TextStyle(color: Colors.white),
                        ),
                        backgroundColor: _getStatusColor(widget.order.estadoPedido),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Progreso del pedido
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Estado del Pedido',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  _buildOrderProgress(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Historial de seguimiento
          if (_trackingHistory.isNotEmpty) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Historial de Seguimiento',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildTrackingHistory(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Dirección de envío
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dirección de Envío',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text(widget.order.direccionEnvio),
                  if (widget.order.direccionFacturacion != null && widget.order.direccionFacturacion!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Dirección de Facturación:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(widget.order.direccionFacturacion!),
                  ],
                ],
              ),
            ),
          ),

          const Spacer(),

          // Botones de acción
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text('Volver al Historial'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      '/home',
                      (route) => false,
                    );
                  },
                  child: const Text('Seguir Comprando'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderProgress() {
    // CORREGIDO: Estados que coinciden con el backend
    final steps = [
      {'status': 'pendiente', 'label': 'Pendiente', 'icon': Icons.shopping_cart},
      {'status': 'confirmado', 'label': 'Confirmado', 'icon': Icons.check_circle},
      {'status': 'en_proceso', 'label': 'En Proceso', 'icon': Icons.build},
      {'status': 'enviado', 'label': 'Enviado', 'icon': Icons.local_shipping},
      {'status': 'entregado', 'label': 'Entregado', 'icon': Icons.verified},
    ];

    final currentStatusIndex = steps.indexWhere((step) => step['status'] == widget.order.estadoPedido);
    final isCancelled = widget.order.estadoPedido == 'cancelado';

    return Column(
      children: steps.asMap().entries.map((entry) {
        final index = entry.key;
        final step = entry.value;
        final isCompleted = index <= currentStatusIndex;
        final isCurrent = index == currentStatusIndex && !isCancelled;
        final isActive = isCompleted && !isCancelled;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isCancelled 
                      ? Colors.red 
                      : isActive 
                          ? Colors.green 
                          : Colors.grey.shade300,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  step['icon'] as IconData,
                  color: isActive ? Colors.white : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['label'] as String,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCancelled 
                            ? Colors.red 
                            : isActive 
                                ? Colors.green 
                                : Colors.grey,
                      ),
                    ),
                    if (isCurrent && _trackingHistory.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          _trackingHistory.last['comentario'] ?? 'Última actualización',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              if (isCurrent && !isCancelled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Actual',
                    style: TextStyle(
                      color: Colors.green.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              if (isCancelled && index == 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Cancelado',
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrackingHistory() {
    return Column(
      children: _trackingHistory.map((tracking) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.history,
                size: 16,
                color: Colors.grey.shade600,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_getStatusText(tracking['estado_nuevo'])}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (tracking['comentario'] != null && tracking['comentario'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          tracking['comentario'],
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ),
                    Text(
                      _formatDateTime(DateTime.parse(tracking['fecha_cambio'])),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
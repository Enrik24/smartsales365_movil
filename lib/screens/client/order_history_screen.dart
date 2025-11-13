import 'package:flutter/material.dart';
import '../../services/order_service.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';
import '../../widgets/neumorphic_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_widget.dart';
import '../../models/order_model.dart';
import 'catalog_screen.dart';
// Importar CatalogScreen si existe, si no, comentar esta línea
// import 'catalog_screen.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  final _orderService = OrderService();
  final List<Order> _orders = [];
  bool _isLoading = true;
  String _error = '';
  String _selectedFilter = 'Todos';

  // CORREGIDO: Estados que coinciden con el backend Django
  final List<String> _filters = [
    'Todos', 
    'pendiente', 
    'confirmado', 
    'en_proceso', 
    'enviado', 
    'entregado', 
    'cancelado'
  ];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final response = await _orderService.getOrders(
        status: _selectedFilter == 'Todos' ? null : _selectedFilter,
      );

      if (response.success && response.data != null) {
        setState(() {
          _orders.clear();
          _orders.addAll(response.data!);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Error al cargar pedidos';
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

  List<Order> get _filteredOrders {
    if (_selectedFilter == 'Todos') return _orders;
    return _orders.where((order) => order.estadoPedido == _selectedFilter).toList();
  }

  // CORREGIDO: Mapeo de estados a colores según el backend
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

  // CORREGIDO: Mapeo de estados a íconos
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

  void _showOrderDetail(Order order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Pedido #${order.id}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Chip(
                    label: Text(
                      _getStatusText(order.estadoPedido),
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: _getStatusColor(order.estadoPedido),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              
              // Información del pedido
              _buildOrderInfo(order),
              const SizedBox(height: 16),
              
              // Items del pedido
              _buildOrderItems(order.detalles),
              const SizedBox(height: 16),
              
              // Total
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'S/. ${order.montoTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // Información adicional
              if (order.numeroSeguimiento != null && order.numeroSeguimiento!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.local_shipping, size: 20, color: Colors.blue),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'N° Seguimiento: ${order.numeroSeguimiento!}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 16),
              
              // Botones de acción
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cerrar'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOrderInfo(Order order) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fecha: ${_formatDate(order.fechaPedido)}'),
        const SizedBox(height: 8),
        if (order.direccionEnvio != null && order.direccionEnvio!.isNotEmpty)
          Text('Dirección: ${order.direccionEnvio!}'),
        if (order.direccionFacturacion != null && order.direccionFacturacion!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Facturación: ${order.direccionFacturacion!}'),
        ],
      ],
    );
  }

  Widget _buildOrderItems(List<DetallePedido> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Productos:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  item.productoDetalle?.name ?? 'Producto',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
              Expanded(
                child: Text(
                  'x${item.cantidad}',
                  textAlign: TextAlign.center,
                ),
              ),
              Expanded(
                child: Text(
                  'S/.${item.precioUnitarioEnElMomento.toStringAsFixed(2)}',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
             border: Border(top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Subtotal:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                'S/. ${items.fold(0.0, (sum, item) => sum + (item.precioUnitarioEnElMomento * item.cantidad)).toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Pedidos'),
      ),
      body: Column(
        children: [
          // Filtros
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: _filters.map((filter) {
                final isSelected = filter == _selectedFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(
                      filter == 'Todos' ? 'Todos' : _getStatusText(filter)
                    ),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedFilter = selected ? filter : 'Todos';
                      });
                      _loadOrders();
                    },
                    backgroundColor: Colors.grey.shade200,
                    selectedColor: Colors.blue.shade100,
                    checkmarkColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.blue : Colors.grey.shade700,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 8),

          // Contador
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Text(
                  '${_filteredOrders.length} pedidos encontrados',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Lista de pedidos
          Expanded(
            child: _isLoading
                ? const CustomLoadingIndicator(message: 'Cargando pedidos...')
                : _error.isNotEmpty
                    ? CustomErrorWidget(
                        message: _error,
                        onRetry: _loadOrders,
                      )
                    : _filteredOrders.isEmpty
                        ? _buildEmptyState()
                        : RefreshIndicator(
                            onRefresh: _loadOrders,
                            child: ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: _filteredOrders.length,
                              itemBuilder: (context, index) {
                                final order = _filteredOrders[index];
                                return _buildOrderCard(order);
                              },
                            ),
                          ),
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildOrderCard(Order order) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: NeumorphicCard(
      onTap: () => _showOrderDetail(order),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del pedido
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pedido #${order.id}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Chip(
                  label: Text(
                    _getStatusText(order.estadoPedido),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: _getStatusColor(order.estadoPedido),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Fecha y total
            Text(
              'Fecha: ${_formatDate(order.fechaPedido)}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 4),
            Text(
              'Total: S/. ${order.montoTotal.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 12),

            // Items del pedido (resumen)
            _buildOrderItemsSummary(order.detalles),
            
            // Número de seguimiento si existe
            if (order.numeroSeguimiento != null && order.numeroSeguimiento!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.local_shipping, size: 16, color: Colors.blue.shade600),
                  const SizedBox(width: 4),
                  Text(
                    'Seguimiento: ${order.numeroSeguimiento!}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    )
    );
  }

  Widget _buildOrderItemsSummary(List<DetallePedido> items) {
    final firstItems = items.take(2).toList();
    final remainingCount = items.length - 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Productos:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        ...firstItems.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '• ${item.productoDetalle?.id?? 'Producto'}',
                  style: const TextStyle(fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'x${item.cantidad}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 8),
              Text(
                'S/.${item.precioUnitarioEnElMomento.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        )),
        if (remainingCount > 0)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              '+ $remainingCount productos más...',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
                fontSize: 12,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay pedidos',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedFilter == 'Todos' 
                ? 'Aún no has realizado ningún pedido'
                : 'No hay pedidos con estado "${_getStatusText(_selectedFilter)}"',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Navegar al catálogo - descomentar si CatalogScreen está disponible
              // Navigator.push(
              //   context,
              //   MaterialPageRoute(builder: (context) => const CatalogScreen()),
              // );
              // Por ahora, mostrar mensaje
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Navegar al catálogo')),
              );
            },
            child: const Text('Explorar Catálogo'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
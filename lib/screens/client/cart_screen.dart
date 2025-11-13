import 'package:flutter/material.dart';
import '../../models/cart_model.dart';
import '../../services/cart_service.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';
import '../../widgets/neumorphic_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_widget.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final CartService _cartService = CartService();
  Cart? _cart;
  bool _isLoading = true;
  String _error = '';
  bool _isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      setState(() {
        _isLoading = true;
        _error = '';
      });

      final response = await _cartService.getCart();

      if (response.success && response.data != null) {
        setState(() {
          _cart = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Error al cargar el carrito';
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

  Future<void> _updateQuantity(int productId, int newQuantity) async {
    if (_isUpdating || _cart == null) return;

    setState(() {
      _isUpdating = true;
    });

    try {
      if (newQuantity <= 0) {
        await _removeItem(productId);
      } else {
        final response = await _cartService.updateCartQuantity(productId, newQuantity);
        
        if (response.success) {
          await _loadCart(); // Recargar carrito para obtener datos actualizados
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response.error ?? 'Error al actualizar cantidad')),
          );
          await _loadCart(); // Recargar para sincronizar
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      await _loadCart(); // Recargar para sincronizar
    } finally {
      setState(() {
        _isUpdating = false;
      });
    }
  }

  Future<void> _removeItem(int productId) async {
    try {
      final response = await _cartService.removeFromCart(productId);
      
      if (response.success) {
        await _loadCart(); // Recargar carrito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producto eliminado del carrito')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error ?? 'Error al eliminar producto')),
        );
        await _loadCart(); // Recargar para sincronizar
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      await _loadCart(); // Recargar para sincronizar
    }
  }

  Future<void> _clearCart() async {
    try {
      final response = await _cartService.clearCart();
      
      if (response.success) {
        await _loadCart(); // Recargar carrito
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Carrito vaciado')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.error ?? 'Error al vaciar carrito')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  void _proceedToCheckout() {
    if (_cart != null && _cart!.items.isNotEmpty) {
      Navigator.pushNamed(context, '/checkout', arguments: _cart);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El carrito está vacío')),
      );
    }
  }

  void _continueShopping() {
    Navigator.pushNamed(context, '/catalog');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Carrito de Compras'),
        actions: [
          if (_cart != null && _cart!.items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearCart,
              tooltip: 'Vaciar carrito',
            ),
        ],
      ),
      body: _isLoading
          ? const CustomLoadingIndicator(message: 'Cargando carrito...')
          : _error.isNotEmpty
              ? CustomErrorWidget(
                  message: _error,
                  onRetry: _loadCart,
                )
              : _cart == null || _cart!.items.isEmpty
                  ? _buildEmptyState()
                  : _buildCartContent(),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 2),
    );
  }

  Widget _buildCartContent() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _cart!.items.length,
            itemBuilder: (context, index) {
              final item = _cart!.items[index];
              return NeumorphicCard(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Imagen del producto
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          image: DecorationImage(
                            image: NetworkImage(item.producto.imagenUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      
                      // Información del producto
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.producto.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'S/. ${item.producto.price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Subtotal: S/. ${(item.producto.price * item.cantidad).toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Controles de cantidad
                      Column(
                        children: [
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: _isUpdating 
                                    ? null 
                                    : () => _updateQuantity(item.producto.id, item.cantidad - 1),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: _isUpdating
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : Text(
                                        item.cantidad.toString(),
                                        style: const TextStyle(fontSize: 16),
                                      ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _isUpdating
                                    ? null
                                    : () => _updateQuantity(item.producto.id, item.cantidad + 1),
                              ),
                            ],
                          ),
                          TextButton(
                            onPressed: _isUpdating 
                                ? null 
                                : () => _removeItem(item.producto.id),
                            child: const Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Total y botón de checkout
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            border: Border.top: BorderSide(color: Colors.grey.shade300)),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total:',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'S/. ${_cart?.total.toStringAsFixed(2) ?? "0.00"}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _continueShopping,
                      child: const Text('Seguir Comprando'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _cart != null && _cart!.items.isNotEmpty ? _proceedToCheckout : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Pagar',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
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
            Icons.shopping_cart_outlined,
            size: 80,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'Tu carrito está vacío',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Explora nuestros productos y agrega algunos items a tu carrito',
            style: TextStyle(
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _continueShopping,
            child: const Text('Explorar Catálogo'),
          ),
        ],
      ),
    );
  }
}
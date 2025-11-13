import 'package:flutter/material.dart';
import '../../models/cart_model.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/cart_service.dart';
import '../../widgets/neumorphic_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_widget.dart';

class CheckoutScreen extends StatefulWidget {
  final Cart cart;

  const CheckoutScreen({super.key, required this.cart});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _zipCodeController = TextEditingController();
  final _billingAddressController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();

  final OrderService _orderService = OrderService();
  final CartService _cartService = CartService();

  String _selectedPaymentMethod = 'tarjeta_credito';
  bool _isProcessing = false;
  String _error = '';

  // CORREGIDO: Métodos de pago que coinciden con el backend
  final List<Map<String, dynamic>> _paymentMethods = [
    {'value': 'tarjeta_credito', 'label': 'Tarjeta de Crédito', 'icon': Icons.credit_card},
    {'value': 'tarjeta_debito', 'label': 'Tarjeta de Débito', 'icon': Icons.credit_card},
    {'value': 'paypal', 'label': 'PayPal', 'icon': Icons.payment},
    {'value': 'yape', 'label': 'Yape', 'icon': Icons.phone_android},
  ];

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    _billingAddressController.dispose();
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  Future<void> _processOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
        _error = '';
      });

      try {
        // Preparar datos para el pedido según el backend
        final orderData = {
          'direccion_envio': '${_addressController.text}, ${_cityController.text} ${_zipCodeController.text}',
          'direccion_facturacion': _billingAddressController.text.isNotEmpty 
              ? _billingAddressController.text 
              : '${_addressController.text}, ${_cityController.text} ${_zipCodeController.text}',
          'metodo_pago': _selectedPaymentMethod,
        };

        // Crear pedido en el backend
        final response = await _orderService.createOrder(orderData);

        if (response.success && response.data != null) {
          final newOrder = response.data!;
          
          // Limpiar carrito después de crear el pedido
          await _cartService.clearCart();

          // Navegar a la pantalla de seguimiento
          Navigator.pushNamedAndRemoveUntil(
            context,
            '/order-tracking',
            (route) => false,
            arguments: newOrder,
          );
        } else {
          setState(() {
            _error = response.error ?? 'Error al crear el pedido';
            _isProcessing = false;
          });
        }
      } catch (e) {
        setState(() {
          _error = 'Error de conexión: $e';
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalizar Compra'),
      ),
      body: _isProcessing
          ? const CustomLoadingIndicator(message: 'Procesando tu pedido...')
          : _buildCheckoutForm(),
    );
  }

  Widget _buildCheckoutForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mostrar error si existe
            if (_error.isNotEmpty) ...[
              CustomErrorWidget(
                message: _error,
                onRetry: () {
                  setState(() {
                    _error = '';
                  });
                },
              ),
              const SizedBox(height: 16),
            ],

            // Resumen del pedido
            _buildOrderSummary(),
            const SizedBox(height: 24),

            // Información de envío
            _buildShippingInfo(),
            const SizedBox(height: 24),

            // Información de facturación
            _buildBillingInfo(),
            const SizedBox(height: 24),

            // Método de pago
            _buildPaymentMethod(),
            const SizedBox(height: 24),

            // Botón de confirmar
            _buildConfirmButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary() {
    return NeumorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen del Pedido',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.cart.items.map((item) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  // Imagen del producto
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      image: DecorationImage(
                        image: NetworkImage(item.producto.imageUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.producto.name,
                          style: const TextStyle(fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'S/. ${item.producto.price.toStringAsFixed(2)} c/u',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'x${item.cantidad}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'S/. ${(item.producto.price * item.cantidad).toStringAsFixed(2)}',
                      textAlign: TextAlign.right,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            )),
            const Divider(),
            Row(
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
                  'S/. ${widget.cart.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShippingInfo() {
    return NeumorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de Envío',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressController,
              decoration: const InputDecoration(
                labelText: 'Dirección de Envío',
                hintText: 'Calle, número, departamento, etc.',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              maxLines: 2,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu dirección de envío';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Ciudad',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu ciudad';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _zipCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Código Postal',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.map),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Por favor ingresa tu código postal';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingInfo() {
    return NeumorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información de Facturación',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¿Usar la misma dirección para facturación?',
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _billingAddressController,
              decoration: const InputDecoration(
                labelText: 'Dirección de Facturación (opcional)',
                hintText: 'Dejar vacío para usar la misma dirección de envío',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.business),
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethod() {
    return NeumorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Método de Pago',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ..._paymentMethods.map((method) => RadioListTile<String>(
              title: Row(
                children: [
                  Icon(method['icon'] as IconData, size: 20),
                  const SizedBox(width: 8),
                  Text(method['label'] as String),
                ],
              ),
              value: method['value'] as String,
              groupValue: _selectedPaymentMethod,
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
            )),
            if (_selectedPaymentMethod == 'tarjeta_credito' || _selectedPaymentMethod == 'tarjeta_debito') ...[
              const SizedBox(height: 16),
              const Text(
                'Información de la Tarjeta',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cardNumberController,
                decoration: const InputDecoration(
                  labelText: 'Número de Tarjeta',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.credit_card),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el número de tarjeta';
                  }
                  if (value.length < 16) {
                    return 'El número de tarjeta debe tener 16 dígitos';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cardNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre en la Tarjeta',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingresa el nombre en la tarjeta';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cardExpiryController,
                      decoration: const InputDecoration(
                        labelText: 'MM/AA',
                        hintText: '12/25',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Fecha de expiración requerida';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _cardCvvController,
                      decoration: const InputDecoration(
                        labelText: 'CVV',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.lock),
                      ),
                      keyboardType: TextInputType.number,
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'CVV requerido';
                        }
                        if (value.length < 3) {
                          return 'CVV debe tener 3 dígitos';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
            ] else if (_selectedPaymentMethod == 'yape') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.purple.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.phone_android, size: 40, color: Colors.purple),
                    SizedBox(height: 8),
                    Text(
                      'Pago con Yape',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Se generará un código QR para que completes el pago desde tu app de Yape',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return Column(
      children: [
        // Términos y condiciones
        Row(
          children: [
            Icon(Icons.info_outline, size: 16, color: Colors.grey.shade600),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Al confirmar, aceptas nuestros términos y condiciones',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Botón de confirmar
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isProcessing ? null : _processOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isProcessing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Confirmar Pedido',
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
          ),
        ),
      ],
    );
  }
}
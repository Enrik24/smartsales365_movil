import 'package:flutter/material.dart';
import '../../models/cart_model.dart';
import '../../widgets/neumorphic_card.dart';
import '../../widgets/loading_indicator.dart';

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
  final _cardNumberController = TextEditingController();
  final _cardNameController = TextEditingController();
  final _cardExpiryController = TextEditingController();
  final _cardCvvController = TextEditingController();

  String _selectedPaymentMethod = 'credit_card';
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _paymentMethods = [
    {'value': 'credit_card', 'label': 'Tarjeta de Crédito', 'icon': Icons.credit_card},
    {'value': 'debit_card', 'label': 'Tarjeta de Débito', 'icon': Icons.credit_card},
    {'value': 'paypal', 'label': 'PayPal', 'icon': Icons.payment},
    {'value': 'cash', 'label': 'Efectivo', 'icon': Icons.money},
  ];

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _zipCodeController.dispose();
    _cardNumberController.dispose();
    _cardNameController.dispose();
    _cardExpiryController.dispose();
    _cardCvvController.dispose();
    super.dispose();
  }

  void _processOrder() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      // Simular procesamiento del pedido
      await Future.delayed(const Duration(seconds: 2));

      // Crear nueva orden
      final newOrder = Order(
        id: DateTime.now().millisecondsSinceEpoch,
        orderNumber: 'ORD-${DateTime.now().millisecondsSinceEpoch}',
        userId: 1, // En una app real esto vendría del auth
        items: widget.cart.items.map((cartItem) => OrderItem(
          productId: cartItem.product.id,
          productName: cartItem.product.name,
          quantity: cartItem.quantity,
          price: cartItem.product.price.toString(),
        )).toList(),
        total: widget.cart.totalAmount.toString(),
        orderDate: DateTime.now(),
        status: 'Pendientes',
        shippingAddress: '${_addressController.text}, ${_cityController.text} ${_zipCodeController.text}',
        paymentMethod: _selectedPaymentMethod,
      );

      setState(() {
        _isProcessing = false;
      });

      // Navegar a la pantalla de seguimiento
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/order-tracking',
        (route) => false,
        arguments: newOrder,
      );
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
            // Resumen del pedido
            _buildOrderSummary(),
            const SizedBox(height: 24),

            // Información de envío
            _buildShippingInfo(),
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
                  Expanded(
                    flex: 2,
                    child: Text(
                      item.product.name,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'x${item.quantity}',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      '\$${(item.subtotal).toStringAsFixed(2)}',
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
                  '\$${widget.cart.totalAmount.toStringAsFixed(2)}',
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
                labelText: 'Dirección',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.home),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor ingresa tu dirección';
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
            if (_selectedPaymentMethod == 'credit_card' || _selectedPaymentMethod == 'debit_card') ...[
              const SizedBox(height: 16),
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
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Fecha de expiración';
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
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _processOrder,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Confirmar Pedido',
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
      ),
    );
  }
}
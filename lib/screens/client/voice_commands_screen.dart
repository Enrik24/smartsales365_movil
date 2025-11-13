import 'package:flutter/material.dart';
import '../../widgets/neumorphic_card.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';

class VoiceCommandsScreen extends StatefulWidget {
  const VoiceCommandsScreen({super.key});

  @override
  State<VoiceCommandsScreen> createState() => _VoiceCommandsScreenState();
}

class _VoiceCommandsScreenState extends State<VoiceCommandsScreen> {
  bool _isListening = false;
  String _lastCommand = '';
  final List<String> _commandHistory = [];

  void _startListening() {
    setState(() {
      _isListening = true;
    });

    // Simular procesamiento de comando de voz
    Future.delayed(const Duration(seconds: 2), () {
      final commands = [
        'Mostrar productos en oferta',
        'Buscar smartphones',
        'Ver mi carrito',
        'Seguir mi pedido',
        'Historial de pedidos',
        'Contactar con soporte'
      ];
      final randomCommand = commands[DateTime.now().millisecondsSinceEpoch % commands.length];
      
      setState(() {
        _isListening = false;
        _lastCommand = randomCommand;
        _commandHistory.insert(0, randomCommand);
        if (_commandHistory.length > 5) {
          _commandHistory.removeLast();
        }
      });

      _executeCommand(randomCommand);
    });
  }

  void _stopListening() {
    setState(() {
      _isListening = false;
    });
  }

  void _executeCommand(String command) {
    // Aquí iría la lógica para ejecutar los comandos
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Ejecutando: $command')),
    );

    // Navegación basada en comandos
    switch (command.toLowerCase()) {
      case 'ver mi carrito':
        Navigator.pushNamed(context, '/cart');
        break;
      case 'historial de pedidos':
        Navigator.pushNamed(context, '/order-history');
        break;
      case 'mostrar productos en oferta':
        Navigator.pushNamed(context, '/catalog');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comandos de Voz'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Área principal de voz
            NeumorphicCard(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.mic,
                      size: 80,
                      color: _isListening ? Colors.red : Colors.blue,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _isListening ? 'Escuchando...' : 'Toca para hablar',
                      style: const TextStyle(fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    if (_lastCommand.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text(
                        'Último comando:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _lastCommand,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Comandos disponibles
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Comandos Disponibles:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: ListView(
                children: [
                  _buildCommandItem('"Mostrar productos en oferta"'),
                  _buildCommandItem('"Buscar [producto]"'),
                  _buildCommandItem('"Ver mi carrito"'),
                  _buildCommandItem('"Seguir mi pedido"'),
                  _buildCommandItem('"Historial de pedidos"'),
                  _buildCommandItem('"Contactar con soporte"'),
                  _buildCommandItem('"Estado de mi cuenta"'),
                  _buildCommandItem('"Promociones disponibles"'),
                ],
              ),
            ),

            // Historial de comandos
            if (_commandHistory.isNotEmpty) ...[
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Historial:',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  itemCount: _commandHistory.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: const Icon(Icons.history, size: 20),
                    title: Text(_commandHistory[index]),
                    onTap: () => _executeCommand(_commandHistory[index]),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isListening ? _stopListening : _startListening,
        backgroundColor: _isListening ? Colors.red : Colors.blue,
        child: Icon(
          _isListening ? Icons.stop : Icons.mic,
          color: Colors.white,
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 4),
    );
  }

  Widget _buildCommandItem(String command) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(Icons.record_voice_over, color: Colors.blue.shade600),
        title: Text(command),
        onTap: () {
          setState(() {
            _lastCommand = command.replaceAll('"', '');
          });
          _executeCommand(_lastCommand);
        },
      ),
    );
  }
}
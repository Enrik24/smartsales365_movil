import 'package:flutter/material.dart';
import '../../services/voice_command_service.dart';
import '../../widgets/neumorphic_card.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';
import '../../widgets/loading_indicator.dart';

class VoiceCommandsScreen extends StatefulWidget {
  const VoiceCommandsScreen({super.key});

  @override
  State<VoiceCommandsScreen> createState() => _VoiceCommandsScreenState();
}

class _VoiceCommandsScreenState extends State<VoiceCommandsScreen> {
  final VoiceCommandService _voiceService = VoiceCommandService();
  bool _isListening = false;
  bool _isProcessing = false;
  String _lastCommand = '';
  String _lastResponse = '';
  final List<VoiceCommandHistory> _commandHistory = [];
  final List<SuggestedCommand> _suggestedCommands = [];

  @override
  void initState() {
    super.initState();
    _initializeServices();
    _loadHistoryAndSuggestions();
  }

  Future<void> _initializeServices() async {
    await _voiceService.initialize();
  }

  Future<void> _loadHistoryAndSuggestions() async {
    final history = await _voiceService.getCommandHistory();
    final suggestions = await _voiceService.getSuggestedCommands();
    
    setState(() {
      _commandHistory.addAll(history);
      _suggestedCommands.addAll(suggestions);
    });
  }

  Future<void> _startListening() async {
    if (_isListening || _isProcessing) return;

    setState(() {
      _isListening = true;
      _lastResponse = '';
    });

    try {
      final result = await _voiceService.listenForCommand();

      setState(() {
        _isListening = false;
      });

      if (result.error != null) {
        setState(() {
          _lastResponse = 'Error: ${result.error}';
        });
        return;
      }

      if (result.transcript.isNotEmpty) {
        await _processCommand(result.transcript);
      }
    } catch (e) {
      setState(() {
        _isListening = false;
        _lastResponse = 'Error: $e';
      });
    }
  }

  Future<void> _processCommand(String transcript) async {
    setState(() {
      _isProcessing = true;
      _lastCommand = transcript;
      _lastResponse = 'Procesando con IA...';
    });

    try {
      // ✅ USAR EL NUEVO BACKEND CON OPENAI
      final response = await _voiceService.processWithOpenAI(transcript);

      setState(() {
        _isProcessing = false;
        _lastResponse = response.message ?? 
                       response.error ?? 
                       'Comando procesado con IA';
      });

      if (response.success) {
        _executeCommand(response);
        
        // Recargar historial para mostrar el nuevo comando
        await _loadHistoryAndSuggestions();
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _lastResponse = 'Error procesando comando: $e';
      });
    }
  }

  void _executeCommand(VoiceCommandResponse response) {
    // ✅ MEJORADO: Manejar diferentes tipos de acciones
    if (response.action == 'navigate' && response.target != null) {
      Navigator.pushNamed(context, response.target!);
    } else if (response.action == 'search' && response.parameters != null) {
      Navigator.pushNamed(
        context, 
        '/catalog', 
        arguments: response.parameters,
      );
    } else if (response.action == 'report') {
      // Navegar a pantalla de reportes con parámetros
      Navigator.pushNamed(
        context,
        '/reports',
        arguments: {
          'tipo_reporte': response.parameters?['tipo_reporte'],
          'fecha_inicio': response.parameters?['fecha_inicio'],
          'fecha_fin': response.parameters?['fecha_fin'],
          'formato': response.parameters?['formato'],
        },
      );
    }

    // Mostrar snackbar con la respuesta
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.message ?? 'Comando ejecutado'),
        backgroundColor: response.success ? Colors.green : Colors.orange,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  void _stopListening() {
    setState(() {
      _isListening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comandos de Voz IA'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadHistoryAndSuggestions,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Área principal de voz
            NeumorphicCard(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildStatusIndicator(),
                    const SizedBox(height: 20),
                    
                    if (_lastCommand.isNotEmpty) ...[
                      _buildCommandSection(),
                      const SizedBox(height: 16),
                    ],
                    
                    _buildActionButton(),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Comandos sugeridos
            _buildSuggestedCommands(),
            const SizedBox(height: 20),

            // Historial de comandos
            _buildCommandHistory(),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 4),
    );
  }

  Widget _buildStatusIndicator() {
    Color statusColor = Colors.grey;
    IconData statusIcon = Icons.mic;
    String statusText = 'Listo para escuchar';
    String? subText;

    if (_isListening) {
      statusColor = Colors.red;
      statusIcon = Icons.mic_none;
      statusText = 'Escuchando... Habla ahora';
    } else if (_isProcessing) {
      statusColor = Colors.orange;
      statusIcon = Icons.auto_awesome;
      statusText = 'Procesando con IA...';
      subText = 'Analizando tu comando';
    } else if (_lastResponse.isNotEmpty) {
      statusColor = _lastResponse.contains('Error') ? Colors.red : Colors.green;
      statusIcon = _lastResponse.contains('Error') ? Icons.error : Icons.check_circle;
      statusText = _lastResponse;
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              statusIcon,
              size: 64,
              color: statusColor,
            ),
            if (_isProcessing)
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          statusText,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 16,
            color: statusColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        if (subText != null) ...[
          const SizedBox(height: 4),
          Text(
            subText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),
        ],
        if (_isListening) ...[
          const SizedBox(height: 8),
          const LinearProgressIndicator(),
        ],
      ],
    );
  }

  Widget _buildCommandSection() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: Colors.blue),
                  const SizedBox(width: 8),
                  const Text(
                    'Comando detectado:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _lastCommand,
                style: const TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isListening ? _stopListening : _startListening,
        style: ElevatedButton.styleFrom(
          backgroundColor: _isListening ? Colors.red : Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          elevation: 2,
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
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isListening ? 'DETENER' : 'TOCA PARA HABLAR',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildSuggestedCommands() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Comandos Sugeridos por IA:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._suggestedCommands.take(6).map((command) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          elevation: 2,
          child: ListTile(
            leading: Icon(Icons.assistant, color: Colors.purple.shade600),
            title: Text(
              command.command,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(command.description),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              setState(() {
                _lastCommand = command.command;
              });
              _processCommand(command.command);
            },
          ),
        )),
      ],
    );
  }

  Widget _buildCommandHistory() {
    if (_commandHistory.isEmpty) {
      return const SizedBox();
    }

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Historial Reciente:',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.builder(
              itemCount: _commandHistory.length,
              itemBuilder: (context, index) {
                final command = _commandHistory[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  elevation: 1,
                  child: ListTile(
                    leading: Icon(
                      command.success ? Icons.check_circle : Icons.error,
                      color: command.success ? Colors.green : Colors.red,
                    ),
                    title: Text(
                      command.transcript,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${command.executionDate.hour}:${command.executionDate.minute.toString().padLeft(2, '0')} - ${command.commandType}',
                    ),
                    trailing: const Icon(Icons.replay, size: 16),
                    onTap: () {
                      setState(() {
                        _lastCommand = command.transcript;
                      });
                      _processCommand(command.transcript);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
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
    });

    try {
      // Procesar con OpenAI primero, si falla usa procesamiento local
      final response = await _voiceService.processWithOpenAI(transcript);

      setState(() {
        _isProcessing = false;
        _lastResponse = response.message ?? response.error ?? 'Comando procesado';
      });

      if (response.success) {
        _executeCommand(response);
        
        // Agregar al historial local
        _commandHistory.insert(0, VoiceCommandHistory(
          id: DateTime.now().millisecondsSinceEpoch,
          transcript: transcript,
          processedText: response.message,
          commandType: response.action ?? 'voice',
          executionDate: DateTime.now(),
          success: true,
        ));

        if (_commandHistory.length > 10) {
          _commandHistory.removeLast();
        }
      }
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _lastResponse = 'Error procesando comando: $e';
      });
    }
  }

  void _executeCommand(VoiceCommandResponse response) {
    if (response.action == 'navigate' && response.target != null) {
      Navigator.pushNamed(context, response.target!);
    } else if (response.action == 'search' && response.parameters != null) {
      Navigator.pushNamed(
        context, 
        '/catalog', 
        arguments: response.parameters,
      );
    }

    // Mostrar snackbar con la respuesta
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(response.message ?? 'Comando ejecutado'),
        backgroundColor: response.success ? Colors.green : Colors.orange,
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
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _loadHistoryAndSuggestions,
            tooltip: 'Actualizar historial',
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
                    // Indicador de estado
                    _buildStatusIndicator(),
                    const SizedBox(height: 20),
                    
                    // Comando y respuesta
                    if (_lastCommand.isNotEmpty) ...[
                      _buildCommandSection(),
                      const SizedBox(height: 16),
                    ],
                    
                    // Botón de acción
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

    if (_isListening) {
      statusColor = Colors.red;
      statusIcon = Icons.mic_none;
      statusText = 'Escuchando... Habla ahora';
    } else if (_isProcessing) {
      statusColor = Colors.orange;
      statusIcon = Icons.autorenew;
      statusText = 'Procesando con IA...';
    } else if (_lastResponse.isNotEmpty) {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = _lastResponse;
    }

    return Column(
      children: [
        Icon(
          statusIcon,
          size: 64,
          color: statusColor,
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
              const Text(
                'Comando detectado:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
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
          'Comandos Sugeridos:',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        ..._suggestedCommands.take(6).map((command) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: Icon(Icons.assistant, color: Colors.purple.shade600),
            title: Text(
              command.command,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
            subtitle: Text(command.description),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
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
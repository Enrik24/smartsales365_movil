// lib/screens/client/profile_screen.dart
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/account_settings_service.dart';
import '../../widgets/custom_bottom_navigation_bar.dart';
import '../../widgets/neumorphic_card.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/error_widget.dart';
// --> CORRECCIÓN: Importar el archivo donde se define el modelo User
import '../../models/smartsales_models.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // --> CORRECCIÓN: Nombres de clases actualizados
  final _authService = AuthService();
  final _accountService = AccountSettingsService();
  User? _currentUser;

  bool _isLoading = true;
  bool _isUpdating = false; // Estado para manejar la carga de la actualización
  String _error = '';
  bool _isEditing = false;

  // Controladores para edición
  final _formKey = GlobalKey<FormState>(); // Key para validación del formulario
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  @override
  void dispose() {
    // Limpiar controladores para evitar fugas de memoria
    _firstNameController.dispose();
    _lastNameController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _error = '';
    });

    try {
      final response = await _authService.getCurrentUser();
      if (!mounted) return;

      if (response.success && response.data != null) {
        setState(() {
          _currentUser = response.data;
          _fillControllers();
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = response.error ?? 'Error al cargar perfil';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error de conexión: $e';
        _isLoading = false;
      });
    }
  }

  void _fillControllers() {
    if (_currentUser != null) {
      _firstNameController.text = _currentUser!.firstName;
      _lastNameController.text = _currentUser!.lastName;
      _telefonoController.text = _currentUser!.telefono ?? '';
      _direccionController.text = _currentUser!.direccion ?? '';
    }
  }

  // --> MEJORA: Lógica de actualización implementada
  Future<void> _updateProfile() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() => _isUpdating = true);

      // Crea un mapa con los datos a actualizar
      final updateData = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'telefono': _telefonoController.text,
        'direccion': _direccionController.text,
      };

      // Llama al servicio para actualizar (deberás crear este método)
      final result = await _accountService.updateUserProfile(updateData);

      if (!mounted) return;

      setState(() => _isUpdating = false);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado exitosamente'), backgroundColor: Colors.green),
        );
        // Actualiza los datos locales y sale del modo edición
        setState(() {
          _currentUser = _currentUser?.copyWith(
            firstName: _firstNameController.text,
            lastName: _lastNameController.text,
            telefono: _telefonoController.text,
            direccion: _direccionController.text,
          );
          _isEditing = false;
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'No se pudo actualizar el perfil'), backgroundColor: Colors.red),
        );
      }
    }
  }


  Future<void> _changePassword() async {
    showDialog(
      context: context,
      builder: (context) => ChangePasswordDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          // Muestra un indicador de carga en el botón de guardar
          if (_isUpdating)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white))),
            )
          else ...[
            if (!_isEditing)
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar Perfil',
                onPressed: () => setState(() => _isEditing = true),
              ),
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.save_outlined),
                tooltip: 'Guardar Cambios',
                onPressed: _updateProfile,
              ),
            if (_isEditing)
              IconButton(
                  icon: const Icon(Icons.cancel_outlined),
                  tooltip: 'Cancelar',
                  onPressed: () {
                    setState(() {
                      _isEditing = false;
                      _fillControllers(); // Restaura los valores originales
                    });
                  }
              ),
          ]
        ],
      ),
      body: _isLoading
          ? const CustomLoadingIndicator(message: 'Cargando perfil...')
          : _error.isNotEmpty
          ? CustomErrorWidget(
        message: _error,
        onRetry: _loadUserData,
      )
          : Form( // --> MEJORA: Envuelve la información en un Form
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildProfileHeader(),
              const SizedBox(height: 24),
              _buildPersonalInfoSection(),
              const SizedBox(height: 24),
              _buildAccountSettingsSection(),
              const SizedBox(height: 24),
              // Las estadísticas solo se muestran si el usuario es cliente
              if (_currentUser?.role.toLowerCase() == 'cliente')
                _buildStatisticsSection(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const CustomBottomNavigationBar(currentIndex: 4),
    );
  }

  Widget _buildProfileHeader() {
    // Código sin cambios...
    return NeumorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.blue.shade100,
              child: Text(
                _currentUser?.firstName.isNotEmpty ?? false ? _currentUser!.firstName.substring(0, 1).toUpperCase() : 'U',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '${_currentUser?.firstName} ${_currentUser?.lastName}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            Text(
              _currentUser?.email ?? '',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 8),
            Chip(
              label: Text(
                _currentUser?.role.toUpperCase() ?? 'CLIENTE',
                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
              ),
              backgroundColor: _currentUser?.isAdmin ?? false ? Colors.red.shade700 : Colors.blue.shade700,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoSection() {
    // Código sin cambios...
    return NeumorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Información Personal',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildEditableField(
              label: 'Nombre',
              controller: _firstNameController,
              icon: Icons.person_outline,
              enabled: _isEditing,
              validator: (value) => (value?.isEmpty ?? true) ? 'El nombre no puede estar vacío' : null,
            ),
            const SizedBox(height: 12),
            _buildEditableField(
              label: 'Apellido',
              controller: _lastNameController,
              icon: Icons.person_outline,
              enabled: _isEditing,
              validator: (value) => (value?.isEmpty ?? true) ? 'El apellido no puede estar vacío' : null,
            ),
            const SizedBox(height: 12),
            _buildEditableField(
              label: 'Teléfono',
              controller: _telefonoController,
              icon: Icons.phone_outlined,
              enabled: _isEditing,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 12),
            _buildEditableField(
              label: 'Dirección',
              controller: _direccionController,
              icon: Icons.location_on_outlined,
              enabled: _isEditing,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            _buildReadOnlyField(
              label: 'Email',
              value: _currentUser?.email ?? '',
              icon: Icons.email_outlined,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    bool enabled = true,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    // --> MEJORA: Cambiado a TextFormField para validación
    return TextFormField(
      controller: controller,
      enabled: enabled,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: !enabled,
        fillColor: enabled ? Colors.white : Colors.grey.shade100,
      ),
    );
  }

  // Los demás widgets (`_buildReadOnlyField`, `_buildAccountSettingsSection`, etc.) permanecen iguales...
  Widget _buildReadOnlyField({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.grey.shade100,
      ),
    );
  }

  Widget _buildAccountSettingsSection() {
    return NeumorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configuración de Cuenta',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.lock_outline, color: Colors.blue),
              title: const Text('Cambiar Contraseña'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _changePassword,
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined, color: Colors.orange),
              title: const Text('Notificaciones'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navegar a configuración de notificaciones
                Navigator.of(context).pushNamed('/client_notifications');
              },
            ),
            ListTile(
              leading: const Icon(Icons.security_outlined, color: Colors.green),
              title: const Text('Privacidad y Seguridad'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navegar a privacidad
              },
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: Colors.purple),
              title: const Text('Ayuda y Soporte'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                // Navegar a ayuda
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatisticsSection() {
    return NeumorphicCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Mis Estadísticas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem('Compras', '12', Icons.shopping_cart_outlined),
                _buildStatItem('Favoritos', '8', Icons.favorite_border),
                _buildStatItem('Reseñas', '5', Icons.star_border),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String title, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 30, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(title, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }
}

// La clase ChangePasswordDialog permanece sin cambios...
class ChangePasswordDialog extends StatefulWidget {
  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _accountService = AccountSettingsService();
  bool _isLoading = false;
  bool _obscureOldPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _oldPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _changePassword() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    setState(() => _isLoading = true);

    final result = await _accountService.changePassword(
      oldPassword: _oldPasswordController.text,
      newPassword: _newPasswordController.text,
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contraseña cambiada exitosamente'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Error al cambiar contraseña'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Cambiar Contraseña'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _oldPasswordController,
                obscureText: _obscureOldPassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña Actual',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureOldPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureOldPassword = !_obscureOldPassword),
                  ),
                ),
                validator: (value) => (value?.isEmpty ?? true) ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _newPasswordController,
                obscureText: _obscureNewPassword,
                decoration: InputDecoration(
                  labelText: 'Nueva Contraseña',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNewPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Campo requerido';
                  if (value.length < 6) return 'Debe tener al menos 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmar Nueva Contraseña',
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Campo requerido';
                  if (value != _newPasswordController.text) return 'Las contraseñas no coinciden';
                  return null;
                },
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _changePassword,
          child: _isLoading
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))
              : const Text('Cambiar'),
        ),
      ],
    );
  }
}

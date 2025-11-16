import 'package:flutter/material.dart';
import 'package:flutter_application_movile/data/constants/cities.dart';
import 'package:flutter_application_movile/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _lastnameController = TextEditingController();
  String? _selectedCity;
  bool _toSave = false;

  @override
  void initState() {
    super.initState();
    _prefillCamposDesdeUsuario();
  }

  void _prefillCamposDesdeUsuario() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final fullName = authState.user.name?.trim() ?? '';
      if (fullName.isNotEmpty) {
        final parts = fullName.split(RegExp(r'\s+'));
        _nameController.text = parts.isNotEmpty ? parts.first : '';
        _lastnameController.text = parts.length > 1
            ? parts.sublist(1).join(' ')
            : '';
      }
    }

    final user = Supabase.instance.client.auth.currentUser;
    final cityMeta = user?.userMetadata?['city'] as String?;
    if (cityMeta != null && cityMeta.isNotEmpty) {
      _selectedCity = cityMeta;
      setState(() {});
    }
  }

  Future<void> _guardarCambios() async {
    final name = _nameController.text.trim();
    final apellido = _lastnameController.text.trim();
    final ciudad = _selectedCity;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío')),
      );
      return;
    }

    setState(() {
      _toSave = true;
    });

    try {
      final fullName = apellido.isNotEmpty ? '$name $apellido' : name;
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Actualizar tabla users (first_name)
      await client
          .from('users')
          .update({'first_name': fullName})
          .eq('id', user.id);

      // Actualizar metadata del user (full_name y city)
      await client.auth.updateUser(
        UserAttributes(
          data: {'full_name': fullName, if (ciudad != null) 'city': ciudad},
        ),
      );

      // Refrescar estado de autenticación para propagar cambios
      context.read<AuthBloc>().add(CheckAuthStatus());

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.toString()}')),
      );
    } finally {
      if (mounted)
        setState(() {
          _toSave = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          IconButton(
            onPressed: _toSave ? null : _guardarCambios,
            icon: const Icon(Icons.save),
            tooltip: 'Guardar cambios',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _lastnameController,
              decoration: const InputDecoration(
                labelText: 'Apellido',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCity,
              items: cities
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => _selectedCity = val),
              decoration: const InputDecoration(
                labelText: 'Ciudad de origen',
                border: OutlineInputBorder(),
              ),
              hint: const Text('Selecciona tu ciudad'),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _toSave ? null : _guardarCambios,
                icon: _toSave
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(_toSave ? 'Guardando...' : 'Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

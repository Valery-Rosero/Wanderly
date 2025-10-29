import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_application_movile/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutter_application_movile/data/constants/colombia_cities.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _apellidoController = TextEditingController();
  String? _ciudadSeleccionada;
  bool _guardando = false;

  @override
  void initState() {
    super.initState();
    _prefillCamposDesdeUsuario();
  }

  void _prefillCamposDesdeUsuario() {
    final authState = context.read<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final fullName = authState.usuario.nombre?.trim() ?? '';
      if (fullName.isNotEmpty) {
        final parts = fullName.split(RegExp(r'\s+'));
        _nombreController.text = parts.isNotEmpty ? parts.first : '';
        _apellidoController.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
    }

    final user = Supabase.instance.client.auth.currentUser;
    final ciudadMeta = user?.userMetadata?['ciudad'] as String?;
    if (ciudadMeta != null && ciudadMeta.isNotEmpty) {
      _ciudadSeleccionada = ciudadMeta;
      setState(() {});
    }
  }

  Future<void> _guardarCambios() async {
    final nombre = _nombreController.text.trim();
    final apellido = _apellidoController.text.trim();
    final ciudad = _ciudadSeleccionada;

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('El nombre no puede estar vacío')),
      );
      return;
    }

    setState(() { _guardando = true; });

    try {
      final fullName = apellido.isNotEmpty ? '$nombre $apellido' : nombre;
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      // Actualizar tabla usuarios (nombre)
      await client
          .from('usuarios')
          .update({'nombre': fullName})
          .eq('id', user.id);

      // Actualizar metadata del usuario (nombre y ciudad)
      await client.auth.updateUser(
        UserAttributes(
          data: {
            'nombre': fullName,
            if (ciudad != null) 'ciudad': ciudad,
          },
        ),
      );

      // Refrescar estado de autenticación para propagar cambios
      context.read<AuthBloc>().add(CheckAuthStatus());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() { _guardando = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Perfil'),
        actions: [
          IconButton(
            onPressed: _guardando ? null : _guardarCambios,
            icon: const Icon(Icons.save),
            tooltip: 'Guardar cambios',
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nombreController,
              decoration: const InputDecoration(
                labelText: 'Nombre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _apellidoController,
              decoration: const InputDecoration(
                labelText: 'Apellido',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _ciudadSeleccionada,
              items: colombiaCities
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (val) => setState(() => _ciudadSeleccionada = val),
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
                onPressed: _guardando ? null : _guardarCambios,
                icon: _guardando
                    ? const SizedBox(
                        width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: Text(_guardando ? 'Guardando...' : 'Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
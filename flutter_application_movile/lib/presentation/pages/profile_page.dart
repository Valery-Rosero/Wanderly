import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_application_movile/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutter_application_movile/data/datasources/local/profile_local_data_source.dart';
import 'package:flutter_application_movile/data/datasources/remote/usuarios_remote_data_source.dart';
import 'package:flutter_application_movile/data/constants/colombia_cities.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _ubicacionCtrl = TextEditingController();
  double? _baseLat;
  double? _baseLon;
  bool _cargando = true;
  bool _guardando = false;
  late List<String> _ciudades;
  String? _ciudadSeleccionada;

  String _toTitleCase(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return trimmed;
    final words = trimmed.toLowerCase().split(RegExp(r"\s+"));
    return words
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }

  @override
  void initState() {
    super.initState();
    _ciudades = List<String>.from(colombiaCities);
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      setState(() => _cargando = false);
      return;
    }

    try {
      final userId = authState.usuario.id;
      final local = kIsWeb ? null : await ProfileLocalDataSource.create();
      final remote = UsuariosRemoteDataSource(Supabase.instance.client);

      // Primero intenta local (offline), luego remoto para refrescar
      if (local != null) {
        final lp = await local.getProfile(userId);
        if (lp != null) {
          _nombreCtrl.text = lp.nombre ?? '';
          _ubicacionCtrl.text = lp.ubicacionBase ?? '';
          _ciudadSeleccionada = lp.ubicacionBase;
          if (_ciudadSeleccionada != null && !_ciudades.contains(_ciudadSeleccionada)) {
            _ciudades = [
              _ciudadSeleccionada!,
              ..._ciudades,
            ];
          }
          _baseLat = lp.baseLat;
          _baseLon = lp.baseLon;
        }
      }

      final rp = await remote.obtenerPerfil(userId);
      if (rp != null) {
        _nombreCtrl.text = rp.nombre ?? _nombreCtrl.text;
        _ubicacionCtrl.text = rp.ubicacionBase ?? _ubicacionCtrl.text;
        _ciudadSeleccionada = rp.ubicacionBase ?? _ciudadSeleccionada;
        if (_ciudadSeleccionada != null && !_ciudades.contains(_ciudadSeleccionada)) {
          _ciudades = [
            _ciudadSeleccionada!,
            ..._ciudades,
          ];
        }
        _baseLat = rp.baseLat ?? _baseLat;
        _baseLon = rp.baseLon ?? _baseLon;
        if (local != null) {
          await local.upsertProfile(rp, markSynced: true);
        }
      }
    } catch (_) {}
    setState(() => _cargando = false);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _guardando = true);

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Inicia sesión para actualizar tu perfil')),
        );
      }
      setState(() => _guardando = false);
      return;
    }
    final userId = authState.usuario.id;

    // Si no hay coordenadas base, intenta usar ubicación actual
    if (_baseLat == null || _baseLon == null) {
      try {
        final pos = await Geolocator.getCurrentPosition();
        _baseLat = pos.latitude;
        _baseLon = pos.longitude;
      } catch (_) {}
    }

    final perfil = UserProfile(
      userId: userId,
      nombre: _toTitleCase(_nombreCtrl.text.trim()),
      apellido: null,
      ubicacionBase: _ciudadSeleccionada,
      baseLat: _baseLat,
      baseLon: _baseLon,
    );

    final local = kIsWeb ? null : await ProfileLocalDataSource.create();
    final remote = UsuariosRemoteDataSource(Supabase.instance.client);

    try {
      if (local != null) {
        await local.upsertProfile(perfil, markSynced: false);
      }
      await remote.actualizarPerfil(perfil);
      if (local != null) {
        await local.upsertProfile(perfil, markSynced: true);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado')),);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar: $e')),
        );
      }
    }
    setState(() => _guardando = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil'),
      ),
      body: _cargando
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Encabezado con gradiente
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.person_pin_circle, color: Colors.white, size: 32),
                        SizedBox(width: 12),
                        Text('Tu perfil', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _nombreCtrl,
                                decoration: const InputDecoration(labelText: 'Nombre', prefixIcon: Icon(Icons.badge_outlined)),
                                validator: (v) => (v == null || v.trim().isEmpty) ? 'Requerido' : null,
                              ),
                              const SizedBox(height: 12),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                value: _ciudadSeleccionada,
                                items: _ciudades
                                    .map((c) => DropdownMenuItem<String>(
                                          value: c,
                                          child: Text(c),
                                        ))
                                    .toList(),
                                onChanged: (v) => setState(() => _ciudadSeleccionada = v),
                                decoration: const InputDecoration(
                                  labelText: 'Ciudad de origen',
                                  prefixIcon: Icon(Icons.location_city),
                                ),
                                validator: (v) => (v == null || v.isEmpty) ? 'Requerido' : null,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _guardando ? null : _guardar,
                                  child: _guardando
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Text('Guardar cambios'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
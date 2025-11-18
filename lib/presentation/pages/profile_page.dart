import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:wanderly/data/constants/cities.dart';
import 'package:wanderly/data/datasources/local/profile_local_data_source.dart';
import 'package:wanderly/data/datasources/remote/users_remote_data_source.dart';
import 'package:wanderly/presentation/bloc/auth/auth_bloc.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:wanderly/presentation/bloc/theme/theme_cubit.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  double? _baseLat;
  double? _baseLon;
  bool _loading = true;
  bool _toSave = false;
  late List<String> _cities;
  String? _selectedCity;

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
    _cities = List<String>.from(cities);
    _cargarPerfil();
  }

  Future<void> _cargarPerfil() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      setState(() => _loading = false);
      return;
    }

    try {
      final userId = authState.user.id;
      final local = kIsWeb ? null : await ProfileLocalDataSource.create();
      final remote = UsersRemoteDataSource(Supabase.instance.client);

      // Primero intenta local (offline), luego remoto para refrescar
      if (local != null) {
        final lp = await local.getProfile(userId);
        if (lp != null) {
          _nameCtrl.text = lp.name ?? '';
          _locationCtrl.text = lp.locationBase ?? '';
          _selectedCity = lp.locationBase;
          if (_selectedCity != null && !_cities.contains(_selectedCity)) {
            _cities = [_selectedCity!, ..._cities];
          }
          _baseLat = lp.baseLat;
          _baseLon = lp.baseLon;
        }
      }

      final rp = await remote.obtenerPerfil(userId);
      if (rp != null) {
        _nameCtrl.text = rp.name ?? _nameCtrl.text;
        _locationCtrl.text = rp.locationBase ?? _locationCtrl.text;
        _selectedCity = rp.locationBase ?? _selectedCity;
        if (_selectedCity != null && !_cities.contains(_selectedCity)) {
          _cities = [_selectedCity!, ..._cities];
        }
        _baseLat = rp.baseLat ?? _baseLat;
        _baseLon = rp.baseLon ?? _baseLon;
        if (local != null) {
          await local.upsertProfile(rp, markSynced: true);
        }
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _toSave = true);

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inicia sesión para actualizar tu perfil'),
          ),
        );
      }
      setState(() => _toSave = false);
      return;
    }
    final userId = authState.user.id;

    // Si no hay coordenadas base, intenta usar ubicación current
    if (_baseLat == null || _baseLon == null) {
      try {
        final pos = await Geolocator.getCurrentPosition();
        _baseLat = pos.latitude;
        _baseLon = pos.longitude;
      } catch (_) {}
    }

    final perfil = UserProfile(
      userId: userId,
      name: _toTitleCase(_nameCtrl.text.trim()),
      lastName: null,
      locationBase: _selectedCity,
      baseLat: _baseLat,
      baseLon: _baseLon,
    );

    final local = kIsWeb ? null : await ProfileLocalDataSource.create();
    final remote = UsersRemoteDataSource(Supabase.instance.client);

    try {
      if (local != null) {
        await local.upsertProfile(perfil, markSynced: false);
      }
      await remote.actualizarPerfil(perfil);
      if (local != null) {
        await local.upsertProfile(perfil, markSynced: true);
      }
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    }
    setState(() => _toSave = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Perfil')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Encabezado con gradiente
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.person_pin_circle,
                          color: Colors.white,
                          size: 32,
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Tu perfil',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Apariencia',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _ThemeModeSelector(),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              TextFormField(
                                controller: _nameCtrl,
                                decoration: const InputDecoration(
                                  labelText: 'Nombre',
                                  prefixIcon: Icon(Icons.badge_outlined),
                                ),
                                validator: (v) =>
                                    (v == null || v.trim().isEmpty)
                                    ? 'Requerido'
                                    : null,
                              ),
                              const SizedBox(height: 12),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: _selectedCity,
                                items: _cities
                                    .map(
                                      (c) => DropdownMenuItem<String>(
                                        value: c,
                                        child: Text(c),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedCity = v),
                                decoration: const InputDecoration(
                                  labelText: 'Ciudad de origen',
                                  prefixIcon: Icon(Icons.location_city),
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Requerido'
                                    : null,
                              ),
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _toSave ? null : _guardar,
                                  child: _toSave
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
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

class _ThemeModeSelector extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final mode = context.watch<ThemeCubit>().state;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: const Text('Claro'),
          selected: mode == ThemeMode.light,
          onSelected: (_) => context.read<ThemeCubit>().setLight(),
        ),
        ChoiceChip(
          label: const Text('Oscuro'),
          selected: mode == ThemeMode.dark,
          onSelected: (_) => context.read<ThemeCubit>().setDark(),
        ),
        ChoiceChip(
          label: const Text('Automático'),
          selected: mode == ThemeMode.system,
          onSelected: (_) => context.read<ThemeCubit>().setSystem(),
        ),
      ],
    );
  }
}

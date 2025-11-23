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
import 'package:image_picker/image_picker.dart';
import 'dart:ui' as ui;
import 'package:wanderly/data/datasources/remote/avatar_storage_data_source.dart';

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
  String? _avatarUrl;

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
    _cargarprofile();
  }

  Future<void> _cargarprofile() async {
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

      final rp = await remote.obtenerprofile(userId);
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

      // Leer avatar actual desde la tabla users
      try {
        final row = await Supabase.instance.client
            .from('users')
            .select('profile_picture')
            .eq('id', userId)
            .maybeSingle();
        _avatarUrl = (row?['profile_picture'] as String?);
      } catch (_) {}
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _pickAndUploadAvatar() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final userId = authState.user.id;

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return;

    // Validar que sea 1:1
    final bytes = await picked.readAsBytes();
    try {
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final img = frame.image;
      if (img.width != img.height) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Selecciona una imagen cuadrada (1:1)')),
        );
        return;
      }
    } catch (_) {}

    final storage = AvatarStorageDataSource(Supabase.instance.client);
    final url = await storage.uploadAvatar(userId: userId, bytes: bytes);
    if (url == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo subir la foto')),
        );
      }
      return;
    }

    await Supabase.instance.client
        .from('users')
        .update({'profile_picture': url})
        .eq('id', userId);

    setState(() => _avatarUrl = url);
    context.read<AuthBloc>().add(CheckAuthStatus());
  }

  Future<void> _deleteAvatar() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;
    final userId = authState.user.id;
    final storage = AvatarStorageDataSource(Supabase.instance.client);
    await storage.deleteAvatar(userId);
    await Supabase.instance.client
        .from('users')
        .update({'profile_picture': null})
        .eq('id', userId);
    setState(() => _avatarUrl = null);
    context.read<AuthBloc>().add(CheckAuthStatus());
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _toSave = true);

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Inicia sesión para actualizar tu profile'),
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

    final profile = UserProfile(
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
        await local.upsertProfile(profile, markSynced: false);
      }
      await remote.actualizarprofile(profile);
      if (local != null) {
        await local.upsertProfile(profile, markSynced: true);
      }
      // Refrescar estado de autenticación para propagar nombre desde Supabase
      context.read<AuthBloc>().add(CheckAuthStatus());
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('profile actualizado')));
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
    // Observar AuthBloc para disponer del avatar actual incluso antes de cargar _avatarUrl
    final authState = context.watch<AuthBloc>().state;
    final effectiveAvatarUrl = (_avatarUrl != null && _avatarUrl!.isNotEmpty)
        ? _avatarUrl!
        : (authState is AuthAuthenticated
              ? authState.user.profilePicture
              : null);
    return Scaffold(
      appBar: AppBar(title: const Text('profile')),
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
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        CircleAvatar(
                          key: ValueKey(effectiveAvatarUrl ?? 'empty'),
                          radius: 20,
                          backgroundColor: Colors.white24,
                          backgroundImage:
                              (effectiveAvatarUrl != null &&
                                  effectiveAvatarUrl.isNotEmpty)
                              ? NetworkImage(effectiveAvatarUrl)
                              : null,
                          child:
                              (effectiveAvatarUrl == null ||
                                  effectiveAvatarUrl.isEmpty)
                              ? const Icon(Icons.person, color: Colors.white)
                              : null,
                        ),
                        const Text(
                          'Tu profile',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: _pickAndUploadAvatar,
                          icon: const Icon(
                            Icons.camera_alt,
                            color: Colors.white,
                          ),
                          label: const Text(
                            'Cambiar foto',
                            style: TextStyle(color: Colors.white),
                            softWrap: true,
                            overflow: TextOverflow.visible,
                          ),
                        ),
                        if (_avatarUrl != null)
                          TextButton.icon(
                            onPressed: _deleteAvatar,
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Eliminar',
                              style: TextStyle(color: Colors.white),
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
                                  labelText: 'city de origen',
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

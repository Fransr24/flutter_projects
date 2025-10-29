// my_profile_screen_no_storage_compressed.dart
import 'dart:convert';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show Uint8List, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:smart_home_app/core/utils/utils.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  final ImagePicker _picker = ImagePicker();
  XFile? _pickedFile; // preview XFile
  Uint8List? _pickedBytes; // preview bytes (web & mobile)
  bool _isSavingToAuth = false;

  // Obtener imagen de la galeria
  Future<void> _pickImage() async {
    try {
      // imageQuality
      final XFile? picked = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 800, maxHeight: 800, imageQuality: 60);

      if (picked == null) return;

      final Uint8List bytes = await picked.readAsBytes();

      setState(() {
        _pickedFile = picked;
        _pickedBytes = bytes;
      });

      // Si el resultado sigue siendo grande, se avisa
      final sizeKb = (bytes.lengthInBytes / 1024).toStringAsFixed(0);
      if (bytes.lengthInBytes > 200 * 1024) {
        final proceed = await showDialog<bool>(
          context: context,
          builder:
              (c) => AlertDialog(
                title: const Text('Imagen grande'),
                content: Text(
                  'La imagen comprimida pesa aproximadamente $sizeKb KB. '
                  'Guardar como data URI en el perfil puede incrementar considerablemente el tamaño del perfil y no es recomendado.\n\n'
                  'Deseas continuar?',
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancelar')),
                  ElevatedButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Continuar')),
                ],
              ),
        );
        if (proceed != true) {
          // el usuario decidió no continuar con esa imagen: limpio preview
          setState(() {
            _pickedFile = null;
            _pickedBytes = null;
          });
          return;
        }
      }

      // Si está todo bien, preguntar dónde guardarla
      await _askWhereToSavePickedImage();
    } catch (e) {
      await showAlertDialog(context: context, title: 'Error', message: 'Error Obteniendo imagen $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error seleccionando imagen: $e')));
      }
    }
  }

  // Le pregunto si lo guardo en la db o solamente en el local
  Future<void> _askWhereToSavePickedImage() async {
    if (_pickedBytes == null) return;
    final user = FirebaseAuth.instance.currentUser;

    final choice = await showDialog<_SaveChoice>(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: const Text('¿Guardar imagen de perfil?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_pickedBytes != null) ClipOval(child: Image.memory(_pickedBytes!, width: 120, height: 120, fit: BoxFit.cover)),
              const SizedBox(height: 12),
              const Text(
                'Podés guardar esta imagen localmente (solo preview en esta sesión), '
                'o guardarla en tu perfil de Firebase Auth como data URI (Base64).',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              const Text(
                'Guardar en perfil (data URI) hará que la imagen quede almacenada en el campo photoURL de Auth. '
                'Esto puede aumentar mucho el tamaño del perfil y no es la práctica recomendada, ',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              if (user == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text('Nota: iniciá sesión para poder guardar en el perfil.', style: TextStyle(color: Colors.red)),
                ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(c).pop(_SaveChoice.cancel), child: const Text('Cancelar')),
            TextButton(onPressed: () => Navigator.of(c).pop(_SaveChoice.sessionOnly), child: const Text('Sólo preview')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(foregroundColor: Colors.white, backgroundColor: Colors.deepPurple),
              onPressed: user == null ? null : () => Navigator.of(c).pop(_SaveChoice.sessionOnly),
              child: const Text('Guardar en perfil'),
            ),
          ],
        );
      },
    );

    if (choice == null || choice == _SaveChoice.cancel) {
      return;
    }

    if (choice == _SaveChoice.sessionOnly) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imagen lista para vista previa (no guardada en perfil)')));
      }
      return;
    }

    if (choice == _SaveChoice.saveToAuth) {
      await _savePickedImageToAuth();
    }
  }

  // Guardo en Auth de database
  Future<void> _savePickedImageToAuth() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No hay usuario autenticado')));
      return;
    }
    if (_pickedBytes == null) return;

    setState(() => _isSavingToAuth = true);

    try {
      String mime = 'image/jpeg';
      final path = _pickedFile?.path ?? '';
      if (path.toLowerCase().endsWith('.png')) mime = 'image/png';
      if (path.toLowerCase().endsWith('.jpg') || path.toLowerCase().endsWith('.jpeg')) mime = 'image/jpeg';

      final b64 = base64Encode(_pickedBytes!);
      final dataUri = 'data:$mime;base64,$b64';

      final sizeKb = (_pickedBytes!.lengthInBytes / 1024).toStringAsFixed(0);
      final confirmed = await showDialog<bool>(
        context: context,
        builder:
            (c) => AlertDialog(
              title: const Text('Confirmar guardado en perfil'),
              content: Text(
                'La imagen comprimida tiene aproximadamente $sizeKb KB. Guardarla en el perfil de Auth como data URI puede aumentar mucho el tamaño del perfil. ¿Deseás continuar?',
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancelar')),
                ElevatedButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Continuar')),
              ],
            ),
      );

      if (confirmed != true) {
        setState(() => _isSavingToAuth = false);
        return;
      }

      await user.updatePhotoURL(dataUri);
      await user.reload();

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Imagen guardada en perfil (photoURL)')));
      }
    } catch (e) {
      await showAlertDialog(context: context, title: 'Error', message: 'Error guardando imagen en perfil: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error guardando imagen en perfil: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSavingToAuth = false);
    }
  }

  Future<void> _changeDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final controller = TextEditingController(text: user.displayName ?? '');

    final newName = await showDialog<String?>(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('Editar nombre'),
            content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Nombre')),
            actions: [
              TextButton(onPressed: () => Navigator.of(c).pop(null), child: const Text('Cancelar')),
              ElevatedButton(onPressed: () => Navigator.of(c).pop(controller.text.trim()), child: const Text('Guardar')),
            ],
          ),
    );

    if (newName != null && newName.isNotEmpty) {
      try {
        await user.updateDisplayName(newName);
        await user.reload();
        if (mounted) setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nombre actualizado')));
      } catch (e) {
        if (mounted) {
          await showAlertDialog(context: context, title: 'Error', message: 'Error actualizando: $e');
        }
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      await user.sendEmailVerification();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email de verificación enviado')));
    } catch (e) {
      if (mounted) {
        await showAlertDialog(context: context, title: 'Error', message: 'Error actualizando: $e');
      }
    }
  }

  Future<void> _signOut() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushReplacementNamed('/login');
  }

  Future<void> _deleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('Eliminar cuenta'),
            content: const Text('¿Estás seguro? Esta acción es irreversible.'),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );

    if (confirm != true) return;

    try {
      await user.delete();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      if (mounted) {
        await showAlertDialog(context: context, title: 'Error', message: 'Error actualizando: $e');
      }
    }
  }

  // Build avatar widget: priority
  // 1) if user.photoURL startsWith http(s) -> Image.network
  // 2) else if user.photoURL startsWith data: -> decode base64 -> Image.memory
  // 3) else if _pickedBytes != null -> Image.memory (preview)
  // 4) else -> placeholder
  Widget _buildAvatar(User? user) {
    final photo = user?.photoURL;
    if (photo != null && (photo.startsWith('http://') || photo.startsWith('https://'))) {
      return ClipOval(
        child: Image.network(photo, width: 140, height: 140, fit: BoxFit.cover, errorBuilder: (c, e, st) => _avatarPlaceholder(user)),
      );
    }

    if (photo != null && photo.startsWith('data:')) {
      try {
        final comma = photo.indexOf(',');
        final header = photo.substring(0, comma);
        final isBase64 = header.contains('base64');
        if (isBase64) {
          final b64 = photo.substring(comma + 1);
          final bytes = base64Decode(b64);
          return ClipOval(
            child: Image.memory(bytes, width: 140, height: 140, fit: BoxFit.cover, errorBuilder: (c, e, st) => _avatarPlaceholder(user)),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error obteniendo data: $e')));
      }
    }

    if (_pickedBytes != null) {
      return ClipOval(
        child: Image.memory(
          _pickedBytes!,
          width: 140,
          height: 140,
          fit: BoxFit.cover,
          errorBuilder: (c, e, st) => _avatarPlaceholder(user),
        ),
      );
    }

    return _avatarPlaceholder(user);
  }

  Widget _avatarPlaceholder(User? user) {
    final initials =
        (user?.displayName?.isNotEmpty == true)
            ? user!.displayName!.trim()[0].toUpperCase()
            : (user?.email?.isNotEmpty == true ? user!.email![0].toUpperCase() : '?');

    return CircleAvatar(
      radius: 70,
      backgroundColor: Colors.deepPurple.shade400,
      child: Text(initials, style: const TextStyle(fontSize: 44, color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi perfil'),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Cerrar sesión',
            icon: const Icon(Icons.logout_outlined),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder:
                    (_) => AlertDialog(
                      title: const Text('Cerrar sesión'),
                      content: const Text('¿Querés cerrar sesión?'),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('No')),
                        ElevatedButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Si')),
                      ],
                    ),
              );
              if (confirm == true) await _signOut();
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
        child: Column(
          children: [
            Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        Hero(tag: 'profile_avatar', child: _buildAvatar(user)),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: FloatingActionButton.small(
                            heroTag: 'pickImageBtn',
                            onPressed: _isSavingToAuth ? null : _pickImage,
                            child:
                                _isSavingToAuth
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                    : const Icon(Icons.edit),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(user?.displayName ?? 'Sin nombre', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text(user?.email ?? 'Sin email', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                    const SizedBox(height: 8),
                    if (user != null)
                      Chip(
                        backgroundColor: user.emailVerified ? Colors.green.shade50 : Colors.orange.shade50,
                        label: Text(
                          user.emailVerified ? 'Email verificado' : 'Email no verificado',
                          style: TextStyle(color: user.emailVerified ? Colors.green.shade700 : Colors.orange.shade700),
                        ),
                      ),
                    const SizedBox(height: 8),
                    const Text(
                      'Nota: la imagen se comprime a calidad 60 y 800px como máximo antes de guardarla.',
                      style: TextStyle(fontSize: 12, color: Colors.black54),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Información de la cuenta', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    _infoRow('UID', user?.uid ?? '—'),
                    const Divider(),
                    _infoRow('Correo', user?.email ?? '—'),
                    const Divider(),
                    _infoRow('Creada', user?.metadata.creationTime?.toLocal().toString() ?? '—'),
                    const Divider(),
                    _infoRow('Último acceso', user?.metadata.lastSignInTime?.toLocal().toString() ?? '—'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 18),

            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit),
                      title: const Text('Cambiar nombre'),
                      subtitle: const Text('Actualiza tu nombre para mostrar'),
                      trailing: ElevatedButton(onPressed: _changeDisplayName, child: const Text('Editar')),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.email_outlined),
                      title: const Text('Verificación de correo'),
                      subtitle: Text(user?.emailVerified == true ? 'Tu correo ya está verificado' : 'Tu correo no está verificado'),
                      trailing:
                          user?.emailVerified == true
                              ? null
                              : ElevatedButton(onPressed: _resendVerificationEmail, child: const Text('Reenviar')),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.delete_outline, color: Colors.red),
                      title: const Text('Eliminar cuenta', style: TextStyle(color: Colors.red)),
                      subtitle: const Text('Borra permanentemente tu cuenta'),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
                        onPressed: _deleteAccount,
                        child: const Text('Eliminar'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.black87))),
        ],
      ),
    );
  }
}

enum _SaveChoice { cancel, sessionOnly, saveToAuth }

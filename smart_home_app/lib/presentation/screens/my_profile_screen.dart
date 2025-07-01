import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

class MyProfileScreen extends ConsumerStatefulWidget {
  const MyProfileScreen({super.key});

  @override
  ConsumerState<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends ConsumerState<MyProfileScreen> {
  Future<void> pickAndUploadProfileImage() async {
    final picker = ImagePicker();
    final user = FirebaseAuth.instance.currentUser;

    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && user != null) {
      final File imageFile = File(pickedFile.path);

      final imgRef = FirebaseStorage.instance
          .ref('usuarios')
          .child(user.uid)
          .child('fotoperfil');

      try {
        await imgRef.putFile(imageFile);

        final downloadUrl = await imgRef.getDownloadURL();
        print("Imagen subida. URL: $downloadUrl");
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Error al subir imagen")));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor selecciona una imagen")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    TextEditingController inputProfilePicture = TextEditingController();
    File? _selectedImage;

    return Scaffold(
      appBar: AppBar(title: const Text("Perfil")),
      body: SingleChildScrollView(
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipOval(
                      child:
                          user!.photoURL != null
                              ? Image.network(
                                user.photoURL!,
                                width: 200,
                                height: 200,
                                fit: BoxFit.fitHeight,
                                errorBuilder: (
                                  BuildContext context,
                                  Object error,
                                  StackTrace? stackTrace,
                                ) {
                                  return Icon(Icons.person, size: 200);
                                },
                              )
                              : CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.deepOrangeAccent,
                                child: Icon(
                                  Icons.person,
                                  size: 50,
                                  color: Colors.white,
                                ),
                              ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: ClipOval(
                        child: Material(
                          color: Colors.black,
                          child: InkWell(
                            onTap: () async {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return StatefulBuilder(
                                    builder: (context, setStateDialog) {
                                      return AlertDialog(
                                        title: Text("Cambiar foto del perfil"),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (_selectedImage != null)
                                              ClipOval(
                                                child: Image.file(
                                                  _selectedImage!,
                                                  width: 100,
                                                  height: 100,
                                                  fit: BoxFit.cover,
                                                ),
                                              )
                                            else
                                              const Text(
                                                "No se ha seleccionado imagen.",
                                              ),
                                            const SizedBox(height: 16),
                                            ElevatedButton.icon(
                                              onPressed: () async {
                                                final picker = ImagePicker();
                                                final pickedFile = await picker
                                                    .pickImage(
                                                      source:
                                                          ImageSource.gallery,
                                                    );
                                                if (pickedFile != null) {
                                                  setStateDialog(() {
                                                    _selectedImage = File(
                                                      pickedFile.path,
                                                    );
                                                  });
                                                }
                                              },
                                              icon: Icon(Icons.photo_library),
                                              label: Text("Seleccionar imagen"),
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              _selectedImage = null;
                                              Navigator.of(context).pop();
                                            },
                                            child: Text("Cancelar"),
                                          ),
                                          ElevatedButton.icon(
                                            onPressed: () async {
                                              if (_selectedImage != null) {
                                                final imgRef = FirebaseStorage
                                                    .instance
                                                    .ref('usuarios')
                                                    .child(user.uid)
                                                    .child('fotoperfil');

                                                await imgRef.putFile(
                                                  _selectedImage!,
                                                );
                                                final downloadUrl =
                                                    await imgRef
                                                        .getDownloadURL();

                                                await user.updatePhotoURL(
                                                  downloadUrl,
                                                );
                                                await user.reload();

                                                setState(() {});
                                                Navigator.of(context).pop();
                                              }
                                            },
                                            icon: Icon(Icons.upload),
                                            label: Text("Subir"),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                },
                              );
                            },
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: Icon(Icons.edit, color: Colors.white),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user?.displayName ?? "Sin nombre",
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                user?.email ?? "Sin email",
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Text(
                user!.emailVerified
                    ? "Email verificado"
                    : "Email no verificado",
                style: TextStyle(
                  fontSize: 14,
                  color: user.emailVerified ? Colors.green : Colors.red,
                ),
              ),
              const SizedBox(height: 32),

              ElevatedButton.icon(
                icon: const Icon(Icons.edit),
                label: const Text("Cambiar nombre de usuario"),
                onPressed: () async {
                  final controller = TextEditingController(
                    text: user.displayName ?? "",
                  );
                  final name = await showDialog<String>(
                    context: context,
                    builder:
                        (context) => AlertDialog(
                          title: const Text("Editar nombre de usuario"),
                          content: TextField(controller: controller),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("Cancelar"),
                            ),
                            ElevatedButton(
                              onPressed:
                                  () => Navigator.pop(context, controller.text),
                              child: const Text("Guardar"),
                            ),
                          ],
                        ),
                  );
                  if (name != null && name.isNotEmpty) {
                    await user.updateDisplayName(name);
                    await user.reload();
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Nombre actualizado")),
                    );
                  }
                },
              ),
              if (!user.emailVerified) ...[
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  icon: const Icon(Icons.email_outlined),
                  label: const Text("Verificar email"),
                  onPressed: () async {
                    await user.sendEmailVerification();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Email de verificación enviado"),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 32),
              TextButton(
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder:
                        (_) => AlertDialog(
                          title: const Text("Eliminar cuenta"),
                          content: const Text(
                            "¿Estás seguro de eliminar tu cuenta? Esta acción es irreversible.",
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context, false),
                              child: const Text("Cancelar"),
                            ),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true),
                              child: const Text(
                                "Eliminar",
                                style: TextStyle(color: Colors.red),
                              ),
                            ),
                          ],
                        ),
                  );
                  // Si el usuario apreto en confirm, elimino la cuenta
                  if (confirm == true) {
                    await user.delete();
                    Navigator.of(context).pushReplacementNamed("/login");
                  }
                },
                child: const Text(
                  "Eliminar cuenta",
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

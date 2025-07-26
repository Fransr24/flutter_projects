import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final redIdProvider = StateProvider<String?>((ref) => null);

Future<bool> findAndSaveRouterId(BuildContext context, WidgetRef ref) async {
  final userId = FirebaseAuth.instance.currentUser!.uid;

  try {
    final snapshot =
        await FirebaseFirestore.instance
            .collection('redes')
            .where('usuarios', arrayContains: userId)
            .get();

    if (snapshot.docs.isEmpty) {
      await showAlertDialog(
        context: context,
        title: 'Sin emparejamiento',
        message: 'No se encontró ninguna red emparejada para tu cuenta.',
      );
      return connectUserWithRouter(context);
    }

    final redId = snapshot.docs.first.id;
    ref.read(redIdProvider.notifier).state = redId;
  } catch (e) {
    await showAlertDialog(
      context: context,
      title: 'Error',
      message: 'Ocurrió un problema al cargar los datos.',
    );
    return false;
  }
  return true;
}

Future<bool> connectUserWithRouter(BuildContext context) async {
  final routerId = await askRouterId(context);
  final user = FirebaseAuth.instance.currentUser;

  if (routerId == null || user == null) return false;
  if (routerId == "false") {
    return true;
  }
  try {
    final docRef = FirebaseFirestore.instance.collection('redes').doc(routerId);
    final snapshot = await docRef.get();

    if (snapshot.exists) {
      await docRef.update({
        'usuarios': FieldValue.arrayUnion([user.uid]),
        'emparejado': true,
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Usuario vinculado exitosamente")));
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("La red con ID '$routerId' no existe")),
      );
    }
  } catch (error) {
    await showAlertDialog(
      context: context,
      title: 'Error',
      message: "Error al vincular usuario: $error",
    );
    return false;
  }
  return false;
}

Future<String?> askRouterId(BuildContext context) async {
  return showDialog<String>(
    context: context,
    builder: (context) {
      final controller = TextEditingController();
      return AlertDialog(
        title: const Text('El usuario no esta emparejado con ninguna red'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Id de la red para emparejar',
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed:
                () async => {
                  Navigator.pop(context, 'false'),
                  await FirebaseAuth.instance.signOut(),
                },
            child: const Text('Cerrar Sesion'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Emparejar'),
          ),
        ],
      );
    },
  );
}

Future<void> showAlertDialog({
  required BuildContext context,
  required String title,
  required String message,
}) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            child: const Text('OK'),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
    },
  );
}

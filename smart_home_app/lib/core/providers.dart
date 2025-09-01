import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_home_app/core/utils/utils.dart';

final redIdProvider = StateProvider<String?>((ref) => null);

Future<bool> findAndSaveRouterId(BuildContext context, WidgetRef ref) async {
  final userId = FirebaseAuth.instance.currentUser!.uid;

  try {
    final snapshot = await FirebaseDatabase.instance.ref("network").get();

    if (!snapshot.exists) {
      await showAlertDialog(
        context: context,
        title: 'Sin emparejamiento',
        message: 'La red network no existe',
      );
      return connectUserWithRouter(context);
    }

    final networks = snapshot.value as Map<dynamic, dynamic>;
    String? foundRedId;
    networks.forEach((key, value) {
      if (foundRedId != null) return;
      final node = value as Map<dynamic, dynamic>;
      // voy viendo cada red y checkeo el campo users
      if (node.containsKey('Users')) {
        final usersNode = node['Users'] as Map<dynamic, dynamic>;
        // veo cada elemento de users (User1, User2) y checkeo si alguno de ellos es igual a userId
        for (var i = 1; i <= 4; i++) {
          final slot = 'User$i';
          if (usersNode.containsKey(slot) && usersNode[slot] == userId) {
            foundRedId = key.toString();
            break;
          }
        }
      }
    });
    // Si no hay red tiro error
    if (foundRedId == null) {
      await showAlertDialog(
        context: context,
        title: 'Sin emparejamiento',
        message: 'No se encontró ninguna red emparejada para tu cuenta.',
      );
      return connectUserWithRouter(context);
    }

    ref.read(redIdProvider.notifier).state = foundRedId!;
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
  if (routerId == "false") return true;

  try {
    final snapshot =
        await FirebaseDatabase.instance.ref("network/$routerId").get();
    // Me llevo la network cuyo id es el del cliente
    if (snapshot.exists) {
      final networks = snapshot.value as Map<dynamic, dynamic>;
      final redId = networks.keys.first.toString();

      final usersSnap =
          await FirebaseDatabase.instance.ref("network/$redId/Users").get();

      Map<dynamic, dynamic> usersMap = {};
      if (usersSnap.exists && usersSnap.value != null) {
        usersMap = Map<dynamic, dynamic>.from(usersSnap.value as Map);
      }

      // si ya está el usuario en alguno de los slots, no hago nada
      for (var i = 1; i <= 4; i++) {
        final slot = 'User$i';
        if (usersMap.containsKey(slot) && usersMap[slot] == user.uid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Usuario ya pertenece a la red")),
          );
          return true;
        }
      }

      // 2) Buscar primer slot vacío y escribir
      var slotToWrite = '';
      for (var i = 1; i <= 4; i++) {
        final slot = 'User$i';
        if (!usersMap.containsKey(slot) ||
            usersMap[slot] == null ||
            usersMap[slot].toString().isEmpty) {
          slotToWrite = slot;
          break;
        }
      }

      if (slotToWrite.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("La red ya tiene 4 usuarios.")),
        );
        return false;
      }

      await FirebaseDatabase.instance.ref("network/$redId/Users").update({
        slotToWrite: user.uid,
      });
      await FirebaseDatabase.instance.ref("network/$redId").update({
        "Connected": true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Usuario vinculado exitosamente")),
      );
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
            labelText: 'Id de la red del cliente a emparejar',
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

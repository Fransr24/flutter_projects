import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AddDeleteDevice extends StatefulWidget {
  const AddDeleteDevice({super.key});

  @override
  State<AddDeleteDevice> createState() => _AddDeleteDeviceState();
}

class _AddDeleteDeviceState extends State<AddDeleteDevice> {
  Future<void> uploadDeviceToDb() async {
    try {
      final data = FirebaseFirestore.instance.collection("luces").add({
        "encendido": false,
        "horario": "--:--:--".trim(),
        "temporizador": "--:--:--".trim(),
      });
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error agregando nuevo dispositivo")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    throw UnimplementedError();
  }
}

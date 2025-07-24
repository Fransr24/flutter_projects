import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Future<void> showEditAirConfigModal(
  BuildContext context,
  String selectedDevice,
  String temp,
  String fan,
  bool swing,
  String mode,
) async {
  await showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return _EditAirConfigModalBody(selectedDevice, temp, fan, swing, mode);
    },
  );
}

class _EditAirConfigModalBody extends StatefulWidget {
  String selectedDevice;
  String temp;
  String fan;
  bool swing;
  String mode;
  _EditAirConfigModalBody(
    this.selectedDevice,
    this.temp,
    this.fan,
    this.swing,
    this.mode,
  );

  @override
  State<_EditAirConfigModalBody> createState() =>
      _EditAirConfigModalBodyState();
}

class _EditAirConfigModalBodyState extends State<_EditAirConfigModalBody> {
  late TextEditingController temperatureController = TextEditingController();
  late String fan;
  late String temp;
  late bool swing;
  late String mode;

  @override
  void initState() {
    super.initState();
    fan = widget.fan;
    swing = widget.swing;
    mode = widget.mode;
    temp = widget.temp;
    temperatureController.text = temp;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Editar configuración",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: "Temperatura (°C)"),
            controller: temperatureController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "FAN"),
            value: fan,
            items:
                ["-", "I", "II", "III"]
                    .map(
                      (val) => DropdownMenuItem(value: val, child: Text(val)),
                    )
                    .toList(),
            onChanged: (val) {
              fan = val!;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Swing"),
            value: swing ? "ON" : "OFF",
            items:
                ["-", "ON", "OFF"]
                    .map(
                      (val) => DropdownMenuItem(value: val, child: Text(val)),
                    )
                    .toList(),
            onChanged: (val) {
              swing = val == "ON";
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Modo"),
            value: mode,
            items:
                ["-", "Frío", "Calor", "Auto"]
                    .map(
                      (val) => DropdownMenuItem(value: val, child: Text(val)),
                    )
                    .toList(),
            onChanged: (val) {
              mode = val!;
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance
                    .collection('aire')
                    .doc(widget.selectedDevice)
                    .update({
                      'temperatura': temperatureController.text,
                      'fan': fan,
                      "swing": swing,
                      "mode": mode,
                    });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Error seteando los datos")),
                );
              }
              Navigator.pop(context);
            },
            icon: const Icon(Icons.save),
            label: const Text("Guardar cambios"),
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
            ),
          ),
        ],
      ),
    );
  }
}

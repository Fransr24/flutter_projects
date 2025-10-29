import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

Future<void> showEditAirConfigModal(BuildContext context, String selectedDevice, int temp, int fan, int mode) async {
  await showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) {
      return _EditAirConfigModalBody(selectedDevice, temp, fan, mode);
    },
  );
}

class _EditAirConfigModalBody extends StatefulWidget {
  String selectedDevice;
  int temp;
  int fan;
  int mode;
  _EditAirConfigModalBody(this.selectedDevice, this.temp, this.fan, this.mode);

  @override
  State<_EditAirConfigModalBody> createState() => _EditAirConfigModalBodyState();
}

class _EditAirConfigModalBodyState extends State<_EditAirConfigModalBody> {
  late TextEditingController temperatureController = TextEditingController();
  late int fan;
  late int temp;
  late int mode;

  @override
  void initState() {
    super.initState();
    fan = widget.fan;
    mode = widget.mode;
    temp = widget.temp;
    temperatureController.text = temp.toString();
  }

  @override
  Widget build(BuildContext context) {
    final modeList = ["Frío", "Calor", "Auto"];
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Editar configuración", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextFormField(
            decoration: const InputDecoration(labelText: "Temperatura (°C)"),
            controller: temperatureController,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: "FAN"),
            value: fan,
            items: [1, 2, 3].map((val) => DropdownMenuItem(value: val, child: Text(val.toString()))).toList(),
            onChanged: (val) {
              fan = val!;
            },
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<int>(
            decoration: const InputDecoration(labelText: "Modo"),
            value: mode,
            items: [0, 1, 2].map((val) => DropdownMenuItem(value: val, child: Text(modeList[val]))).toList(),
            onChanged: (val) {
              mode = val!;
            },
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await FirebaseDatabase.instance.ref("air/${widget.selectedDevice}").update({
                  'ACTemp': int.tryParse(temperatureController.text) ?? 0,
                  'Speed': fan,
                  "Mode": mode,
                });
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error seteando los datos")));
              }
              Navigator.pop(context);
            },
            icon: const Icon(Icons.save),
            label: const Text("Guardar cambios"),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
          ),
        ],
      ),
    );
  }
}

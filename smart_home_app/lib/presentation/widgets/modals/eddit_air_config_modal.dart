import 'package:flutter/material.dart';

Future<void> showEditAirConfigModal(BuildContext context) async {
  await showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return const _EditAirConfigModalBody();
    },
  );
}

class _EditAirConfigModalBody extends StatelessWidget {
  const _EditAirConfigModalBody();

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
            initialValue: "24",
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "FAN"),
            value: "III",
            items:
                ["I", "II", "III"]
                    .map(
                      (val) => DropdownMenuItem(value: val, child: Text(val)),
                    )
                    .toList(),
            onChanged: (_) {},
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Swing"),
            value: "ON",
            items:
                ["ON", "OFF"]
                    .map(
                      (val) => DropdownMenuItem(value: val, child: Text(val)),
                    )
                    .toList(),
            onChanged: (_) {},
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: const InputDecoration(labelText: "Modo"),
            value: "Frío",
            items:
                ["Frío", "Calor", "Auto"]
                    .map(
                      (val) => DropdownMenuItem(value: val, child: Text(val)),
                    )
                    .toList(),
            onChanged: (_) {},
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: guardar cambios
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

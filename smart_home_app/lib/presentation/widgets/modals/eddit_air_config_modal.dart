import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';

Future<void> showEditAirConfigModal(BuildContext context, String selectedDevice, int temp, int fan, bool swing) async {
  await showModalBottomSheet(
    context: context,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
    builder: (context) {
      return _EditAirConfigModalBody(selectedDevice, temp, fan, swing);
    },
  );
}

class _EditAirConfigModalBody extends StatefulWidget {
  String selectedDevice;
  int temp;
  int fan;
  bool swing;
  _EditAirConfigModalBody(this.selectedDevice, this.temp, this.fan, this.swing);

  @override
  State<_EditAirConfigModalBody> createState() => _EditAirConfigModalBodyState();
}

class _EditAirConfigModalBodyState extends State<_EditAirConfigModalBody> {
  late TextEditingController temperatureController = TextEditingController();
  late int fan;
  late int temp;
  late bool swing;

  @override
  void initState() {
    super.initState();
    fan = widget.fan;
    swing = widget.swing;
    temp = widget.temp;
    temperatureController.text = temp.toString();
  }

  @override
  void dispose() {
    temperatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final bottomInset = media.viewInsets.bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.85),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Editar configuración", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              const Text(
                "Esta configuracion sirve para que recuerdes como tenias configurado el aire acondicionado al momento de guardarlo. No sirve para configurarlo directamente. Para eso vuelva a configurar el aire acondicionado en opciones avanzadas",
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w200),
              ),
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
                  if (val == null) return;
                  setState(() {
                    fan = val;
                  });
                },
              ),
              const SizedBox(height: 12),

              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Swing (oscilación)'),
                subtitle: Text(swing ? 'Activado' : 'Desactivado'),
                value: swing,
                onChanged: (v) => setState(() => swing = v),
              ),
              const SizedBox(height: 20),

              // Botones
              ElevatedButton.icon(
                onPressed: () async {
                  try {
                    await FirebaseDatabase.instance.ref("air/${widget.selectedDevice}").update({
                      'AcTemp': int.tryParse(temperatureController.text) ?? 0,
                      'Speed': fan,
                      'Swing': swing,
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
        ),
      ),
    );
  }
}

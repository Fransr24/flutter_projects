import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_home_app/presentation/screens/light_screen.dart';

enum DeviceType { luces, aire }

class DeviceAppBar extends StatefulWidget implements PreferredSizeWidget {
  final String selectedDevice;
  final DeviceType type;
  final void Function(String) onDevChanged;

  DeviceAppBar({
    super.key,
    required this.selectedDevice,
    required this.onDevChanged,
    required this.type,
  });

  @override
  State<DeviceAppBar> createState() => _DeviceAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _DeviceAppBarState extends State<DeviceAppBar> {
  late String _selectedDevice = "";
  late DeviceType _type;
  late List<String> _availableDevices = [];
  late String collectionName;

  @override
  void initState() {
    super.initState();
    _type = widget.type;
    collectionName = _getCollectionName(widget.type);
    _fetchDevices();
  }

  String _getCollectionName(DeviceType type) {
    switch (type) {
      case DeviceType.luces:
        return 'luces';
      case DeviceType.aire:
        return 'aires';
    }
  }

  Future<void> _fetchDevices() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance.collection(collectionName).get();

      final deviceNames = snapshot.docs.map((doc) => doc.id).toList();
      print(deviceNames);

      setState(() {
        _availableDevices = deviceNames;
        _selectedDevice =
            deviceNames.isNotEmpty ? deviceNames.first : 'Sin dispositivos';
      });

      widget.onDevChanged(_selectedDevice);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error actualizando dispositivo")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController controller = TextEditingController();

    return AppBar(
      title: Row(
        children: [
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDevice,
                isExpanded: true,
                items:
                    _availableDevices.map((dev) {
                      return DropdownMenuItem(value: dev, child: Text(dev));
                    }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedDevice = newValue;
                    });
                    widget.onDevChanged(newValue);
                  }
                },
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Eliminar Dispositivo',
            onPressed: () {
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: Text("Eliminando Luces de $_selectedDevice"),
                      content: Text(
                        "¿Estas seguro que quieres eliminar este elemento?",
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text("No"),
                        ),
                        TextButton(
                          onPressed: () async {
                            if (_type == DeviceType.luces) {
                              await FirebaseFirestore.instance
                                  .collection("luces")
                                  .doc(_selectedDevice)
                                  .delete();
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Modulo ${_selectedDevice} eliminado",
                                ),
                              ),
                            );
                            await _fetchDevices();

                            Navigator.of(context).pop();
                          },
                          child: Text("Si"),
                        ),
                      ],
                    ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Agregar modulo',
            onPressed: () async {
              if (_type == DeviceType.luces) {
                await showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return AlertDialog(
                          title: const Text('Agregar nuevo modulo de luces'),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText:
                                      'Inserte el nombre de las nuevas luces',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ],
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: () async {
                                await FirebaseFirestore.instance
                                    .collection("luces")
                                    .doc(controller.text)
                                    .set({
                                      'encendido': false,
                                      'horario': "--:--",
                                      'temporizador': "00",
                                    });
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Modulo ${controller.text} agregado",
                                    ),
                                  ),
                                );
                                await _fetchDevices();

                                Navigator.of(context).pop();
                              },
                              child: const Text('Guardar'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

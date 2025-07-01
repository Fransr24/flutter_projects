import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
        return 'aire';
    }
  }

  Future<void> _fetchDevices() async {
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection(collectionName)
              .where(
                'creador',
                isEqualTo: FirebaseAuth.instance.currentUser!.uid,
              )
              .get();

      final deviceNames = snapshot.docs.map((doc) => doc.id).toList();

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

    final String deviceName = _selectedDevice.split('|').first;

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
                      return DropdownMenuItem(
                        value: dev,
                        child: Text(dev.split('|').first),
                      );
                    }).toList(),
                onChanged: (newValue) {
                  if (newValue != null) {
                    setState(() {
                      _selectedDevice = newValue;
                    });
                    widget.onDevChanged(_selectedDevice);
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
                      title: Text("Eliminando modulo $deviceName"),
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
                            if (_type == DeviceType.aire) {
                              await FirebaseFirestore.instance
                                  .collection("aire")
                                  .doc(_selectedDevice)
                                  .delete();
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Modulo $deviceName eliminado"),
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
              if (_type == DeviceType.luces || _type == DeviceType.aire) {
                final collectionName =
                    _type == DeviceType.luces ? "luces" : "aire";
                final defaultData =
                    _type == DeviceType.luces
                        ? {
                          'encendido': false,
                          'horario': "--:--",
                          'temporizador': "00",
                          'creador': FirebaseAuth.instance.currentUser!.uid,
                        }
                        : {
                          'encendido': false,
                          'swing': false,
                          'temperatura': "00",
                          'fan': "-",
                          'mode': "-",
                          'temporizador': "00",
                          'creador': FirebaseAuth.instance.currentUser!.uid,
                        };

                await showDialog(
                  context: context,
                  builder: (context) {
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return AlertDialog(
                          title: Text(
                            _type == DeviceType.luces
                                ? 'Agregar nuevo modulo de luces'
                                : 'Agregar nuevo modulo de aire acondicionado',
                          ),
                          content: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              TextField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(
                                  labelText: 'Inserte el nombre del modulo',
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
                                final String docName =
                                    "${controller.text}|${FirebaseAuth.instance.currentUser!.uid}";
                                try {
                                  final docRef = FirebaseFirestore.instance
                                      .collection(collectionName)
                                      .doc(docName);

                                  final docSnapshot = await docRef.get();

                                  if (docSnapshot.exists) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "El módulo ya existe con ese nombre.",
                                        ),
                                      ),
                                    );
                                  } else {
                                    await docRef.set(defaultData);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          "Módulo ${controller.text} agregado",
                                        ),
                                      ),
                                    );
                                    await _fetchDevices();
                                    Navigator.of(context).pop();
                                  }
                                } catch (error) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error al crear modulo"),
                                    ),
                                  );
                                }
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

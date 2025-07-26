import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_home_app/core/providers.dart';

enum DeviceType { luces, aire }

class DeviceAppBar extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
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
  ConsumerState<DeviceAppBar> createState() => _DeviceAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _DeviceAppBarState extends ConsumerState<DeviceAppBar> {
  late String _selectedDevice = "";
  late DeviceType _type;
  late List<String> _availableDevices = [];
  late String collectionName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _type = widget.type;
      collectionName = _getCollectionName(widget.type);
      _fetchDevices();
    });
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
    final redId = ref.watch(redIdProvider);
    try {
      final snapshot =
          await FirebaseFirestore.instance
              .collection(collectionName)
              .where('red', isEqualTo: redId)
              .get();

      final deviceIds = snapshot.docs.map((doc) => doc.id).toList();

      setState(() {
        _availableDevices = deviceIds;
        _selectedDevice =
            deviceIds.isNotEmpty ? deviceIds.first : 'Sin dispositivos';
      });

      widget.onDevChanged(_selectedDevice);
    } catch (e) {
      showAlertDialog(
        context: context,
        title: "Error",
        message: "Error actualizando dispositivo",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextEditingController controllerId = TextEditingController();
    final TextEditingController controllerName = TextEditingController();
    final TextEditingController controllerDescription = TextEditingController();

    final redId = ref.watch(redIdProvider);

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
                                controller: controllerId,
                                decoration: const InputDecoration(
                                  labelText: 'Inserte el Id del modulo',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              TextField(
                                controller: controllerName,
                                decoration: const InputDecoration(
                                  labelText: 'Inserte el nombre del modulo',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              TextField(
                                controller: controllerDescription,
                                decoration: const InputDecoration(
                                  labelText:
                                      'Inserte una descripcion del modulo',
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
                                final name = controllerName.text;
                                final id = controllerId.text;
                                final description = controllerDescription.text;

                                final collectionName =
                                    _type == DeviceType.luces
                                        ? "luces"
                                        : "aire";
                                final defaultData =
                                    _type == DeviceType.luces
                                        ? {
                                          'red': redId,
                                          'emparejado': true,
                                          'nombre': name,
                                          'descripcion': description,
                                          'encendido': false,
                                          'horario': "--:--",
                                          'temporizador': "00",
                                        }
                                        : {
                                          'red': redId,
                                          'emparejado': true,
                                          'nombre': name,
                                          'descripcion': description,
                                          'encendido': false,
                                          'swing': false,
                                          'temperatura': "00",
                                          'fan': "-",
                                          'mode': "-",
                                          'temporizador': "00",
                                        };

                                try {
                                  final docRef = FirebaseFirestore.instance
                                      .collection(collectionName)
                                      .doc(id);

                                  final docSnapshot = await docRef.get();

                                  if (docSnapshot.exists) {
                                    showAlertDialog(
                                      context: context,
                                      title: "Error",
                                      message:
                                          "El módulo ya existe y se encuentra registrado",
                                    );
                                  } else {
                                    final data =
                                        await FirebaseFirestore.instance
                                            .collection(collectionName)
                                            .where('red', isEqualTo: redId)
                                            .where('nombre', isEqualTo: name)
                                            .get();
                                    if (data.docs.isNotEmpty) {
                                      showAlertDialog(
                                        context: context,
                                        title: "Error",
                                        message:
                                            "Ya existe un dispositivo con ese nombre, prueba uno distinto",
                                      );
                                    } else {
                                      await docRef.set(defaultData);

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "Módulo ${controllerName.text} agregado",
                                          ),
                                        ),
                                      );
                                      await _fetchDevices();
                                      Navigator.of(context).pop();
                                    }
                                  }
                                } catch (error) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Error al emparejar dispositivo",
                                      ),
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

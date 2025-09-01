// ignore_for_file: use_build_context_synchronously

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_home_app/core/providers.dart';
import 'package:smart_home_app/core/utils/utils.dart';
import 'package:smart_home_app/presentation/widgets/firebase_options.dart';

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
  late String _deviceName = "";
  late DeviceType _type;
  late List<Map<String, dynamic>> _availableDevices = [];
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
        return 'lights';
      case DeviceType.aire:
        return 'air';
    }
  }

  Future<void> _fetchDevices() async {
    final redId = ref.watch(redIdProvider);
    try {
      final collectionName = _getCollectionName(_type);
      final snapshot =
          await FirebaseDatabase.instance
              .ref(collectionName)
              .orderByChild("Network")
              .equalTo(redId)
              .get();

      final deviceList = <Map<String, dynamic>>[];

      for (final child in snapshot.children) {
        final data = child.value as Map<dynamic, dynamic>;
        deviceList.add({'id': child.key, 'name': data['Name']});
      }

      setState(() {
        _availableDevices = deviceList;
        _selectedDevice =
            deviceList.isNotEmpty ? deviceList.first['id'] : 'Sin dispositivos';
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

    return AppBar(
      title: Row(
        children: [
          const SizedBox(height: 12),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedDevice,
                isExpanded: true,
                items:
                    _availableDevices.map((dev) {
                      return DropdownMenuItem(
                        value: dev['id'] as String,
                        child: Text(dev['name']),
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
                      title: Text("Eliminando modulo $_deviceName"),
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
                            try {
                              if (_type == DeviceType.luces) {
                                await FirebaseDatabase.instance
                                    .ref("lights/$_selectedDevice")
                                    .remove();
                              }
                              if (_type == DeviceType.aire) {
                                await FirebaseDatabase.instance
                                    .ref("air/$_selectedDevice")
                                    .remove();
                              }
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Modulo $_deviceName eliminado",
                                  ),
                                ),
                              );
                              await _fetchDevices();

                              Navigator.of(context).pop();
                            } catch (error) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "Error eliminando módulo: $error",
                                  ),
                                ),
                              );
                            }
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
                              const SizedBox(height: 15),

                              TextField(
                                controller: controllerName,
                                decoration: const InputDecoration(
                                  labelText: 'Inserte el nombre del modulo',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 15),

                              TextField(
                                controller: controllerDescription,
                                decoration: const InputDecoration(
                                  labelText:
                                      'Inserte una descripcion del modulo',
                                  border: OutlineInputBorder(),
                                ),
                              ),
                              const SizedBox(height: 15),
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
                                        ? "lights"
                                        : "air";
                                final defaultData =
                                    _type == DeviceType.luces
                                        ? {
                                          'Network': redId,
                                          'Connected': true,
                                          'Name': name,
                                          'Description': description,
                                          'On': false,
                                          'SecondaryLight': "testidsecondlight",
                                          'TimeOff': "*",
                                          'TimeOn': "*",
                                        }
                                        : {
                                          'Network': redId,
                                          'Connected': true,
                                          'Name': name,
                                          'Description': description,
                                          'On': false,
                                          'Mode': 0,
                                          'SensorTemp': 20,
                                          'ACTemp': 24,
                                          'Speed': 1,
                                          'TempMax': 40,
                                          'TempMin': 3,
                                          'TimeOff': "*",
                                          'TimeOn': "*",
                                          'ToggleLimits': false,
                                        };

                                try {
                                  final deviceRef = FirebaseDatabase.instance
                                      .ref("$collectionName/$id");

                                  final deviceSnap = await deviceRef.get();

                                  if (deviceSnap.exists) {
                                    showAlertDialog(
                                      context: context,
                                      title: "Error",
                                      message:
                                          "El módulo ya existe y se encuentra registrado",
                                    );
                                    return;
                                  }

                                  final querySnap =
                                      await FirebaseDatabase.instance
                                          .ref(collectionName)
                                          .orderByChild("Network")
                                          .equalTo(redId)
                                          .get();

                                  bool nameExists = false;
                                  for (final child in querySnap.children) {
                                    final data =
                                        child.value as Map<dynamic, dynamic>;
                                    if (data['nombre'] == name) {
                                      nameExists = true;
                                      break;
                                    }
                                  }

                                  if (nameExists) {
                                    showAlertDialog(
                                      context: context,
                                      title: "Error",
                                      message:
                                          "Ya existe un dispositivo con ese nombre, prueba uno distinto",
                                    );
                                    return;
                                  }
                                  await deviceRef.set(defaultData);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "Módulo ${controllerName.text} agregado",
                                      ),
                                    ),
                                  );
                                  await _fetchDevices();
                                  Navigator.of(context).pop();
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

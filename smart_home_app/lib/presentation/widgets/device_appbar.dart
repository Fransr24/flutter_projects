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

class DeviceAppBar extends ConsumerStatefulWidget implements PreferredSizeWidget {
  final String selectedDevice;
  final DeviceType type;
  final void Function(String) onDevChanged;

  DeviceAppBar({super.key, required this.selectedDevice, required this.onDevChanged, required this.type});

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

      final deviceProviderValue = ref.watch(devicesProvider);
      final List<String> allDevices = (deviceProviderValue is List) ? List<String>.from(deviceProviderValue) : <String>[];

      final filteredDevices =
          allDevices.where((d) {
            if (collectionName == 'lights') {
              return d.startsWith('MLP'); // luces empiezan con MLP
            } else if (collectionName == 'air') {
              return d.startsWith('AIR'); // aire empiezan con AIR
            }
            return false;
          }).toList();

      final deviceList = <Map<String, dynamic>>[];

      // Recorremos cada device id filtrado y consultamos su nodo individual
      for (final dev in filteredDevices) {
        try {
          final snap = await FirebaseDatabase.instance.ref("$collectionName/$dev").get();
          final data = snap.value as Map<dynamic, dynamic>;

          // Me dijo si esta en connected = true
          final connectedRaw = data['Connected'];
          final bool isConnected = (connectedRaw == true) || (connectedRaw?.toString().toLowerCase() == 'true');

          if (!isConnected) {
            // Si no está marcado como conectado, lo ignoramos
            continue;
          }

          // Me llevo name
          final nameRaw = data['Name'];
          final name = nameRaw?.toString();

          deviceList.add({'id': dev, 'name': name});
        } catch (innerError) {
          await showAlertDialog(context: context, title: 'Error', message: 'Error leyendo device $dev: $innerError');
          continue;
        }
      }
      setState(() {
        _availableDevices = deviceList;
        _selectedDevice = deviceList.isNotEmpty ? deviceList.first['id'] : 'Sin dispositivos';
      });

      widget.onDevChanged(_selectedDevice);
    } catch (e) {
      showAlertDialog(context: context, title: "Error", message: "Error actualizando dispositivo: $e");
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
                      return DropdownMenuItem(value: dev['id'] as String, child: Text(dev['name']));
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
            icon: const Icon(Icons.edit),
            tooltip: 'Editar dispositivo',
            onPressed: () async {
              await showDeviceDetailDialog(context, ref, collection: collectionName, id: _selectedDevice);
              _fetchDevices();
            },
          ),
        ],
      ),
    );
  }
}

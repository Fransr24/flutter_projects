import 'package:flutter/material.dart';

class DeviceAppBar extends StatefulWidget implements PreferredSizeWidget {
  final List<String> availableDevices;
  final String selectedDevice;
  final void Function(String) onLightChanged;

  DeviceAppBar({
    super.key,
    required this.availableDevices,
    required this.selectedDevice,
    required this.onLightChanged,
  });

  @override
  State<DeviceAppBar> createState() => _DeviceAppBarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _DeviceAppBarState extends State<DeviceAppBar> {
  late String _selectedDevice;
  late List<String> _availableDevices;

  @override
  void initState() {
    super.initState();
    _selectedDevice = widget.selectedDevice;
    _availableDevices = widget.availableDevices;
  }

  @override
  Widget build(BuildContext context) {
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
                      return DropdownMenuItem(value: dev, child: Text('$dev'));
                    }).toList(),
                onChanged: (light) {
                  if (light != null) {
                    setState(() {
                      _selectedDevice = light;
                    });
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
                          onPressed: () {
                            _availableDevices.remove(_selectedDevice);
                            _selectedDevice = _availableDevices.first;
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
            tooltip: 'Agregar Dispositivo',
            onPressed: () {
              _availableDevices.add(
                'Nuevo Dispositivo ${_availableDevices.length + 1}',
              );
              _selectedDevice = _availableDevices.last;
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:smart_home_app/core/providers.dart';
import 'package:smart_home_app/core/utils/utils.dart';

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  bool _loading = true;
  String? _error;
  List<_DeviceModel> _connected = [];
  List<_DeviceModel> _disconnected = [];

  @override
  void initState() {
    super.initState();
    _loadDevices();
  }

  Future<void> _loadDevices() async {
    setState(() {
      _loading = true;
      _error = null;
      _connected = [];
      _disconnected = [];
    });

    final redId = ref.read(redIdProvider);
    final rawDevices = ref.read(devicesProvider);

    if (redId == null || rawDevices == null) {
      setState(() {
        _error = 'No hay red seleccionada o lista de dispositivos vacía.';
        _loading = false;
      });
      return;
    }

    final List<String> ids = (rawDevices is List) ? List<String>.from(rawDevices) : <String>[];

    final filtered = ids.where((id) => id != null && id.toString().trim().isNotEmpty).toList();

    try {
      // Fetch en paralelo
      final futures =
          filtered.map((id) async {
            final idStr = id.toString();
            // Dependiendo de como empieza busco en lights o air
            final collection = idStr.startsWith('MLP') ? 'lights' : (idStr.startsWith('AIR') ? 'air' : null);

            if (collection == null) {
              return _DeviceModel(id: idStr, collection: 'unknown', name: idStr, description: '', connected: false);
            }

            final snap = await FirebaseDatabase.instance.ref('$collection/$idStr').get();

            if (!snap.exists || snap.value == null) {
              return _DeviceModel(id: idStr, collection: collection, name: idStr, description: '', connected: false);
            }

            final data = snap.value as Map<dynamic, dynamic>;
            final name = (data['Name'])?.toString() ?? idStr;
            final desc = (data['Description'])?.toString() ?? '';
            final rawConnected = data['Connected'] ?? false;
            final bool connected = (rawConnected == true) || (rawConnected?.toString().toLowerCase() == 'true');

            return _DeviceModel(id: idStr, collection: collection, name: name, description: desc, connected: connected);
          }).toList();

      final results = await Future.wait(futures);

      final connectedList = results.where((d) => d.connected).toList();
      final disconnectedList = results.where((d) => !d.connected).toList();

      // ordena por nombre
      connectedList.sort((a, b) => a.name.compareTo(b.name));
      disconnectedList.sort((a, b) => a.name.compareTo(b.name));

      setState(() {
        _connected = connectedList;
        _disconnected = disconnectedList;
        _loading = false;
      });
    } catch (e, st) {
      await showAlertDialog(context: context, title: 'Error cargando dispositivos', message: 'Error cargando dispositivos: $e');
      setState(() {
        _error = 'Error cargando dispositivos: $e';
        _loading = false;
      });
    }
  }

  Future<void> _pairDevice(BuildContext context, _DeviceModel device, String censoredId) async {
    final redId = ref.read(redIdProvider);
    if (redId == null) {
      await showAlertDialog(context: context, title: 'Error', message: 'No hay red seleccionada');
      return;
    }

    final idController = TextEditingController();
    final nameController = TextEditingController();
    final descController = TextEditingController();

    final _formKey = GlobalKey<FormState>();

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 8,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          contentPadding: EdgeInsets.zero,
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor.withOpacity(0.08),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(color: Theme.of(context).primaryColor, shape: BoxShape.circle),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.device_hub, color: Colors.white, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Emparejar dispositivo',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Theme.of(context).primaryColorDark),
                        ),
                      ),
                      Text(censoredId, style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    ],
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text('Datos del módulo', style: TextStyle(fontWeight: FontWeight.w700)),
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: idController,
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'ID del dispositivo',
                              hintText: 'Ej: MLP-1234',
                              isDense: true,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresá el ID del dispositivo';
                              }
                              if (value.trim() != device.id) {
                                return 'El ID no coincide con el del dispositivo real';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: nameController,
                            textInputAction: TextInputAction.next,
                            autofocus: true,
                            decoration: const InputDecoration(
                              labelText: 'Nombre',
                              hintText: 'Ej: Luz Cocina',
                              isDense: true,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Ingresa un nombre para el dispositivo';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          TextFormField(
                            controller: descController,
                            textInputAction: TextInputAction.newline,
                            minLines: 1,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Descripción (opcional)',
                              hintText: 'Ej: Luz principal de la cocina',
                              isDense: true,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                            ),
                          ),

                          const SizedBox(height: 10),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Al emparejar, el módulo quedará asignado a tu red actual.',
                              style: TextStyle(fontSize: 12, color: Colors.black54),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                      ),
                    ),
                  ),
                ),

                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Cancelar', style: TextStyle(fontSize: 15)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 4,
                          ),
                          onPressed: () {
                            if (_formKey.currentState?.validate() ?? false) {
                              Navigator.of(context).pop(true);
                            }
                          },
                          child: const Text('Emparejar', style: TextStyle(fontSize: 15)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != true) return;

    final newName = nameController.text.trim();
    final newDesc = descController.text.trim();

    try {
      await FirebaseDatabase.instance.ref('${device.collection}/${device.id}').update({
        'Connected': true,
        'Network': redId,
        'Name': newName.isNotEmpty ? newName : device.name,
        'Description': newDesc,
      });

      if (device.collection == "air") {
        await FirebaseDatabase.instance.ref('${device.collection}/${device.id}').update({'SensorTemp': 24, 'AcTemp': 24});
      }

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Dispositivo emparejado correctamente')));
      await _loadDevices();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error emparejando dispositivo: $e')));
    }
  }

  Widget _buildDeviceTile(_DeviceModel d) {
    String _maskedId(String id) {
      final s = id.toString();
      if (s.length <= 6) {
        if (s.length <= 2) return '*' * s.length;
        return '${s.substring(0, 1)}${'*' * (s.length - 2)}${s.substring(s.length - 1)}';
      }

      const keepStart = 3;
      const keepEnd = 3;
      final middleLen = s.length - keepStart - keepEnd;

      return '${s.substring(0, keepStart)}${'*' * middleLen}${s.substring(s.length - keepEnd)}';
    }

    final String idText = d.connected ? (d.name ?? '') : _maskedId(d.id ?? '');

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 20, horizontal: 14),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: d.connected ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.06),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              d.connected ? (d.collection == 'air' ? Icons.thermostat_outlined : Icons.lightbulb_outline) : Icons.power_off_outlined,
              color: d.connected ? Colors.green.shade700 : Colors.red.shade600,
              size: 22,
            ),
          ),
        ),
        title: Text(idText, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        subtitle: Text(
          d.description.isNotEmpty ? d.description : '— Sin descripción —',
          style: const TextStyle(fontSize: 13, color: Colors.black54),
        ),

        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              backgroundColor: d.connected ? Colors.green.shade50 : Colors.red.shade50,
              label: Text(
                d.connected ? 'Conectado' : 'No emparejado',
                style: TextStyle(color: d.connected ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              d.connected ? Icons.chevron_right_rounded : Icons.add_circle_outline,
              color: d.connected ? Colors.black26 : Theme.of(context).primaryColor,
            ),
          ],
        ),

        onTap: () async {
          if (!d.connected) {
            _pairDevice(context, d, idText);
          } else {
            await showDeviceDetailDialog(context, ref, collection: d.collection, id: d.id);
            _loadDevices();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dispositivos de la red'),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadDevices, tooltip: 'Refrescar')],
      ),
      body: SafeArea(
        child:
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                : RefreshIndicator(
                  onRefresh: _loadDevices,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Conectados
                        if (_connected.isNotEmpty) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(20)),
                                child: Row(
                                  children: [
                                    Icon(Icons.check_circle, color: Colors.green.shade700, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Dispositivos conectados',
                                      style: TextStyle(fontWeight: FontWeight.w700, color: Colors.green.shade700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._connected.map((d) => _buildDeviceTile(d)).toList(),
                          const SizedBox(height: 20),
                        ],

                        // Desconectados
                        if (_disconnected.isNotEmpty) ...[
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(20)),
                                child: Row(
                                  children: [
                                    Icon(Icons.error_outline, color: Colors.red.shade700, size: 18),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Dispositivos no emparejados',
                                      style: TextStyle(fontWeight: FontWeight.w700, color: Colors.red.shade700),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ..._disconnected.map((d) => _buildDeviceTile(d)).toList(),
                          const SizedBox(height: 20),
                        ],

                        if (_connected.isEmpty && _disconnected.isEmpty) ...[
                          Center(
                            child: Column(
                              children: [
                                Icon(Icons.devices_other, size: 48, color: Colors.deepPurple.shade200),
                                const SizedBox(height: 12),
                                const Text('No se encontraron dispositivos'),
                                const SizedBox(height: 8),
                                ElevatedButton(onPressed: _loadDevices, child: const Text('Buscar nuevamente')),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
      ),
    );
  }
}

// Modelo interno
class _DeviceModel {
  final String id;
  final String collection; // 'lights' | 'air' | 'unknown'
  final String name;
  final String description;
  final bool connected;

  _DeviceModel({required this.id, required this.collection, required this.name, required this.description, required this.connected});
}

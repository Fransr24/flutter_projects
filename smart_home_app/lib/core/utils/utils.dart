import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_home_app/core/providers.dart';

Future<void> showAlertDialog({required BuildContext context, required String title, required String message}) async {
  return showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [TextButton(child: const Text('OK'), onPressed: () => Navigator.of(context).pop())],
      );
    },
  );
}

Future<void> showDeviceDetailDialog(BuildContext context, WidgetRef ref, {required String collection, required String id}) async {
  final dbRef = FirebaseDatabase.instance.ref('$collection/$id');

  DataSnapshot snap;
  try {
    snap = await dbRef.get();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error leyendo dispositivo: $e')));
    return;
  }

  if (!snap.exists || snap.value == null) {
    await showDialog(
      context: context,
      builder:
          (c) => AlertDialog(
            title: const Text('Dispositivo no encontrado'),
            content: Text('No se encontró el dispositivo $id en $collection.'),
            actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Aceptar'))],
          ),
    );
    return;
  }

  final dataRaw = snap.value;
  if (dataRaw is! Map) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Formato inválido para el dispositivo')));
    return;
  }
  final Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(dataRaw);

  // Campos y controllers
  final initialName = (data['Name'] ?? '').toString();
  final initialDesc = (data['Description'] ?? '').toString();
  final initialSecondary = (data['SecondaryLight'] ?? '').toString();

  final network = (data['Network'] ?? '').toString();
  final rawConnected = data['Connected'] ?? false;
  final connected = (rawConnected == true) || (rawConnected?.toString().toLowerCase() == 'true');

  final isLight = id.startsWith('MLP') || collection.toLowerCase() == 'lights';
  final isAir = id.startsWith('AIR') || collection.toLowerCase() == 'air';

  final mode = data['Mode'] ?? '—';
  final sensorTemp = data['SensorTemp'] ?? '--';
  final acTemp = data['AcTemp'] ?? '--';
  final speed = data['Speed'] ?? '--';
  final tempMax = data['TempMax'] ?? '--';
  final tempMin = data['TempMin'] ?? '--';
  final timeOn = data['TimeOn'] ?? '';
  final timeOff = data['TimeOff'] ?? '';
  final toggleLimits = data['ToggleLimits'] ?? false;

  final onState = data['On'] ?? false;
  final secondaryLightId = initialSecondary;

  final nameController = TextEditingController(text: initialName);
  final descController = TextEditingController(text: initialDesc);

  bool isSaving = false;
  bool isDeleting = false;

  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogCtx) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            titlePadding: const EdgeInsets.fromLTRB(16, 16, 8, 8),
            title: Row(
              children: [
                if (isLight)
                  const Icon(Icons.lightbulb_outline, color: Colors.deepPurple)
                else if (isAir)
                  const Icon(Icons.thermostat_outlined, color: Colors.deepPurple)
                else
                  const Icon(Icons.devices_other, color: Colors.deepPurple),
                const SizedBox(width: 12),
                Expanded(child: Text('$id', style: const TextStyle(fontWeight: FontWeight.w700))),
                const SizedBox(width: 8),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Chip(
                          backgroundColor: connected ? Colors.green.shade50 : Colors.red.shade50,
                          label: Text(
                            connected ? 'Conectado' : 'No emparejado',
                            style: TextStyle(color: connected ? Colors.green.shade700 : Colors.red.shade700, fontWeight: FontWeight.w700),
                          ),
                        ),
                        const SizedBox(width: 10),
                        if (network.isNotEmpty) Text('Red: $network', style: const TextStyle(color: Colors.black54)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    const Text('Nombre', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        hintText: 'Nombre',
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text('Descripción', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: descController,
                      decoration: const InputDecoration(
                        hintText: 'Descripción (opcional)',
                        isDense: true,
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),

                    const SizedBox(height: 6),
                    // Boton de eliminar
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.red.shade700),
                        foregroundColor: Colors.red.shade700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed:
                          isDeleting
                              ? null
                              : () async {
                                // Confirmación adicional
                                final confirm = await showDialog<bool>(
                                  context: dialogCtx,
                                  builder:
                                      (c) => AlertDialog(
                                        title: const Text('Confirmar eliminación'),
                                        content: Text('¿Seguro querés eliminar el dispositivo "$id"? Esta acción no se puede deshacer.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('Cancelar')),
                                          ElevatedButton(
                                            style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
                                            onPressed: () => Navigator.of(c).pop(true),
                                            child: const Text('Eliminar'),
                                          ),
                                        ],
                                      ),
                                );

                                if (confirm != true) return;

                                try {
                                  setState(() => isDeleting = true);
                                  await dbRef.update({'Connected': false, 'Name': null, 'Description': null, 'On': null});
                                  if (isLight) {
                                    await dbRef.update({'SecondaryLight': '-'});
                                  } else {
                                    await dbRef.update({'SensorTemp': null, 'AcTemp': null});
                                  }

                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Dispositivo "$id" eliminado')));

                                  Navigator.of(dialogCtx).pop();
                                } catch (e) {
                                  setState(() => isDeleting = false);
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error eliminando: $e')));
                                }
                              },
                      child:
                          isDeleting
                              ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Text('Eliminar dispositivo', style: TextStyle(fontWeight: FontWeight.w700)),
                    ),

                    const SizedBox(height: 10),
                    const Divider(),
                    const SizedBox(height: 8),

                    // Read-only info section
                    const Text('Información:', style: TextStyle(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    _roRow('Encendido', onState.toString()),
                    _roRow('Horario encendido', (timeOn ?? '').toString()),
                    _roRow('Horario apagado', (timeOff ?? '').toString()),
                    if (isLight) _roRow('SecondaryLight', secondaryLightId),
                    if (isAir) ...[
                      _roRow('Modo', mode.toString()),
                      _roRow('Temperatura ambiente (SensorTemp)', sensorTemp.toString()),
                      _roRow('Temperatura AIR (AcTemp)', acTemp.toString()),
                      _roRow('FAN (Speed)', speed.toString()),
                      _roRow('TempMax', tempMax.toString()),
                      _roRow('TempMin', tempMin.toString()),
                      _roRow('ToggleLimits', toggleLimits.toString()),
                    ],
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: (isSaving || isDeleting) ? null : () => Navigator.of(dialogCtx).pop(), child: const Text('Cerrar')),
              ElevatedButton.icon(
                icon:
                    isSaving
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.save),
                label: const Text('Guardar'),
                onPressed:
                    (isSaving || isDeleting)
                        ? null
                        : () async {
                          final newName = nameController.text.trim();
                          final newDesc = descController.text.trim();

                          setState(() => isSaving = true);

                          final Map<String, dynamic> updates = {};
                          updates['Name'] = newName;
                          updates['Description'] = newDesc;

                          try {
                            await dbRef.update(updates);
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cambios guardados')));
                            setState(() => isSaving = false);

                            Navigator.of(dialogCtx).pop();
                          } catch (e) {
                            setState(() => isSaving = false);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error guardando: $e')));
                          }
                        },
              ),
            ],
          );
        },
      );
    },
  );
}

Widget _roRow(String label, String value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6.0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 150, child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black87))),
        const SizedBox(width: 8),
        Expanded(child: Text((value.isNotEmpty ? value : '—'), style: const TextStyle(color: Colors.black54))),
      ],
    ),
  );
}

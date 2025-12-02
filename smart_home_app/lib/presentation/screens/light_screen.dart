import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_home_app/core/providers.dart';
import 'package:smart_home_app/core/utils/utils.dart';
import 'package:smart_home_app/presentation/widgets/device_appbar.dart';

class LightScreen extends ConsumerStatefulWidget {
  const LightScreen({super.key});

  @override
  ConsumerState<LightScreen> createState() => _LightScreenState();
}

class _LightScreenState extends ConsumerState<LightScreen> {
  late String selectedLight = "";
  late bool isLightOn;
  String? selectedTime;
  int? timerMinutes;
  bool isLoading = true;

  void initState() {
    super.initState();
  }

  Future<void> _fetchLight(WidgetRef ref) async {
    final already = ref.read(isFetchingDevicesProvider);
    if (already) return;
    ref.read(isFetchingDevicesProvider.notifier).state = true;
    final redId = ref.read(redIdProvider);
    final deviceProviderValue = ref.read(devicesProvider);

    final List<String> allDevices = (deviceProviderValue is List) ? List<String>.from(deviceProviderValue) : <String>[];

    final filteredDevices = allDevices.where((d) => d.toUpperCase().startsWith('MLP')).toList();

    try {
      if (mounted) setState(() => isLoading = true);

      String? foundId;
      bool foundIsOn = false;

      for (final devId in filteredDevices) {
        try {
          final snap = await FirebaseDatabase.instance.ref("lights/$devId").get();

          if (!snap.exists || snap.value == null) continue;
          final node = snap.value;
          if (node is! Map) continue;
          final Map<dynamic, dynamic> data = Map<dynamic, dynamic>.from(node);

          final connectedRaw = data['Connected'];
          final bool isConnected = (connectedRaw == true) || (connectedRaw?.toString().toLowerCase() == 'true');
          if (!isConnected) continue;

          final onRaw = data['On'];
          final bool isOn = (onRaw == true) || (onRaw?.toString().toLowerCase() == 'true');

          foundId = devId;
          foundIsOn = isOn;
          break;
        } catch (innerErr) {
          await showAlertDialog(context: context, title: 'Error', message: 'Error leyendo dispositivo $devId: $innerErr');
          continue;
        }
      }

      if (!mounted) return;
      setState(() {
        selectedLight = foundId ?? ''; // '' = sin dispositivo seleccionado
        isLightOn = foundIsOn;
        isLoading = false;
      });
      ref.read(isFetchingDevicesProvider.notifier).state = false;
    } catch (e) {
      if (mounted) {
        setState(() {
          selectedLight = '';
          isLightOn = false;
          isLoading = false;
        });
      }
      await showAlertDialog(
        context: context,
        title: 'Error',
        message: 'Error obteniendo la información de las luces desde el servidor: $e',
      );
    }
  }

  // muestra timePicker 24h y actualiza el campo en la db
  Future<void> _pickAndSetTime(String field, String label) async {
    if (selectedLight == null || selectedLight!.isEmpty) {
      await showAlertDialog(
        context: context,
        title: 'Sin dispositivo',
        message: 'No hay un dispositivo seleccionado para establecer $label.',
      );
      return;
    }

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) => MediaQuery(data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true), child: child!),
    );

    if (pickedTime == null) return;

    final formattedTime = "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";

    try {
      await FirebaseDatabase.instance.ref("lights/$selectedLight").update({field: formattedTime});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label establecido: $formattedTime')));
    } catch (e) {
      await showAlertDialog(context: context, title: 'Error', message: 'No se pudo establecer $label: $e');
    }
  }

  // Elimina el campo (TimeOn/TimeOff) de la database
  Future<void> _removeSchedule(String field, String label) async {
    if (selectedLight == null || selectedLight!.isEmpty) {
      await showAlertDialog(
        context: context,
        title: 'Sin dispositivo',
        message: 'No hay un dispositivo seleccionado para eliminar $label.',
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Eliminar $label'),
            content: Text('¿Seguro querés eliminar $label programado?'),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('No')),
              ElevatedButton(
                style: ElevatedButton.styleFrom(foregroundColor: Colors.red),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Eliminar'),
              ),
            ],
          ),
    );

    if (confirmed != true) return;

    try {
      await FirebaseDatabase.instance.ref("lights/$selectedLight/$field").remove();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label eliminado')));
    } catch (e) {
      await showAlertDialog(context: context, title: 'Error', message: 'No se pudo eliminar $label: $e');
    }
  }

  Future<String?> _showSecondarySelectionDialog() async {
    final deviceProvValue = ref.read(devicesProvider);
    final List<String> allDevices = (deviceProvValue is List) ? List<String>.from(deviceProvValue) : <String>[];

    final candidates = allDevices.where((d) => d.startsWith('MLS') && d != selectedLight).toList();

    if (candidates.isEmpty) {
      await showDialog(
        context: context,
        builder:
            (c) => AlertDialog(
              title: const Text('Sin candidatas'),
              content: const Text('No se encontraron módulos secundarios (MLS) en tus devices.'),
              actions: [ElevatedButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Aceptar'))],
            ),
      );
      return null;
    }

    Map<String, Map<String, String>> assigned = {};
    try {
      final lightsSnap = await FirebaseDatabase.instance.ref('lights').get();
      if (lightsSnap.exists && lightsSnap.value != null) {
        final raw = lightsSnap.value as Map<dynamic, dynamic>;
        raw.forEach((key, value) {
          final id = key.toString();
          if (!id.startsWith('MLP')) return;
          final node = (value is Map) ? Map<String, dynamic>.from(value) : <String, dynamic>{};
          final sec = node['SecondaryLight']?.toString() ?? '';
          final name = node['Name']?.toString() ?? id;
          if (sec.isNotEmpty) {
            assigned[sec] = {'primaryId': id, 'primaryName': name};
          }
        });
      }
    } catch (e) {
      await showAlertDialog(context: context, title: 'Error', message: 'Error leyendo lights para asignaciones: $e');
    }

    final String? pickedId = await showDialog<String>(
      context: context,
      builder: (c) {
        return AlertDialog(
          title: const Text('Seleccionar luz secundaria'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: candidates.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final id = candidates[idx];
                final assignedInfo = assigned[id];
                final bool isAssigned = assignedInfo != null;
                final assignedText =
                    isAssigned ? 'Ya asociada a ${assignedInfo!['primaryName']} (${assignedInfo['primaryId']})' : 'Disponible para asociar';
                return ListTile(
                  leading: Icon(isAssigned ? Icons.link_off : Icons.lightbulb_outline, color: isAssigned ? Colors.red : Colors.green),
                  title: Text(id, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(assignedText),
                  onTap: isAssigned ? null : () => Navigator.of(context).pop(id),
                  enabled: !isAssigned,
                );
              },
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.of(c).pop(), child: const Text('Cancelar'))],
        );
      },
    );

    return pickedId;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DeviceAppBar(
        selectedDevice: selectedLight,
        type: DeviceType.luces,
        onDevChanged: (newLight) {
          setState(() {
            selectedLight = newLight;
          });
        },
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StreamBuilder<DatabaseEvent>(
                stream:
                    (selectedLight != null && selectedLight.isNotEmpty)
                        ? FirebaseDatabase.instance.ref("lights/$selectedLight").onValue
                        : null,
                builder: (context, snapshot) {
                  if ((snapshot.connectionState == ConnectionState.waiting) ||
                      (snapshot.connectionState == ConnectionState.none) && isLoading) {
                    return const SizedBox(height: 260, child: Center(child: CircularProgressIndicator()));
                  }
                  if (!snapshot.hasData || snapshot.data!.snapshot.value == null) {
                    return Center(
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        color: Colors.deepPurple.shade50,
                        margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 22.0, horizontal: 18.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.lightbulb_outline, size: 46, color: Colors.deepPurple),
                              const SizedBox(height: 12),
                              const Text(
                                'No hay luces seleccionadas',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.deepPurple),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Seleccioná un dispositivo en la pestaña "Dispositivos" para controlarlo desde aquí.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: Colors.black54),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  OutlinedButton(
                                    onPressed: () async {
                                      try {
                                        await _fetchLight(ref);
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Busqueda finalizada")));
                                      } catch (_) {}
                                    },
                                    child: const Text('Buscar de nuevo'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  final data = snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                  final isLightOn = data['On'] ?? false;
                  final icon = isLightOn ? Icons.lightbulb : Icons.lightbulb_outline;
                  final iconColor = isLightOn ? Colors.amber.shade600 : Colors.grey.shade400;

                  final timeOn = (data['TimeOn'] ?? '').toString();
                  final timeOff = (data['TimeOff'] ?? '').toString();
                  final hasOn = timeOn.isNotEmpty && timeOn != '*';
                  final hasOff = timeOff.isNotEmpty && timeOff != '*';
                  final deviceName = (data['Name'] ?? selectedLight).toString();

                  Widget scheduleCard({
                    required IconData icon,
                    required String title,
                    required String timeValue,
                    required bool active,
                    required VoidCallback onSet,
                    required VoidCallback onRemove,
                  }) {
                    return Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: active ? Colors.deepPurple.shade50 : Colors.grey.shade100,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(icon, color: active ? Colors.deepPurple : Colors.grey.shade600),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                                      const SizedBox(height: 4),
                                      Text(
                                        active ? timeValue : '- : -',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: active ? Colors.black87 : Colors.black45,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Chip(
                                  backgroundColor: active ? Colors.green.shade50 : Colors.red.shade50,
                                  label: Text(
                                    active ? 'Programado' : 'No programado',
                                    style: TextStyle(
                                      color: active ? Colors.green.shade700 : Colors.red.shade700,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final wide = constraints.maxWidth > 420;
                                if (wide) {
                                  return Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          icon: const Icon(Icons.schedule),
                                          label: Text(active ? 'Re-Establecer' : 'Establecer'),
                                          onPressed: onSet,
                                          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      SizedBox(
                                        width: 140,
                                        child: OutlinedButton.icon(
                                          icon: const Icon(Icons.delete_outline, color: Colors.red),
                                          label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                          onPressed: active ? onRemove : null,
                                          style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red.shade100)),
                                        ),
                                      ),
                                    ],
                                  );
                                } else {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      ElevatedButton.icon(
                                        icon: const Icon(Icons.schedule),
                                        label: Text(active ? 'Re-Establecer' : 'Establecer'),
                                        onPressed: onSet,
                                        style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
                                      ),
                                      const SizedBox(height: 8),
                                      OutlinedButton.icon(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        label: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                                        onPressed: active ? onRemove : null,
                                        style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.red.shade100)),
                                      ),
                                    ],
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final secRaw = data['SecondaryLight'];
                  final String? secondaryLightId = (secRaw is String && secRaw.isNotEmpty) ? secRaw : null;
                  final bool isSecondaryPaired = secondaryLightId != null && secondaryLightId.startsWith('MLS');

                  Widget secondarySection = Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Luz secundaria', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 10),
                          if (isSecondaryPaired) ...[
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(color: Colors.green.withOpacity(0.12), shape: BoxShape.circle),
                                  child: const Center(child: Icon(Icons.device_hub, color: Colors.green)),
                                ),
                                const SizedBox(width: 12),
                                Expanded(child: Text(secondaryLightId!, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
                                TextButton(
                                  onPressed: () async {
                                    final chosen = await _showSecondarySelectionDialog();
                                    if (chosen != null) {
                                      try {
                                        await FirebaseDatabase.instance.ref("lights/$selectedLight").update({'SecondaryLight': chosen});
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(SnackBar(content: Text('Luz secundaria asociada: $chosen')));
                                      } catch (e) {
                                        await showAlertDialog(
                                          context: context,
                                          title: 'Error',
                                          message: 'No se pudo asociar la luz secundaria: $e',
                                        );
                                      }
                                    }
                                  },
                                  child: const Text('Cambiar'),
                                ),
                                const SizedBox(width: 6),
                                OutlinedButton(
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder:
                                          (c) => AlertDialog(
                                            title: const Text('Desasociar luz secundaria'),
                                            content: const Text('¿Querés desasociar la luz secundaria del módulo actual?'),
                                            actions: [
                                              TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('No')),
                                              ElevatedButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Sí')),
                                            ],
                                          ),
                                    );
                                    if (confirm == true) {
                                      try {
                                        await FirebaseDatabase.instance.ref("lights/$selectedLight").update({'SecondaryLight': '-'});
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(const SnackBar(content: Text('Luz secundaria desasociada')));
                                      } catch (e) {
                                        await showAlertDialog(context: context, title: 'Error', message: 'No se pudo desasociar: $e');
                                      }
                                    }
                                  },
                                  child: const Text('Desasociar'),
                                ),
                              ],
                            ),
                          ] else ...[
                            Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(color: Colors.grey.withOpacity(0.06), shape: BoxShape.circle),
                                  child: const Center(child: Icon(Icons.device_hub_outlined, color: Colors.grey)),
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'No hay luz secundaria asociada',
                                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.link),
                                    label: const Text('Asociar luz secundaria'),
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () async {
                                      // Abrir selector de devices
                                      final chosen = await _showSecondarySelectionDialog();
                                      if (chosen == null) {
                                        return;
                                      }
                                      // Confirmar
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder:
                                            (c) => AlertDialog(
                                              title: const Text('Confirmar asociación'),
                                              content: Text('¿Querés asociar la luz secundaria "$chosen" al módulo actual?'),
                                              actions: [
                                                TextButton(onPressed: () => Navigator.of(c).pop(false), child: const Text('No')),
                                                ElevatedButton(onPressed: () => Navigator.of(c).pop(true), child: const Text('Sí')),
                                              ],
                                            ),
                                      );
                                      if (confirm != true) return;
                                      try {
                                        await FirebaseDatabase.instance.ref("lights/$selectedLight").update({'SecondaryLight': chosen});
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(SnackBar(content: Text('Luz secundaria asociada: $chosen')));
                                      } catch (e) {
                                        await showAlertDialog(context: context, title: 'Error', message: 'No se pudo asociar: $e');
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  );

                  return Column(
                    children: [
                      const SizedBox(height: 8),
                      SizedBox(height: 140, child: Icon(icon, size: 140, color: iconColor)),
                      const SizedBox(height: 8),
                      Text(deviceName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 12),

                      // Card de encendido/apagado
                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Encender/Apagar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                              Switch(
                                value: isLightOn,
                                onChanged: (value) async {
                                  try {
                                    await FirebaseDatabase.instance.ref("lights/$selectedLight").update({'On': value});
                                  } catch (e) {
                                    await showAlertDialog(
                                      context: context,
                                      title: 'Error actualizando el estado del dispositivo',
                                      message: 'No se pudo cambiar el estado de encendido de la luz',
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Sección de horarios
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0),
                        child: Column(
                          children: [
                            scheduleCard(
                              icon: Icons.wb_sunny_outlined,
                              title: 'Horario de encendido',
                              timeValue: timeOn,
                              active: hasOn,
                              onSet: () => _pickAndSetTime('TimeOn', 'Horario de encendido'),
                              onRemove: () => _removeSchedule('TimeOn', 'Horario de encendido'),
                            ),
                            const SizedBox(height: 12),
                            scheduleCard(
                              icon: Icons.nights_stay_outlined,
                              title: 'Horario de apagado',
                              timeValue: timeOff,
                              active: hasOff,
                              onSet: () => _pickAndSetTime('TimeOff', 'Horario de apagado'),
                              onRemove: () => _removeSchedule('TimeOff', 'Horario de apagado'),
                            ),
                            secondarySection,
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

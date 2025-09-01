import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchLight(ref);
    });
  }

  Future<void> _fetchLight(WidgetRef ref) async {
    final redId = ref.watch(redIdProvider);
    try {
      final snapshot =
          await FirebaseDatabase.instance
              .ref("lights")
              .orderByChild("Network")
              .equalTo(redId)
              .get();

      if (snapshot.exists && snapshot.children.isNotEmpty) {
        final firstChild = snapshot.children.first;

        setState(() {
          selectedLight = firstChild.key!;
          final data = firstChild.value as Map<dynamic, dynamic>;
          isLightOn = data['On'] ?? false;
          isLoading = false;
        });
      } else {
        setState(() {
          selectedLight = 'Sin dispositivos';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        selectedLight = 'Error';
        isLoading = false;
      });
      await showAlertDialog(
        context: context,
        title: 'Error',
        message:
            'Error obteniendo la informacion de las luces desde el servidor',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final TextEditingController controller = TextEditingController();
    String selectedUnit = 'minutos';
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
              const SizedBox(height: 16),
              StreamBuilder<DatabaseEvent>(
                stream:
                    FirebaseDatabase.instance
                        .ref("lights/$selectedLight")
                        .onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData &&
                      snapshot.data!.snapshot.value != null) {
                    final data =
                        snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                    final isLightOn = data['On'] ?? false;

                    final icon =
                        isLightOn ? Icons.lightbulb : Icons.lightbulb_outline;
                    final iconColor =
                        isLightOn
                            ? Colors.amber.shade600
                            : Colors.grey.shade400;

                    return Column(
                      children: [
                        SizedBox(
                          height: 140,
                          child: Icon(icon, size: 140, color: iconColor),
                        ),
                        Card(
                          elevation: 3,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 16,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Encender/Apagar',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Switch(
                                  value: isLightOn,
                                  onChanged: (value) async {
                                    try {
                                      await FirebaseDatabase.instance
                                          .ref("lights/$selectedLight")
                                          .update({'On': value});
                                    } catch (e) {
                                      await showAlertDialog(
                                        context: context,
                                        title:
                                            'Error actualizando el estado del dispositivo',
                                        message:
                                            'No se pudo cambiar el estado de encendido de la luz',
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  } else {
                    return const Text("No data");
                  }
                },
              ),
              const SizedBox(height: 24),

              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Programar horario de encendido',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.schedule),
                onPressed: () async {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      selectedTime = pickedTime.format(context);
                    });
                    try {
                      await FirebaseDatabase.instance
                          .ref("lights/$selectedLight")
                          .update({'TimeOn': selectedTime});
                    } catch (e) {
                      await showAlertDialog(
                        context: context,
                        title: 'Error actualizando el estado del dispositivo',
                        message:
                            'No se pudo cambiar el estado de programacion de encendido',
                      );
                    }
                  }
                },
                label: const Text('Establecer horario'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<DatabaseEvent>(
                stream:
                    FirebaseDatabase.instance
                        .ref("lights/$selectedLight")
                        .onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData &&
                      snapshot.data!.snapshot.value != null) {
                    final data =
                        snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                    final selectedTime = data['TimeOn'] ?? false;
                    return Text(
                      selectedTime != null
                          ? 'Horario de encendido programado: ${selectedTime!} hrs'
                          : 'Horario de encendido programado: - : - hrs',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    );
                  } else {
                    return const Text(
                      "No se pudo obtener el horario programado de encendido",
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.cancel, color: Colors.red),
                label: const Text(
                  'Eliminar horario de encendido',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () async {
                  setState(() {
                    selectedTime = "*";
                  });
                  try {
                    await FirebaseDatabase.instance
                        .ref("lights/$selectedLight")
                        .update({'TimeOn': selectedTime});
                  } catch (e) {
                    await showAlertDialog(
                      context: context,
                      title: 'Error actualizando el estado del dispositivo',
                      message:
                          'No se pudo eliminar el horario de encendido del dispositivo',
                    );
                  }
                },
              ),
              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Programar horario de apagado',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.schedule),
                onPressed: () async {
                  final TimeOfDay? pickedTime = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.now(),
                  );
                  if (pickedTime != null) {
                    setState(() {
                      selectedTime = pickedTime.format(context);
                    });
                    try {
                      await FirebaseDatabase.instance
                          .ref("lights/$selectedLight")
                          .update({'TimeOff': selectedTime});
                    } catch (e) {
                      await showAlertDialog(
                        context: context,
                        title: 'Error actualizando el estado del dispositivo',
                        message:
                            'No se pudo cambiar el estado de programacion de apagado',
                      );
                    }
                  }
                },
                label: const Text('Establecer horario'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 24,
                  ),
                  textStyle: const TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              StreamBuilder<DatabaseEvent>(
                stream:
                    FirebaseDatabase.instance
                        .ref("lights/$selectedLight")
                        .onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData &&
                      snapshot.data!.snapshot.value != null) {
                    final data =
                        snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                    final selectedTime = data['TimeOff'] ?? false;
                    return Text(
                      selectedTime != null
                          ? 'Horario de apagado programado: ${selectedTime!} hrs'
                          : 'Horario de apagado programado: - : - hrs',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    );
                  } else {
                    return const Text(
                      "No se pudo obtener el horario programado de apagado",
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.cancel, color: Colors.red),
                label: const Text(
                  'Eliminar horario de apagado',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () async {
                  setState(() {
                    selectedTime = "*";
                  });
                  try {
                    await FirebaseDatabase.instance
                        .ref("lights/$selectedLight")
                        .update({'TimeOff': selectedTime});
                  } catch (e) {
                    await showAlertDialog(
                      context: context,
                      title: 'Error actualizando el estado del dispositivo',
                      message:
                          'No se pudo eliminar el horario de apagado del dispositivo',
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

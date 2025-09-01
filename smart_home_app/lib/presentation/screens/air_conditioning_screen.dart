import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:smart_home_app/core/utils/utils.dart';
import 'package:smart_home_app/presentation/widgets/device_appbar.dart';
import 'package:smart_home_app/presentation/widgets/modals/eddit_air_config_modal.dart';

class AirConditioningScreen extends StatefulWidget {
  const AirConditioningScreen({super.key});

  @override
  State<AirConditioningScreen> createState() => _AirConditioningScreenState();
}

class _AirConditioningScreenState extends State<AirConditioningScreen> {
  String selectedAirConditioning = 'air';
  bool isairConditioningOn = false;
  String? selectedTime;
  int? timerMinutes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DeviceAppBar(
        type: DeviceType.aire,
        selectedDevice: selectedAirConditioning,
        onDevChanged: (newairConditioning) {
          setState(() {
            selectedAirConditioning = newairConditioning;
          });
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              StreamBuilder<DatabaseEvent>(
                stream:
                    FirebaseDatabase.instance
                        .ref("air/$selectedAirConditioning")
                        .onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData &&
                      snapshot.data!.snapshot.value != null) {
                    final data =
                        snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                    final isOn = data['On'];
                    final sensorTemp = data['SensorTemp'];
                    final acTemp = data['ACTemp'];
                    final fan = data['Speed'];
                    final mode = data['Mode'];
                    final TimeOn = data['TimeOn'];
                    final TimeOff = data['TimeOff'];

                    final isOnText = isOn ? "Encendido" : "Apagado";
                    final isOnColor = isOn ? Colors.green : Colors.red;
                    final isOnBackgroundColor =
                        isOn ? Colors.green.shade50 : Colors.red.shade50;

                    return Column(
                      children: [
                        const SizedBox(height: 20),
                        const Text(
                          "Temperatura actual:",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "$sensorTemp °C",
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Chip(
                          label: Text(
                            isOnText,
                            style: TextStyle(color: isOnColor),
                          ),
                          backgroundColor: isOnBackgroundColor,
                          avatar: Icon(Icons.power, color: isOnColor),
                        ),
                        const SizedBox(height: 24),
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
                                  value: isOn,
                                  onChanged: (value) async {
                                    try {
                                      await FirebaseDatabase.instance
                                          .ref("air/$selectedAirConditioning")
                                          .update({'On': value});
                                    } catch (e) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Error actualizando el estado del dispositivo",
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),

                        Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      "Configuración del dispositivo:",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    IconButton(
                                      onPressed:
                                          () => {
                                            showEditAirConfigModal(
                                              context,
                                              selectedAirConditioning,
                                              acTemp,
                                              fan,
                                              mode,
                                            ),
                                          },
                                      icon: const Icon(Icons.edit),
                                      tooltip: "Editar configuración",
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 12,
                                  runSpacing: 8,
                                  children: [
                                    Chip(label: Text("T°: $acTemp °C")),
                                    Chip(label: Text("FAN: $fan")),
                                    Chip(label: Text("Mode: $mode")),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Establecer horario de encendido del aire acondicionado:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final TimeOfDay? pickedTime =
                                      await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                      );
                                  if (pickedTime != null) {
                                    setState(() {
                                      selectedTime = pickedTime.format(context);
                                    });
                                    try {
                                      await FirebaseDatabase.instance
                                          .ref("air/$selectedAirConditioning")
                                          .update({'TimeOn': selectedTime});
                                    } catch (e) {
                                      await showAlertDialog(
                                        context: context,
                                        title:
                                            'Error actualizando el estado del dispositivo',
                                        message:
                                            'No se pudo cambiar el estado de programacion de encendido',
                                      );
                                    }
                                  }
                                },

                                icon: const Icon(Icons.timer),
                                label: const Text("Seleccionar duración"),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        StreamBuilder<DatabaseEvent>(
                          stream:
                              FirebaseDatabase.instance
                                  .ref("air/$selectedAirConditioning")
                                  .onValue,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasData &&
                                snapshot.data!.snapshot.value != null) {
                              final data =
                                  snapshot.data!.snapshot.value
                                      as Map<dynamic, dynamic>;
                              final selectedTime = data['TimeOn'] ?? false;
                              return Text(
                                selectedTime != null
                                    ? 'Horario de encendido programado: ${selectedTime!} hrs'
                                    : 'Horario de encendido programado: - : - hrs',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              );
                            } else {
                              return const Text(
                                "No se pudo obtener el horario programado de encendido",
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          "Establecer horario de apagado del aire acondicionado:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () async {
                                  final TimeOfDay? pickedTime =
                                      await showTimePicker(
                                        context: context,
                                        initialTime: TimeOfDay.now(),
                                      );
                                  if (pickedTime != null) {
                                    setState(() {
                                      selectedTime = pickedTime.format(context);
                                    });
                                    try {
                                      await FirebaseDatabase.instance
                                          .ref("air/$selectedAirConditioning")
                                          .update({'TimeOff': selectedTime});
                                    } catch (e) {
                                      await showAlertDialog(
                                        context: context,
                                        title:
                                            'Error actualizando el estado del dispositivo',
                                        message:
                                            'No se pudo cambiar el estado de programacion de apagado',
                                      );
                                    }
                                  }
                                },

                                icon: const Icon(Icons.timer),
                                label: const Text("Seleccionar duración"),
                                style: OutlinedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        StreamBuilder<DatabaseEvent>(
                          stream:
                              FirebaseDatabase.instance
                                  .ref("air/$selectedAirConditioning")
                                  .onValue,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                            if (snapshot.hasData &&
                                snapshot.data!.snapshot.value != null) {
                              final data =
                                  snapshot.data!.snapshot.value
                                      as Map<dynamic, dynamic>;
                              final selectedTime = data['TimeOff'] ?? false;
                              return Text(
                                selectedTime != null
                                    ? 'Horario de apagado programado: ${selectedTime!} hrs'
                                    : 'Horario de apagado programado: - : - hrs',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey,
                                ),
                              );
                            } else {
                              return const Text(
                                "No se pudo obtener el horario programado de apagado",
                              );
                            }
                          },
                        ),
                      ],
                    );
                  } else {
                    return const Text(
                      "No Se encontraron datos del aire acondicionado en el servidor",
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

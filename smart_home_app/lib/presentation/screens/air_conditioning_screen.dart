import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:smart_home_app/presentation/widgets/device_appbar.dart';
import 'package:smart_home_app/presentation/widgets/modals/eddit_air_config_modal.dart';

class AirConditioningScreen extends StatefulWidget {
  const AirConditioningScreen({super.key});

  @override
  State<AirConditioningScreen> createState() => _AirConditioningScreenState();
}

class _AirConditioningScreenState extends State<AirConditioningScreen> {
  String selectedAirConditioning = 'aire';
  bool isairConditioningOn = false;
  TimeOfDay? selectedTime;
  int? timerMinutes;
  final TextEditingController temperatureController = TextEditingController();

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
              StreamBuilder(
                stream:
                    FirebaseFirestore.instance
                        .collection("aire")
                        .doc(selectedAirConditioning)
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData && snapshot.data!.exists) {
                    final data = snapshot.data!.data()!;
                    final isOn = data['encendido'];
                    final temperature = data['temperatura'];
                    final fan = data['fan'];
                    final mode = data['mode'];
                    final timer = data['temporizador'];
                    final swing = data['swing'];

                    final isOnText = isOn ? "Encendido" : "Apagado";
                    final isOnColor = isOn ? Colors.green : Colors.red;
                    final isOnBackgroundColor =
                        isOn ? Colors.green.shade50 : Colors.red.shade50;
                    temperatureController.text = temperature;

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
                          "$temperature °C",
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
                                      await FirebaseFirestore.instance
                                          .collection('aire')
                                          .doc(selectedAirConditioning)
                                          .update({'encendido': value});
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
                                    const Spacer(),
                                    IconButton(
                                      onPressed:
                                          () => showEditAirConfigModal(
                                            context,
                                            selectedAirConditioning,
                                            temperature,
                                            fan,
                                            swing,
                                            mode,
                                          ),
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
                                    Chip(label: Text("T°: $temperature °C")),
                                    Chip(label: Text("FAN: $fan")),
                                    Chip(
                                      label: Text(
                                        "Swing: ${swing ? "ON" : "OFF"}",
                                      ),
                                    ),
                                    Chip(label: Text("Mode: $mode")),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: ElevatedButton.icon(
                                onPressed: () async {
                                  try {
                                    await FirebaseFirestore.instance
                                        .collection('aire')
                                        .doc(selectedAirConditioning)
                                        .update({
                                          'temperatura':
                                              temperatureController.text,
                                        });
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Error seteando temperatura",
                                        ),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.thermostat),
                                label: const Text("Establecer temperatura"),
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size.fromHeight(50),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: temperatureController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  hintText: "°C",
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Esta configuracion te permite mantener el aire acondicionado encendido hasta que el ambiente alcance cierta temperatura",
                          style: const TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          "Prender aire acondicionado durante:",
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
                                  final tiempo = await showDialog<String>(
                                    context: context,
                                    builder: (context) {
                                      final TextEditingController controller =
                                          TextEditingController();
                                      String selectedUnit = "minutos";

                                      return AlertDialog(
                                        title: const Text("Temporizador"),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            TextField(
                                              controller: controller,
                                              keyboardType:
                                                  TextInputType.number,
                                              decoration: const InputDecoration(
                                                labelText: "Cantidad",
                                                border: OutlineInputBorder(),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            DropdownButton<String>(
                                              value: selectedUnit,
                                              items:
                                                  ['segundos', 'minutos']
                                                      .map(
                                                        (unit) =>
                                                            DropdownMenuItem(
                                                              value: unit,
                                                              child: Text(unit),
                                                            ),
                                                      )
                                                      .toList(),
                                              onChanged: (value) {
                                                if (value != null) {
                                                  selectedUnit = value;
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed:
                                                () =>
                                                    Navigator.of(context).pop(),
                                            child: const Text("Cancelar"),
                                          ),
                                          ElevatedButton(
                                            onPressed: () {
                                              final tiempoIngresado =
                                                  controller.text;
                                              if (tiempoIngresado.isNotEmpty) {
                                                Navigator.of(context).pop(
                                                  '$tiempoIngresado $selectedUnit',
                                                );
                                              }
                                            },
                                            child: const Text("Guardar"),
                                          ),
                                        ],
                                      );
                                    },
                                  );

                                  if (tiempo != null) {
                                    try {
                                      await FirebaseFirestore.instance
                                          .collection('aire')
                                          .doc(selectedAirConditioning)
                                          .update({'temporizador': tiempo});
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
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            "Temporizador activado por: $timer",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontStyle: FontStyle.italic,
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
            ],
          ),
        ),
      ),
    );
  }
}

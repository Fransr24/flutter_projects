import 'package:flutter/material.dart';
import 'package:smart_home_app/presentation/widgets/device_appbar.dart';
import 'package:smart_home_app/presentation/widgets/modals/eddit_air_config_modal.dart';

class AirConditioningScreen extends StatefulWidget {
  const AirConditioningScreen({super.key});

  @override
  State<AirConditioningScreen> createState() => _AirConditioningScreenState();
}

class _AirConditioningScreenState extends State<AirConditioningScreen> {
  final List<String> airConditionings = [
    'Aire Living',
    'Aire Pasillo',
    'Aire Dormitorio',
  ];
  String selectedairConditioning = 'Aire Living';
  bool isairConditioningOn = false;
  TimeOfDay? selectedTime;
  int? timerMinutes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: DeviceAppBar(
        type: DeviceType.aire,
        selectedDevice: selectedairConditioning,
        onDevChanged: (newairConditioning) {
          setState(() {
            selectedairConditioning = newairConditioning;
          });
        },
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              const Text(
                "Temperatura actual:",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              Text(
                "25°C",
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              const SizedBox(height: 8),
              Chip(
                label: Text(
                  "Encendido",
                  style: const TextStyle(color: Colors.green),
                ),
                backgroundColor: Colors.green.shade50,
                avatar: const Icon(Icons.power, color: Colors.green),
              ),
              const SizedBox(height: 24),
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
                            onPressed: () => showEditAirConfigModal(context),
                            icon: const Icon(Icons.edit),
                            tooltip: "Editar configuración",
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Wrap(
                        spacing: 12,
                        runSpacing: 8,
                        children: [
                          Chip(label: Text("24°C")),
                          Chip(label: Text("FAN: III")),
                          Chip(label: Text("Swing: ON")),
                          Chip(label: Text("Mode: Frío")),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () {
                  // Seleccionar temperatura
                },
                icon: const Icon(Icons.thermostat),
                label: const Text("Establecer temperatura a: 20°C"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        // Apagar
                      },
                      child: const Text("Apagar dispositivo"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Encender
                      },
                      child: const Text("Encender dispositivo"),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text(
                "Prender aire durante:",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                onPressed: () {
                  // Temporizador
                },
                icon: const Icon(Icons.timer),
                label: const Text("5 min"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

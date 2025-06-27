import 'package:flutter/material.dart';
import 'package:smart_home_app/presentation/widgets/device_appbar.dart';

class LightScreen extends StatefulWidget {
  const LightScreen({super.key});

  @override
  State<LightScreen> createState() => _LightScreenState();
}

class _LightScreenState extends State<LightScreen> {
  final List<String> lights = [
    'Luces Living',
    'Luces Cocina',
    'Luces Dormitorio',
  ];
  String selectedLight = 'Luces Living';
  bool isLightOn = false;
  TimeOfDay? selectedTime;
  int? timerMinutes;

  @override
  Widget build(BuildContext context) {
    final icon = isLightOn ? Icons.lightbulb : Icons.lightbulb_outline;
    final iconColor = isLightOn ? Colors.yellow.shade600 : Colors.grey.shade700;

    return Scaffold(
      appBar: DeviceAppBar(
        availableDevices: lights,
        selectedDevice: selectedLight,
        onLightChanged: (newLight) {
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

              // 💡 Ícono de luz
              Icon(
                icon,
                size: 140,
                color: isLightOn ? Colors.amber.shade600 : Colors.grey.shade400,
              ),

              const SizedBox(height: 24),

              // 🟢 Encendido / Apagado
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
                        activeColor: Colors.amber,
                        onChanged: (value) {
                          setState(() {
                            isLightOn = value;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // 🕒 Horario programado
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Encendido programado',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.schedule),
                onPressed: () {
                  // TODO: lógica de selección de hora
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
              Text(
                selectedTime != null
                    ? 'Horario programado: ${selectedTime!.format(context)}'
                    : 'Horario programado: - : - hrs',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 32),

              // ⏳ Temporizador
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Temporizador de apagado',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                icon: const Icon(Icons.timer_outlined),
                onPressed: () {
                  // TODO: lógica de temporizador
                },
                label: const Text('Establecer temporizador'),
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
              Text(
                timerMinutes != null ? '$timerMinutes min' : '- min',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

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
                stream: FirebaseDatabase.instance.ref("air/$selectedAirConditioning").onValue,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const SizedBox(height: 260, child: Center(child: CircularProgressIndicator()));
                  }

                  final rawValue = snapshot.hasData ? snapshot.data!.snapshot.value : null;
                  final Map<dynamic, dynamic> data = (rawValue is Map) ? Map<dynamic, dynamic>.from(rawValue) : <dynamic, dynamic>{};

                  // Valores por defecto
                  final dynamic rawIsOn = data['On'];
                  final bool isOn = (rawIsOn == true) || (rawIsOn?.toString().toLowerCase() == 'true');

                  final sensorTempText = (data['SensorTemp'] ?? '--').toString();

                  final acTempText = (data['ACTemp'] ?? '--').toString();
                  final String fan = data['Speed']?.toString() ?? '-';
                  final String mode = data['Mode']?.toString() ?? '-';
                  final String timeOn = data['TimeOn']?.toString() ?? '';
                  final String timeOff = data['TimeOff']?.toString() ?? '';
                  final String isOnText = isOn ? 'Encendido' : 'Apagado';
                  final Color isOnColor = isOn ? Colors.green : Colors.red;
                  final Color isOnBackgroundColor = isOn ? Colors.green.shade50 : Colors.red.shade50;

                  // lista de modos, el índice coincide con el valor del campo Mode
                  final modeList = ["Frío", "Calor", "Auto"];

                  // convertimos el valor de mode (que viene como string o número) al texto
                  int modeIndex = int.tryParse(mode.toString()) ?? 0;
                  if (modeIndex < 0 || modeIndex >= modeList.length) modeIndex = 0;
                  final modeText = modeList[modeIndex];

                  final noData = data.isEmpty;
                  if (noData) {
                    return Center(
                      child: Card(
                        elevation: 6,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 28.0, horizontal: 20.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.air_outlined, size: 70, color: Colors.blue.shade400),
                              const SizedBox(height: 16),
                              const Text(
                                "Sin módulos de aire conectados",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "No se encontraron lecturas del aire acondicionado.\nVerificá que el dispositivo esté encendido y que pertenezca a la red.",
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 14, color: Colors.black54, height: 1.4),
                              ),
                              const SizedBox(height: 18),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      try {
                                        await FirebaseDatabase.instance.ref("air/$selectedAirConditioning").get();
                                        setState(() {});
                                      } catch (_) {}
                                    },
                                    icon: const Icon(Icons.refresh),
                                    label: const Text("Reintentar"),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }

                  // Si llegamos acá hay datos
                  return Column(
                    children: [
                      const SizedBox(height: 20),
                      const Text("Temperatura actual:", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Text(
                        "$sensorTempText °C",
                        style: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Theme.of(context).primaryColor),
                      ),
                      const SizedBox(height: 8),
                      Chip(
                        label: Text(isOnText, style: TextStyle(color: isOnColor)),
                        backgroundColor: isOnBackgroundColor,
                        avatar: Icon(Icons.power, color: isOnColor),
                      ),
                      const SizedBox(height: 24),

                      Card(
                        elevation: 3,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Encender/Apagar', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500)),
                              Switch.adaptive(
                                value: isOn,
                                onChanged: (value) async {
                                  try {
                                    await FirebaseDatabase.instance.ref("air/$selectedAirConditioning").update({'On': value});
                                  } catch (e) {
                                    ScaffoldMessenger.of(
                                      context,
                                    ).showSnackBar(const SnackBar(content: Text('Error actualizando el estado del dispositivo')));
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Config card
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text("Configuración del dispositivo:", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                                  IconButton(
                                    onPressed: () {
                                      try {
                                        final String acTempStr = acTempText?.toString() ?? '';
                                        final String fanStr = fan?.toString() ?? '';
                                        final String modeStr = mode?.toString() ?? '';

                                        final int acTempVal = int.tryParse(acTempStr) ?? 24; // temperatura objetivo por defecto
                                        final int fanVal = int.tryParse(fanStr) ?? 1; // velocidad por defecto
                                        final int modeVal = int.tryParse(modeStr) ?? 0; // modo por defecto

                                        showEditAirConfigModal(context, selectedAirConditioning, acTempVal, fanVal, modeVal);
                                      } catch (e) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(SnackBar(content: Text('Error abriendo configuración: $e')));
                                      }
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
                                  Chip(label: Text("T°: $acTempText °C")),
                                  Chip(label: Text("FAN: $fan")),
                                  Chip(label: Text("Modo: $modeText")),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                "Esta configuracion sirve para que recuerdes como tenias configurado el aire acondicionado al momento de guardarlo. No sirve para configurarlo directamente. Para eso vuelva a configurar el aire acondicionado",
                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w200),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Horario On
                      const Text(
                        "Establecer horario de encendido del aire acondicionado:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                if (pickedTime != null) {
                                  final formatted =
                                      "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
                                  try {
                                    await FirebaseDatabase.instance.ref("air/$selectedAirConditioning").update({'TimeOn': formatted});
                                  } catch (e) {
                                    await showAlertDialog(
                                      context: context,
                                      title: 'Error actualizando el estado del dispositivo',
                                      message: 'No se pudo cambiar el estado de programación de encendido',
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.timer),
                              label: const Text("Seleccionar hora"),
                              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timeOn.isNotEmpty ? 'Horario de encendido programado: $timeOn hrs' : 'Horario de encendido programado: - : - hrs',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),

                      const SizedBox(height: 16),

                      // Horario Off
                      const Text(
                        "Establecer horario de apagado del aire acondicionado:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.now());
                                if (pickedTime != null) {
                                  final formatted =
                                      "${pickedTime.hour.toString().padLeft(2, '0')}:${pickedTime.minute.toString().padLeft(2, '0')}";
                                  try {
                                    await FirebaseDatabase.instance.ref("air/$selectedAirConditioning").update({'TimeOff': formatted});
                                  } catch (e) {
                                    await showAlertDialog(
                                      context: context,
                                      title: 'Error actualizando el estado del dispositivo',
                                      message: 'No se pudo cambiar el estado de programación de apagado',
                                    );
                                  }
                                }
                              },
                              icon: const Icon(Icons.timer),
                              label: const Text("Seleccionar hora"),
                              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        timeOff.isNotEmpty ? 'Horario de apagado programado: $timeOff hrs' : 'Horario de apagado programado: - : - hrs',
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),

                      const SizedBox(height: 16),
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

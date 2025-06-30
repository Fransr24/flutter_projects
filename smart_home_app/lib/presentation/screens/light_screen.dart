import 'package:cloud_firestore/cloud_firestore.dart';
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
  String? selectedTime;
  int? timerMinutes;

  @override
  Widget build(BuildContext context) {
    final icon = isLightOn ? Icons.lightbulb : Icons.lightbulb_outline;
    final iconColor = isLightOn ? Colors.yellow.shade600 : Colors.grey.shade700;
    final TextEditingController controller = TextEditingController();
    String selectedUnit = 'minutos';

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
              StreamBuilder(
                stream:
                    FirebaseFirestore.instance
                        .collection("luces")
                        .doc('luz-living')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData) {
                    isLightOn = snapshot.data!['encendido'];
                    return SizedBox(
                      height: 140,
                      child: Icon(icon, size: 140, color: iconColor),
                    );
                  } else {
                    return const Text("No data");
                  }
                },
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
                        value: isLightOn,
                        onChanged: (value) async {
                          setState(() {
                            isLightOn = value;
                          });
                          try {
                            await FirebaseFirestore.instance
                                .collection('luces')
                                .doc('luz-living')
                                .update({'encendido': value});
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text("Error actualizando dispositivo"),
                              ),
                            );
                            setState(() {
                              isLightOn = !value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Programar apagado',
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
                      await FirebaseFirestore.instance
                          .collection('luces')
                          .doc('luz-living')
                          .update({'horario': selectedTime});
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Error actualizando dispositivo"),
                        ),
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
              StreamBuilder(
                stream:
                    FirebaseFirestore.instance
                        .collection("luces")
                        .doc('luz-living')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData) {
                    selectedTime = snapshot.data!['horario'];
                    return Text(
                      selectedTime != null
                          ? 'Horario programado: ${selectedTime!}'
                          : 'Horario programado: - : - hrs',
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    );
                  } else {
                    return const Text("No data");
                  }
                },
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                icon: const Icon(Icons.cancel, color: Colors.red),
                label: const Text(
                  'Eliminar horario',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () async {
                  setState(() {
                    selectedTime = null;
                  });
                  try {
                    await FirebaseFirestore.instance
                        .collection('luces')
                        .doc('luz-living')
                        .update({'horario': "--:--"});
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Error eliminando horario")),
                    );
                  }
                },
              ),
              const SizedBox(height: 32),
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
                onPressed: () async {
                  await showDialog(
                    context: context,
                    builder: (context) {
                      return StatefulBuilder(
                        builder: (context, setState) {
                          return AlertDialog(
                            title: const Text('Establecer temporizador'),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                TextField(
                                  controller: controller,
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Tiempo',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                DropdownButton<String>(
                                  value: selectedUnit,
                                  items:
                                      ['segundos', 'minutos']
                                          .map(
                                            (unit) => DropdownMenuItem(
                                              value: unit,
                                              child: Text(unit),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (value) {
                                    if (value != null) {
                                      setState(() {
                                        selectedUnit = value;
                                      });
                                    }
                                  },
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancelar'),
                              ),
                              ElevatedButton(
                                onPressed: () async {
                                  final int? value = int.tryParse(
                                    controller.text,
                                  );
                                  if (value != null) {
                                    final String tiempoTemp =
                                        controller.text +
                                        " ".toString() +
                                        selectedUnit;
                                    // Guardá el valor en Firestore o usalo como quieras
                                    await FirebaseFirestore.instance
                                        .collection('luces')
                                        .doc('luz-living')
                                        .update({'temporizador': tiempoTemp});

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          "Temporizador actualizado",
                                        ),
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                  }
                                },
                                child: const Text('Guardar'),
                              ),
                            ],
                          );
                        },
                      );
                    },
                  );
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
              StreamBuilder(
                stream:
                    FirebaseFirestore.instance
                        .collection("luces")
                        .doc('luz-living')
                        .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasData) {
                    final temp = snapshot.data!['temporizador'];
                    return Text(
                      temp,
                      style: const TextStyle(fontSize: 16, color: Colors.grey),
                    );
                  } else {
                    return const Text("No data");
                  }
                },
              ),

              const SizedBox(height: 12),

              TextButton.icon(
                icon: const Icon(Icons.cancel, color: Colors.red),
                label: const Text(
                  'Eliminar temporizador',
                  style: TextStyle(color: Colors.red),
                ),
                onPressed: () async {
                  setState(() {
                    selectedTime = null;
                  });
                  try {
                    await FirebaseFirestore.instance
                        .collection('luces')
                        .doc('luz-living')
                        .update({'temporizador': "00"});
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Error eliminando temporizador"),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

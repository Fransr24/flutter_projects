import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_home_app/core/providers.dart';
import 'package:smart_home_app/core/utils/utils.dart';
import 'package:smart_home_app/domain/models/device_button.dart';
import 'package:smart_home_app/presentation/widgets/drawer_menu.dart';
import 'package:firebase_database/firebase_database.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  Future<void> _initialize() async {
    await _checkAndAskForDisplayName();

    bool connected = false;
    while (!connected) {
      connected = await findAndSaveRouterId(context, ref);
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _checkAndAskForDisplayName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && (user.displayName == null || user.displayName!.isEmpty)) {
      final name = await _askForDisplayName(context);
      if (name != null && name.isNotEmpty) {
        await user.updateDisplayName(name);
        await user.reload();
        setState(() {});
      }
    }
  }

  Future<String?> _askForDisplayName(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Indicar nombre de usuario'),
          content: TextField(controller: controller, decoration: const InputDecoration(labelText: 'Nombre')),
          actions: [ElevatedButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Aceptar'))],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scafoldKey = GlobalKey<ScaffoldState>();
    final user = FirebaseAuth.instance.currentUser;

    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    try {
      final _ = FirebaseAuth.instance.currentUser!.uid;
    } catch (error) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: Text("Bienvenido ${user?.displayName ?? 'Usuario'}")),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Builder(
                  builder: (context) {
                    final deviceProvValue = ref.watch(devicesProvider);
                    final List<String> allDevices = List<String>.from(deviceProvValue);

                    // candidatas de aire
                    final airCandidates =
                        allDevices.where((d) {
                          final up = d.toUpperCase();
                          return up.startsWith('AC') || up.startsWith('AIR');
                        }).toList();

                    // función local para encontrar el primer device de aire con Connected == true
                    Future<String?> _firstConnectedAirId() async {
                      for (final id in airCandidates) {
                        try {
                          final snap = await FirebaseDatabase.instance.ref("air/$id").get();
                          if (!snap.exists || snap.value == null) continue;
                          final data = snap.value as Map<dynamic, dynamic>;
                          final raw = data['Connected'];
                          final bool connected = (raw == true) || (raw?.toString().toLowerCase() == 'true');
                          if (connected) return id;
                        } catch (_) {
                          continue;
                        }
                      }
                      return null;
                    }

                    if (airCandidates.isEmpty) {
                      // No hay devices de aire en el provider
                      return Center(
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          color: Colors.deepPurple.shade50,
                          margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.air_outlined, size: 50, color: Colors.deepPurple),
                                SizedBox(height: 16),
                                Text(
                                  "No hay módulos de aire configurados",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.deepPurple),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Agrega un nuevo dispositivo para ver la temperatura actual",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    return FutureBuilder<String?>(
                      future: _firstConnectedAirId(),
                      builder: (context, futureSnap) {
                        if (futureSnap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        final firstAirId = futureSnap.data;
                        if (firstAirId == null || firstAirId.isEmpty) {
                          // ninguno conectado
                          return Center(
                            child: Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              color: Colors.deepPurple.shade50,
                              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.air_outlined, size: 50, color: Colors.deepPurple),
                                    SizedBox(height: 16),
                                    Text(
                                      "No hay módulos de aire conectados",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.deepPurple),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Asegurate de que al menos un módulo AC esté emparejado y conectado.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        return StreamBuilder<DatabaseEvent>(
                          stream: FirebaseDatabase.instance.ref("air/$firstAirId").onValue,
                          builder: (context, snap) {
                            if (snap.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (!snap.hasData || snap.data!.snapshot.value == null) {
                              return Center(
                                child: Card(
                                  elevation: 6,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                  color: Colors.deepPurple.shade50,
                                  margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                                  child: Padding(
                                    padding: const EdgeInsets.all(18.0),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: const [
                                        Icon(Icons.air_outlined, size: 50, color: Colors.deepPurple),
                                        SizedBox(height: 16),
                                        Text(
                                          "No hay lecturas del módulo de aire",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.deepPurple),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          "Verifica que el dispositivo esté encendido y conectado a la red.",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 14, color: Colors.black54),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }

                            final data = snap.data!.snapshot.value as Map<dynamic, dynamic>;
                            final sensorTemp = data['SensorTemp'];
                            final deviceName = data['Name']?.toString() ?? 'Dispositivo';

                            final tempNum = (sensorTemp == null) ? null : double.tryParse(sensorTemp.toString());
                            final tempText = tempNum != null ? tempNum.toStringAsFixed(0) : "--";

                            Color tempColor;
                            if (tempNum == null) {
                              tempColor = Colors.deepPurple;
                            } else if (tempNum <= 16) {
                              tempColor = Colors.blueAccent;
                            } else if (tempNum <= 24) {
                              tempColor = Colors.deepPurple;
                            } else {
                              tempColor = Colors.redAccent;
                            }

                            return Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                              child: Card(
                                elevation: 4,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                color: Colors.white,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 14.0),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(shape: BoxShape.circle, color: tempColor.withOpacity(0.12)),
                                        child: Icon(Icons.thermostat_outlined, size: 28, color: tempColor),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Temperatura actual",
                                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black87),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              crossAxisAlignment: CrossAxisAlignment.end,
                                              children: [
                                                AnimatedSwitcher(
                                                  duration: const Duration(milliseconds: 360),
                                                  child: Text(
                                                    tempText,
                                                    key: ValueKey(tempText),
                                                    style: TextStyle(
                                                      fontSize: 44,
                                                      fontWeight: FontWeight.w800,
                                                      color: tempColor,
                                                      height: 1,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Padding(
                                                  padding: const EdgeInsets.only(bottom: 6.0),
                                                  child: Text(
                                                    "°C",
                                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black54),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              tempNum != null
                                                  ? (tempNum <= 16
                                                      ? "Hace frío — considera subir la temperatura"
                                                      : (tempNum < 30
                                                          ? "Temperatura agradable"
                                                          : "Hace calor — Considera prender el aire acondicionado"))
                                                  : "Sensor sin lecturas válidas",
                                              style: const TextStyle(fontSize: 12, color: Colors.black54),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(deviceName, style: TextStyle(fontSize: 12, color: Colors.black54)),
                                          const SizedBox(height: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: tempColor.withOpacity(0.12),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              tempNum != null ? ((12 <= tempNum && tempNum < 30) ? "Normal" : "Alerta") : "—",
                                              style: TextStyle(fontSize: 12, color: tempColor, fontWeight: FontWeight.w700),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                child: Builder(
                  builder: (context) {
                    final deviceProvValue = ref.watch(devicesProvider);
                    final List<String> allDevices = List<String>.from(deviceProvValue);

                    final deviceIdsForLights =
                        allDevices.where((d) {
                          final up = d.toUpperCase();
                          return up.startsWith('MLP') || up.startsWith('MLS');
                        }).toList();

                    if (deviceIdsForLights.isEmpty) {
                      // No hay devices en el provider para lights
                      return Center(
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                          color: Colors.deepPurple.shade50,
                          margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 1),
                          child: Padding(
                            padding: const EdgeInsets.all(18.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(Icons.lightbulb_outline, size: 50, color: Colors.deepPurple),
                                SizedBox(height: 16),
                                Text(
                                  "No hay luces registradas",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.deepPurple),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  "Agrega una nueva luz para controlarla desde esta red",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 14, color: Colors.black54),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }

                    Future<List<String>> _findConnectedLights() async {
                      final List<String> connected = [];
                      for (final id in deviceIdsForLights) {
                        try {
                          final snap = await FirebaseDatabase.instance.ref("lights/$id").get();
                          if (!snap.exists || snap.value == null) continue;
                          final data = snap.value as Map<dynamic, dynamic>;
                          final rawConnected = data['Connected'];
                          final bool isConnected = (rawConnected == true) || (rawConnected?.toString().toLowerCase() == 'true');
                          if (isConnected) connected.add(id);
                        } catch (e) {
                          await showAlertDialog(context: context, title: 'Error', message: 'Error checkeando campos para $id: $e');
                        }
                      }
                      return connected;
                    }

                    return FutureBuilder<List<String>>(
                      future: _findConnectedLights(),
                      builder: (context, futureSnap) {
                        if (futureSnap.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (futureSnap.hasError) {
                          return Center(child: Text('Error leyendo luces: ${futureSnap.error}'));
                        }

                        final connectedIds = futureSnap.data ?? <String>[];

                        if (connectedIds.isEmpty) {
                          // No hay luces conectadas
                          return Center(
                            child: Card(
                              elevation: 6,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                              color: Colors.deepPurple.shade50,
                              margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 1),
                              child: Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.lightbulb_outline, size: 50, color: Colors.deepPurple),
                                    SizedBox(height: 16),
                                    Text(
                                      "No hay luces conectadas",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.deepPurple),
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      "Asegúrate de emparejar y conectar al menos una luz en la red.",
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 14, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }

                        return SizedBox(
                          height: 96,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                                child: ConstrainedBox(
                                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: connectedIds
                                        .map((id) {
                                          return Padding(
                                            key: ValueKey('lamp_$id'),
                                            padding: const EdgeInsets.symmetric(horizontal: 10.0),
                                            child: SizedBox(
                                              width: 90,
                                              child: StreamBuilder<DatabaseEvent>(
                                                stream: FirebaseDatabase.instance.ref("lights/$id").onValue,
                                                builder: (context, snap) {
                                                  if (snap.connectionState == ConnectionState.waiting) {
                                                    return Column(
                                                      mainAxisSize: MainAxisSize.min,
                                                      children: [
                                                        Container(
                                                          width: 56,
                                                          height: 56,
                                                          decoration: BoxDecoration(
                                                            color: Colors.grey.withOpacity(0.02),
                                                            shape: BoxShape.circle,
                                                          ),
                                                          child: const Center(
                                                            child: SizedBox(
                                                              width: 16,
                                                              height: 16,
                                                              child: CircularProgressIndicator(strokeWidth: 2),
                                                            ),
                                                          ),
                                                        ),
                                                        const SizedBox(height: 8),
                                                        const SizedBox(height: 12),
                                                      ],
                                                    );
                                                  }

                                                  if (!snap.hasData || snap.data!.snapshot.value == null) {
                                                    return const SizedBox.shrink();
                                                  }

                                                  final data = snap.data!.snapshot.value as Map<dynamic, dynamic>;
                                                  final rawOn = data['On'];
                                                  final bool isOn = (rawOn == true) || (rawOn?.toString().toLowerCase() == 'true');
                                                  final name = (data['Name'] ?? 'Sin nombre').toString();

                                                  final Color iconColor = isOn ? Colors.amber.shade600 : Colors.grey.shade400;
                                                  final Color bgColor =
                                                      isOn ? Colors.amber.withOpacity(0.12) : Colors.grey.withOpacity(0.02);
                                                  final double tileSize = 56;

                                                  return Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Tooltip(
                                                        message: '$name — ${isOn ? 'Encendida' : 'Apagada'}',
                                                        child: Semantics(
                                                          label: '$name, ${isOn ? 'encendida' : 'apagada'}',
                                                          button: true,
                                                          child: GestureDetector(
                                                            onTap: () {},
                                                            child: AnimatedContainer(
                                                              duration: const Duration(milliseconds: 280),
                                                              curve: Curves.easeOut,
                                                              width: tileSize,
                                                              height: tileSize,
                                                              decoration: BoxDecoration(
                                                                color: bgColor,
                                                                shape: BoxShape.circle,
                                                                boxShadow:
                                                                    isOn
                                                                        ? [
                                                                          BoxShadow(
                                                                            color: iconColor.withOpacity(0.20),
                                                                            blurRadius: 18,
                                                                            spreadRadius: 1,
                                                                          ),
                                                                        ]
                                                                        : [
                                                                          BoxShadow(
                                                                            color: Colors.black12,
                                                                            blurRadius: 6,
                                                                            offset: const Offset(0, 2),
                                                                          ),
                                                                        ],
                                                              ),
                                                              child: Center(
                                                                child: AnimatedScale(
                                                                  scale: isOn ? 1.08 : 1.0,
                                                                  duration: const Duration(milliseconds: 240),
                                                                  child: Icon(
                                                                    isOn ? Icons.lightbulb : Icons.lightbulb_outline,
                                                                    size: 34,
                                                                    color: iconColor,
                                                                  ),
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(height: 8),
                                                      SizedBox(
                                                        width: 84,
                                                        child: Text(
                                                          name,
                                                          textAlign: TextAlign.center,
                                                          overflow: TextOverflow.ellipsis,
                                                          maxLines: 1,
                                                          style: const TextStyle(fontSize: 12, color: Colors.black87),
                                                        ),
                                                      ),
                                                    ],
                                                  );
                                                },
                                              ),
                                            ),
                                          );
                                        })
                                        .toList(growable: false),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(20),
                      children:
                          deviceButons.map((device) {
                            return InkWell(
                              onTap: () => context.push(device.route),
                              child: Ink(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 12)],
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    if (device.icon != null) Icon(device.icon!, size: 40, color: Theme.of(context).primaryColor),
                                    if (device.icon != null) const SizedBox(height: 12),
                                    Text(
                                      device.label,
                                      textAlign: TextAlign.center,
                                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
      drawer: DrawerMenu(scafoldKey: scafoldKey, ref: ref),
    );
  }
}

class _ModuleListView extends StatefulWidget {
  @override
  State<_ModuleListView> createState() => _ModuleListViewState();
}

class _ModuleListViewState extends State<_ModuleListView> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemBuilder: (context, index) {
        return _ModuleListItem(device: deviceButons[index]);
      },
      itemCount: deviceButons.length,
    );
  }
}

class _ModuleListItem extends StatelessWidget {
  final DeviceButton device;

  const _ModuleListItem({required this.device});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(device.label),
        trailing: Icon(Icons.arrow_forward),
        onTap: () {
          context.push(device.route);
        },
      ),
    );
  }
}

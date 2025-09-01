import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_home_app/core/providers.dart';
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
    if (user != null &&
        (user.displayName == null || user.displayName!.isEmpty)) {
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
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Nombre'),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Aceptar'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final scafoldKey = GlobalKey<ScaffoldState>();
    final user = FirebaseAuth.instance.currentUser;
    var temperature = "-";

    if (isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    try {
      final user = FirebaseAuth.instance.currentUser!.uid;
    } catch (error) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    final redId = ref.watch(redIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text("Bienvenido ${user?.displayName ?? 'Usuario'}"),
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            StreamBuilder<DatabaseEvent>(
              stream:
                  FirebaseDatabase.instance
                      .ref("air")
                      .orderByChild("Network")
                      .equalTo(redId)
                      .onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(
                    child: Text(
                      "Crea un dispositivo de aire acondicionado para poder ver la temperatura actual",
                    ),
                  );
                }

                final devices =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                final firstDevice =
                    devices.values.first as Map<dynamic, dynamic>;

                final temperature =
                    firstDevice['SensorTemp']?.toString() ?? "--";

                return Column(
                  children: [
                    const Text(
                      "Temperatura actual en la habitación",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 15),
                    Center(
                      child: Text(
                        "$temperature °C",
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.deepPurple,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            StreamBuilder<DatabaseEvent>(
              stream:
                  FirebaseDatabase.instance
                      .ref("lights")
                      .orderByChild("Network")
                      .equalTo(redId)
                      .onValue,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData ||
                    snapshot.data!.snapshot.value == null) {
                  return const Center(
                    child: Text("No hay luces registradas en esta red"),
                  );
                }

                final devicesMap =
                    snapshot.data!.snapshot.value as Map<dynamic, dynamic>;
                final deviceEntries = devicesMap.entries.toList();

                return SizedBox(
                  height: 56,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: deviceEntries
                          .map((entry) {
                            final id = entry.key as String;
                            final data = entry.value as Map<dynamic, dynamic>;
                            final isOn = (data['On']) as bool;

                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 1,
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    isOn
                                        ? Icons.lightbulb
                                        : Icons.lightbulb_outline,
                                    size: 30,
                                    color:
                                        isOn
                                            ? Colors.amber.shade600
                                            : Colors.grey.shade400,
                                  ),

                                  SizedBox(
                                    width: 72,
                                    child: Text(
                                      data['Name'].toString(),
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                      style: const TextStyle(fontSize: 12),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          })
                          .toList(growable: false),
                    ),
                  ),
                );
              },
            ),

            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                padding: const EdgeInsets.all(20),
                children:
                    deviceButons.map((device) {
                      return InkWell(
                        onTap: () => context.push(device.route),
                        child: Ink(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (device.icon != null)
                                Icon(
                                  device.icon!,
                                  size: 40,
                                  color: Theme.of(context).primaryColor,
                                ),
                              if (device.icon != null)
                                const SizedBox(height: 12),
                              Text(
                                device.label,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
              ),
            ),
          ],
        ),
      ),
      drawer: DrawerMenu(scafoldKey: scafoldKey),
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

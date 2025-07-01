import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_home_app/domain/models/device_button.dart';
import 'package:smart_home_app/presentation/widgets/drawer_menu.dart';

// TODO: Grafico
// TODO: cambiar la imagen del login
// TODO: agregar campo temperatura ambiente (no es lo mismo que temperatura ya q este ultimo es del aire acondicionado)

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAndAskForDisplayName();
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

    return Scaffold(
      appBar: AppBar(title: Text("Bienvenido ${user!.displayName}")),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            StreamBuilder(
              stream:
                  FirebaseFirestore.instance
                      .collection("aire")
                      .where(
                        'creador',
                        isEqualTo: FirebaseAuth.instance.currentUser!.uid,
                      )
                      .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      "Crea un dispositivo de aire acondicionado para poder ver la temperatura actual",
                    ),
                  );
                }

                final doc = snapshot.data!.docs.first;
                final data = doc.data();
                temperature = data['temperatura'] ?? '--';
                return Column(
                  children: [
                    Text(
                      "Temperatura actual en la habitacion",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 20),
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
      drawer: DrawerMenu(scafoldKey: scafoldKey, userId: "pepe"),
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

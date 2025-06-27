import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_home_app/domain/models/device_button.dart';
import 'package:smart_home_app/presentation/widgets/drawer_menu.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  final double temperature = 25.0;

  @override
  Widget build(BuildContext context) {
    final scafoldKey = GlobalKey<ScaffoldState>();
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(title: Text("Bienvenido pepe")),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            Text(
              "Temperatura actual en la habitacion principal",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                "${temperature.toStringAsFixed(0)}°C",
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
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
  const _ModuleListView({super.key});

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

  const _ModuleListItem({super.key, required this.device});

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

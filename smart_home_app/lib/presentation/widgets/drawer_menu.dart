import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_home_app/config/menu_item.dart';

class DrawerMenu extends StatefulWidget {
  final GlobalKey<ScaffoldState> scafoldKey;
  const DrawerMenu({super.key, required this.scafoldKey});

  @override
  State<DrawerMenu> createState() => _DrawerMenuState();
}

class _DrawerMenuState extends State<DrawerMenu> {
  @override
  Widget build(BuildContext context) {
    return NavigationDrawer(
      onDestinationSelected: (value) {
        setState(() {});
        if (menuItems[value].title == 'Cerrar sesion') {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text("Cerrar sesión"),
                  content: Text("¿Estas seguro que quieres cerrar sesión?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("No"),
                    ),
                    TextButton(
                      onPressed: () async {
                        Navigator.of(context).pop();
                        await FirebaseAuth.instance.signOut();
                      },
                      child: Text("Si"),
                    ),
                  ],
                ),
          );
        } else {
          final link = menuItems[value].link;
          Navigator.of(context).pop();

          context.push(link);
          widget.scafoldKey.currentState?.closeDrawer();
        }
      },
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 10, 28, 5),
          child: Text('Main', style: Theme.of(context).textTheme.titleMedium),
        ),
        ...menuItems.map(
          (item) => NavigationDrawerDestination(
            icon: Icon(item.icon),
            label: Text(item.title),
          ),
        ),
      ],
    );
  }
}

import 'package:flutter/material.dart';
import 'package:primer_parcial/config/menu_item.dart';
import 'package:go_router/go_router.dart';

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
        if (menuItems[value].title == 'Log out') {
          showDialog(
            context: context,
            builder:
                (context) => AlertDialog(
                  title: Text("Login out"),
                  content: Text("Are you sure you want to log out?"),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text("No"),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        context.push(menuItems[value].link);
                      },
                      child: Text("Yes"),
                    ),
                  ],
                ),
          );
        } else {
          context.push(menuItems[value].link);
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

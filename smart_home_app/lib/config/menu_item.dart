import 'package:flutter/material.dart';

class MenuItem {
  final String title;
  final IconData icon;
  final String link;

  const MenuItem({required this.title, required this.icon, required this.link});
}

const List<MenuItem> menuItems = [
  MenuItem(title: 'Home', icon: Icons.house, link: '/home'),
  MenuItem(title: 'Perfil', icon: Icons.person, link: '/myprofile'),
  MenuItem(title: 'Cerrar sesion', icon: Icons.logout, link: '/login'),
];
